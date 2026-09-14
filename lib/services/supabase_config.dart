class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qxvssdtwflsosraonlmu.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_RbZbMZ5kVwEd0GoXI7VueA_uVla6_Yk',
  );

  static bool get isConfigured =>
      url.startsWith('https://') && publishableKey.isNotEmpty;
}
