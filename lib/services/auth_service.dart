import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static bool get isSignedIn => _client.auth.currentSession != null;

  static String? get trainerNameFromMetadata {
    final value = _client.auth.currentUser?.userMetadata?['trainer_name'];
    if (value is! String) return null;
    final name = value.trim();
    return name.isEmpty ? null : name;
  }

  static String? get _webRedirectUrl =>
      kIsWeb ? '${Uri.base.origin}${Uri.base.path}' : null;

  static Future<void> signUp({
    required String email,
    required String password,
    required String trainerName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'trainer_name': trainerName},
      emailRedirectTo: _webRedirectUrl,
    );
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Sign-out request failed (signed out locally anyway): $e');
    }
  }

  static Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: _webRedirectUrl,
    );
  }

  static Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
