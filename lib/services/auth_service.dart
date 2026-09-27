import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps the auth calls the app needs. Screens call these instead of
/// talking to `Supabase.instance.client.auth` directly, so the login,
/// sign-up, and forgot-password screens stay simple form-handling code.
class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static bool get isSignedIn => _client.auth.currentSession != null;

  /// Creates the account. If email confirmation is off (see
  /// SUPABASE_SETUP.md), the returned session is already usable —
  /// [isSignedIn] is true right after this returns.
  static Future<void> signUp({
    required String email,
    required String password,
    required String trainerName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'trainer_name': trainerName},
    );
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() => _client.auth.signOut();

  static Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }
}
