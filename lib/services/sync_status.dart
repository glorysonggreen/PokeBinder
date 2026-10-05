import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncStatus {
  SyncStatus._();

  static final ValueNotifier<String?> lastError = ValueNotifier(null);

  static Future<void> _tail = Future<void>.value();

  static const _writeTimeout = Duration(seconds: 30);

  static Future<void> flush() => _tail;

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
    final future = completer.future;
    future.ignore();
    return future;
  }

  static void _report(String what, Object error) {
    debugPrint('Sync failed ($what): $error');
    lastError.value = null;
    lastError.value = _messageFor(what, error);
  }

  static String _messageFor(String what, Object error) {
    if (error is AuthException) {
      return "Couldn't $what — your session expired. Log in again.";
    }
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505':
          return "Couldn't $what — you already have one with that name.";
        case '23503':
          return "Couldn't $what — it refers to a card or deck that no "
              'longer exists.';
        case '23514':
          return "Couldn't $what — one of the values is out of range.";
        case '42501':
        case 'PGRST301':
        case 'PGRST303':
          return "Couldn't $what — your session may have expired. "
              'Log in again.';
      }
    }
    return "Couldn't $what — check your connection.";
  }
}
