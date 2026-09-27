import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/binder_data.dart';
import 'sync_status.dart';

/// Syncs [BinderData.library] with the `binders` table. Screens keep
/// mutating `library` directly; they just also call [upsert] or [delete]
/// alongside each mutation so the change is persisted.
class BinderRepository {
  BinderRepository._();

  static SupabaseQueryBuilder get _table =>
      Supabase.instance.client.from('binders');

  /// Replaces [BinderData.library] with everything the signed-in user
  /// owns. Called once by AppShell on load.
  static Future<void> loadAll() async {
    final rows = await _table.select();
    BinderData.library
      ..clear()
      ..addAll(rows.map(BinderData.fromRow));
  }

  static Future<void> upsert(BinderData binder) {
    return SyncStatus.track(
      'save that binder',
      () => _table.upsert(binder.toRow()),
    );
  }

  static Future<void> delete(String id) {
    return SyncStatus.track(
      'delete that binder',
      () => _table.delete().eq('id', id),
    );
  }
}
