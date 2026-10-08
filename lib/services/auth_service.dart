import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountAlreadyExistsException implements Exception {
  const AccountAlreadyExistsException();
}

class AuthService {
  AuthService._();

  static const minPasswordLength = 6;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isValidEmail(String email) =>
      _emailPattern.hasMatch(email.trim());

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
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: normalizeEmail(email),
        password: password,
        data: {'trainer_name': trainerName},
        emailRedirectTo: _webRedirectUrl,
      );
      final identities = response.user?.identities;
      if (identities != null && identities.isEmpty) {
        throw const AccountAlreadyExistsException();
      }
    } on AuthException catch (e) {
      if (_isDuplicateAccountError(e)) {
        throw const AccountAlreadyExistsException();
      }
      rethrow;
    }
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: normalizeEmail(email),
      password: password,
    );
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
      normalizeEmail(email),
      redirectTo: _webRedirectUrl,
    );
  }

  static Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  static const _offlineMessage =
      "Couldn't reach the server. Check your connection and try again.";

  static bool _isDuplicateAccountError(AuthException error) {
    final message = error.message.toLowerCase();
    return error.code == 'user_already_exists' ||
        error.code == 'email_exists' ||
        message.contains('already registered') ||
        message.contains('already been registered');
  }

  static bool _isRateLimited(AuthException error) {
    final message = error.message.toLowerCase();
    return error.statusCode == '429' ||
        error.code == 'over_request_rate_limit' ||
        error.code == 'over_email_send_rate_limit' ||
        message.contains('rate limit') ||
        message.contains('security purposes');
  }

  static String signUpErrorMessage(Object error) {
    if (error is AccountAlreadyExistsException) {
      return 'An account with that email already exists. Log in instead, or '
          'use Forgot Password if you need to reset it.';
    }
    if (error is! AuthException) return _offlineMessage;
    final message = error.message.toLowerCase();
    if (_isRateLimited(error)) {
      return 'Too many attempts. Wait a minute, then try again.';
    }
    if (error.code == 'weak_password' || message.contains('password')) {
      return 'That password is too weak. Use at least $minPasswordLength '
          'characters with letters and numbers.';
    }
    if (error.code == 'email_address_invalid' ||
        error.code == 'validation_failed' ||
        (message.contains('invalid') && message.contains('email'))) {
      return "That email address doesn't look right.";
    }
    if (error.code == 'signup_disabled') {
      return 'Sign-ups are turned off right now. Try again later.';
    }
    return 'Could not create that account — try again.';
  }

  static String signInErrorMessage(Object error) {
    if (error is! AuthException) return _offlineMessage;
    final message = error.message.toLowerCase();
    if (error.code == 'email_not_confirmed' ||
        message.contains('not confirmed')) {
      return 'Confirm your email first — check your inbox for the link, '
          'then log in.';
    }
    if (_isRateLimited(error)) {
      return 'Too many attempts. Wait a minute, then try again.';
    }
    if (error is AuthRetryableFetchException) return _offlineMessage;
    return 'Could not log in — check your email and password.';
  }

  static String resetEmailErrorMessage(Object error) {
    if (error is! AuthException) return _offlineMessage;
    final message = error.message.toLowerCase();
    if (_isRateLimited(error)) {
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
