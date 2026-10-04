import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Every screen calls `Repository.upsert(...)` / `.delete(...)` without
/// awaiting or catching it (see e.g. `binders_screen.dart`) — the local
/// list is treated as the source of truth, and the write to Supabase rides
/// along in the background.
///
/// [SyncStatus] is where those fire-and-forget writes are run, and it does
/// three jobs:
///
/// 1. **Runs writes one at a time, in the order they were requested.**
///    Previously every call started its own HTTP request immediately, so
///    requests could finish out of order. That caused real bugs: a quick
///    second edit to a card could be overwritten by the slower first one; a
///    new card and the deck that references it were sent at the same moment,
///    so the `deck_cards` insert could reach the server before the `cards`
///    insert and fail the foreign key; and two quick deck edits interleaved
///    their delete-then-insert and tripped the primary key.
/// 2. **Reports failures.** A failed write is surfaced through [lastError]
///    (AppShell shows it as a SnackBar) instead of vanishing.
/// 3. **Says something useful.** The message depends on *why* it failed
///    rather than always blaming the connection.
class SyncStatus {
  SyncStatus._();

  /// The latest failure message. AppShell listens to this.
  ///
  /// A [ValueNotifier] only notifies when the value *changes*, so assigning
  /// the same text twice in a row (two failed saves in a row, which is the
  /// normal case when offline) used to show the SnackBar once and then never
  /// again. [_report] therefore clears it to null first; listeners must
  /// ignore null.
  static final ValueNotifier<String?> lastError = ValueNotifier(null);

  /// Tail of the write queue. Never completes with an error — each task
  /// handles its own failure — so one bad write can't block the rest.
  static Future<void> _tail = Future<void>.value();

  /// Upper bound for one write. Without it a request that hangs (some
  /// networks never answer) would block every later write forever.
  static const _writeTimeout = Duration(seconds: 30);

  /// Resolves once every write queued so far has finished (succeeded or
  /// failed). Await this before signing out so a pending save isn't sent
  /// after the session is gone — or, worse, under the next account.
  static Future<void> flush() => _tail;

  /// Queues [action] behind any writes already in flight and runs it. On
  /// failure a human-readable message is recorded in [lastError]. The
  /// returned future still completes with the real error, so a caller that
  /// *does* await/catch it (e.g. the sign-up flow) sees it.
  static Future<T> track<T>(
    String actionDescription,
    Future<T> Function() action,
  ) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action().timeout(_writeTimeout));
      } catch (e, st) {
        _report(actionDescription, e);
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  static void _report(String what, Object error) {
    debugPrint('Sync failed ($what): $error');
    lastError.value = null; // force a notification even for a repeat message
    lastError.value = _messageFor(what, error);
  }

  static String _messageFor(String what, Object error) {
    if (error is AuthException) {
      return "Couldn't $what — your session expired. Log in again.";
    }
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505': // unique_violation
          return "Couldn't $what — you already have one with that name.";
        case '23503': // foreign_key_violation
          return "Couldn't $what — it refers to a card or deck that no "
              'longer exists.';
        case '23514': // check_violation
          return "Couldn't $what — one of the values is out of range.";
        case '42501': // insufficient_privilege (row-level security)
        case 'PGRST301': // JWT expired / invalid
        case 'PGRST303':
          return "Couldn't $what — your session may have expired. "
              'Log in again.';
      }
    }
    return "Couldn't $what — check your connection.";
  }
}
