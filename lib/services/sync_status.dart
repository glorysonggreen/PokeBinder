import 'package:flutter/foundation.dart';

/// Every screen calls `Repository.upsert(...)` / `.delete(...)` without
/// awaiting or catching it (see e.g. `binders_screen.dart`) — the local
/// list is treated as the source of truth, and the write to Supabase rides
/// along in the background. That's fine when it works, but it means a
/// failed write (offline, RLS rejection, a bad constraint) used to just
/// throw into an unhandled Future and vanish: the UI kept showing the
/// change as saved when the server never got it.
///
/// [SyncStatus] gives those fire-and-forget calls somewhere to report a
/// failure. Repositories call [SyncStatus.track] around each write instead
/// of letting it throw bare; [SyncStatus.errors] is a stream a widget near
/// the root can listen to and surface (a SnackBar, a banner) so "saved"
/// actually means saved.
class SyncStatus {
  SyncStatus._();

  static final ValueNotifier<String?> lastError = ValueNotifier(null);

  /// Runs [action], and on failure records a human-readable message in
  /// [lastError] instead of letting the exception disappear into an
  /// unhandled Future. Rethrows, so a caller that *does* await/catch still
  /// sees the real error.
  static Future<T> track<T>(String actionDescription, Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      lastError.value = "Couldn't $actionDescription — check your connection.";
      rethrow;
    }
  }
}
