import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static final ValueNotifier<bool> recoveryRequested = ValueNotifier(false);
  static StreamSubscription<AuthState>? _recoverySubscription;

  static void watchForPasswordRecovery() {
    if (_recoverySubscription != null) return;
    try {
      _recoverySubscription = _client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          recoveryRequested.value = true;
        }
      });
    } catch (e) {
      debugPrint('Could not listen for password recovery yet: $e');
    }
  }

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

  static const _offlineMessage =
      "Couldn't reach the server. Check your connection and try again.";

  static String resetEmailErrorMessage(Object error) {
    if (error is! AuthException) return _offlineMessage;
    final message = error.message.toLowerCase();
    if (error.statusCode == '429' ||
        message.contains('rate limit') ||
        message.contains('security purposes')) {
      return 'Too many requests. Wait a minute, then try again.';
    }
    if (message.contains('invalid') && message.contains('email')) {
      return "That email address doesn't look right.";
    }
    return "Couldn't send the reset email. Please try again in a moment.";
  }

  static String passwordChangeErrorMessage(Object error) {
    if (error is! AuthException) return _offlineMessage;
    final message = error.message.toLowerCase();
    if (message.contains('different from the old password') ||
        message.contains('same password')) {
      return 'Your new password must be different from your current one.';
    }
    if (message.contains('weak') ||
        message.contains('at least') ||
        message.contains('characters')) {
      return 'That password is too weak. Try a longer one with letters and '
          'numbers.';
    }
    if (message.contains('session') ||
        message.contains('expired') ||
        message.contains('jwt') ||
        message.contains('not authenticated') ||
        error.statusCode == '401' ||
        error.statusCode == '403') {
      return 'This reset link has expired or was already used. Request a new '
          'one and try again.';
    }
    return "Couldn't change your password. Please try again.";
  }
}
