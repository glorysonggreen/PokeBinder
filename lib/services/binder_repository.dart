import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/binder_data.dart';
import 'paged_select.dart';
import 'sync_status.dart';

class BinderRepository {
  BinderRepository._();

  static SupabaseQueryBuilder get _table =>
      Supabase.instance.client.from('binders');

  static Future<void> loadAll() async {
    final rows =
        await fetchAllRows('binders', orderBy: 'created_at', thenBy: 'id');
    final binders = rows.map(BinderData.fromRow).toList();
    BinderData.library
      ..clear()
      ..addAll(binders);
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
