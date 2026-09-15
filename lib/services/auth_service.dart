import 'package:supabase_flutter/supabase_flutter.dart';

import 'pomodoro_controller.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
    final identities = response.user?.identities;
    if (response.user != null && identities != null && identities.isEmpty) {
      throw const EmailAlreadyRegisteredException();
    }
    return response.session != null;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      throw ArgumentError.value(
        newPassword,
        'newPassword',
        'A nova senha deve ter pelo menos 8 caracteres.',
      );
    }
    final email = _client.auth.currentUser?.email;
    if (email == null) throw StateError('Usuário não autenticado.');
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } on AuthException catch (error) {
      if (error.message.toLowerCase().contains('invalid login credentials')) {
        throw const CurrentPasswordInvalidException();
      }
      rethrow;
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await PomodoroController.instance.clearForLogout();
    await _client.auth.signOut();
  }
}

class CurrentPasswordInvalidException implements Exception {
  const CurrentPasswordInvalidException();
}

class EmailAlreadyRegisteredException implements Exception {
  const EmailAlreadyRegisteredException();
}
