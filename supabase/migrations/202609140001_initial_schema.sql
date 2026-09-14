-- Estuda+ - esquema inicial do Supabase
-- Execute pelo Supabase CLI ou cole o arquivo no SQL Editor.

create extension if not exists pgcrypto;

do $$ begin
  create type public.subject_status as enum ('active', 'completed', 'archived');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.study_session_source as enum ('pomodoro', 'manual');
exception when duplicate_object then null;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(trim(full_name)) between 2 and 120),
  avatar_url text,
  timezone text not null default 'America/Sao_Paulo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 100),
  description text check (description is null or char_length(description) <= 500),
  color_hex text not null default '#2563EB'
    check (color_hex ~ '^#[0-9A-Fa-f]{6}$'),
  icon_key text not null default 'book'
    check (char_length(icon_key) between 1 and 40),
  target_minutes integer
    check (target_minutes is null or target_minutes between 1 and 525600),
  status public.subject_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);

create unique index if not exists subjects_user_name_active_unique
  on public.subjects (user_id, lower(name))
  where status <> 'archived';

create index if not exists subjects_user_status_idx
  on public.subjects (user_id, status, created_at desc);

create table if not exists public.weekly_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  target_minutes integer not null check (target_minutes between 1 and 10080),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, week_start),
  check (extract(isodow from week_start) = 1)
);

create index if not exists weekly_goals_user_week_idx
  on public.weekly_goals (user_id, week_start desc);

create table if not exists public.study_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid not null,
  source public.study_session_source not null default 'manual',
  started_at timestamptz not null,
  ended_at timestamptz,
  duration_seconds integer not null check (duration_seconds between 1 and 86400),
  summary text check (summary is null or char_length(summary) <= 1000),
  completed boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint study_sessions_subject_owner_fk
    foreign key (subject_id, user_id)
    references public.subjects(id, user_id)
    on delete restrict,
  check (ended_at is null or ended_at >= started_at)
);

create index if not exists study_sessions_user_started_idx
  on public.study_sessions (user_id, started_at desc);

create index if not exists study_sessions_subject_started_idx
  on public.study_sessions (subject_id, started_at desc);

create index if not exists study_sessions_completed_idx
  on public.study_sessions (user_id, completed, started_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists subjects_set_updated_at on public.subjects;
create trigger subjects_set_updated_at
before update on public.subjects
for each row execute function public.set_updated_at();

drop trigger if exists weekly_goals_set_updated_at on public.weekly_goals;
create trigger weekly_goals_set_updated_at
before update on public.weekly_goals
for each row execute function public.set_updated_at();

drop trigger if exists study_sessions_set_updated_at on public.study_sessions;
create trigger study_sessions_set_updated_at
before update on public.study_sessions
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    case
      when char_length(
        coalesce(
          nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
          nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
          split_part(coalesce(new.email, ''), '@', 1)
        )
      ) >= 2
      then coalesce(
        nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
        nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
        split_part(new.email, '@', 1)
      )
      else 'Estudante'
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.weekly_goals enable row level security;
alter table public.study_sessions enable row level security;

revoke all on table public.profiles from anon;
revoke all on table public.subjects from anon;
revoke all on table public.weekly_goals from anon;
revoke all on table public.study_sessions from anon;

grant select, insert, update, delete on table public.profiles to authenticated;
grant select, insert, update, delete on table public.subjects to authenticated;
grant select, insert, update, delete on table public.weekly_goals to authenticated;
grant select, insert, update, delete on table public.study_sessions to authenticated;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert
to authenticated
with check ((select auth.uid()) = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists "profiles_delete_own" on public.profiles;
create policy "profiles_delete_own"
on public.profiles for delete
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "subjects_select_own" on public.subjects;
create policy "subjects_select_own"
on public.subjects for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "subjects_insert_own" on public.subjects;
create policy "subjects_insert_own"
on public.subjects for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "subjects_update_own" on public.subjects;
create policy "subjects_update_own"
on public.subjects for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "subjects_delete_own" on public.subjects;
create policy "subjects_delete_own"
on public.subjects for delete
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "weekly_goals_select_own" on public.weekly_goals;
create policy "weekly_goals_select_own"
on public.weekly_goals for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "weekly_goals_insert_own" on public.weekly_goals;
create policy "weekly_goals_insert_own"
on public.weekly_goals for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "weekly_goals_update_own" on public.weekly_goals;
create policy "weekly_goals_update_own"
on public.weekly_goals for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "weekly_goals_delete_own" on public.weekly_goals;
create policy "weekly_goals_delete_own"
on public.weekly_goals for delete
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "study_sessions_select_own" on public.study_sessions;
create policy "study_sessions_select_own"
on public.study_sessions for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "study_sessions_insert_own" on public.study_sessions;
create policy "study_sessions_insert_own"
on public.study_sessions for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.subjects
    where subjects.id = subject_id
      and subjects.user_id = (select auth.uid())
  )
);

drop policy if exists "study_sessions_update_own" on public.study_sessions;
create policy "study_sessions_update_own"
on public.study_sessions for update
to authenticated
using ((select auth.uid()) = user_id)
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.subjects
    where subjects.id = subject_id
      and subjects.user_id = (select auth.uid())
  )
);

drop policy if exists "study_sessions_delete_own" on public.study_sessions;
create policy "study_sessions_delete_own"
on public.study_sessions for delete
to authenticated
using ((select auth.uid()) = user_id);

create or replace function public.current_week_start(user_timezone text default 'America/Sao_Paulo')
returns date
language sql
stable
set search_path = ''
as $$
  select date_trunc(
    'week',
    timezone(user_timezone, now())
  )::date;
$$;

create or replace function public.get_dashboard_summary()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with current_profile as (
    select coalesce(p.timezone, 'America/Sao_Paulo') as timezone
    from public.profiles p
    where p.id = (select auth.uid())
  ),
  bounds as (
    select
      public.current_week_start(cp.timezone) as week_start,
      cp.timezone
    from current_profile cp
  ),
  totals as (
    select
      coalesce(sum(s.duration_seconds), 0)::bigint as total_seconds,
      count(*)::bigint as total_sessions,
      coalesce(
        sum(s.duration_seconds) filter (
          where timezone(b.timezone, s.started_at)::date >= b.week_start
            and timezone(b.timezone, s.started_at)::date < b.week_start + 7
        ),
        0
      )::bigint as week_seconds
    from bounds b
    left join public.study_sessions s
      on s.user_id = (select auth.uid())
      and s.completed = true
    group by b.week_start
  ),
  goal as (
    select coalesce(g.target_minutes, 0)::integer as target_minutes
    from bounds b
    left join public.weekly_goals g
      on g.user_id = (select auth.uid())
      and g.week_start = b.week_start
  )
  select jsonb_build_object(
    'total_seconds', t.total_seconds,
    'total_sessions', t.total_sessions,
    'week_seconds', t.week_seconds,
    'weekly_target_minutes', g.target_minutes,
    'weekly_progress_percent',
      case
        when g.target_minutes > 0
          then least(100, round((t.week_seconds / 60.0) / g.target_minutes * 100))
        else 0
      end
  )
  from totals t
  cross join goal g;
$$;

revoke all on function public.get_dashboard_summary() from public, anon;
revoke all on function public.current_week_start(text) from public, anon;
grant execute on function public.get_dashboard_summary() to authenticated;
grant execute on function public.current_week_start(text) to authenticated;
