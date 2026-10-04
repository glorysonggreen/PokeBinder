import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps the auth calls the app needs. Screens call these instead of
/// talking to `Supabase.instance.client.auth` directly, so the login,
/// sign-up, and forgot-password screens stay simple form-handling code.
class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static bool get isSignedIn => _client.auth.currentSession != null;

  /// The trainer name the user typed at sign-up, stored in the account's
  /// metadata. Used as the starting name of the trainer profile, including
  /// when the profile is first created on a *later* log in (the normal case
  /// when email confirmation is on, since there's no session at sign-up to
  /// create the profile with). Null if the account has none.
  static String? get trainerNameFromMetadata {
    final value = _client.auth.currentUser?.userMetadata?['trainer_name'];
    if (value is! String) return null;
    final name = value.trim();
    return name.isEmpty ? null : name;
  }

  /// Where Supabase's emailed links (confirm account, reset password) send
  /// the person back to. Without this they land on the project's configured
  /// "Site URL" — `localhost` by default — instead of the deployed app.
  /// Only meaningful on web; the URL must also be listed under
  /// Authentication > URL Configuration > Redirect URLs (see
  /// SUPABASE_SETUP.md). Null elsewhere, which keeps the project default.
  static String? get _webRedirectUrl =>
      kIsWeb ? '${Uri.base.origin}${Uri.base.path}' : null;

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
      emailRedirectTo: _webRedirectUrl,
    );
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Signs out on this device. The local session is removed *before* the
  /// server is told, so if that request fails (offline) the library still
  /// throws — which used to abort the caller's cleanup and leave the person
  /// looking at a collection they were no longer signed in to. That error
  /// is swallowed here: the local session is gone either way.
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

  /// Sets a new password for the signed-in user. Used by the reset-password
  /// screen, which is shown after the person follows the emailed link (that
  /// link signs them in with a temporary recovery session).
  static Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
