import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wishlist_entry.dart';
import 'paged_select.dart';
import 'sync_status.dart';

/// Syncs [WishlistEntry.library] with the `wishlist_entries` table.
/// Screens keep mutating `library` directly; they just also call [upsert]
/// or [delete] alongside each mutation so the change is persisted.
class WishlistRepository {
  WishlistRepository._();

  static SupabaseQueryBuilder get _table =>
      Supabase.instance.client.from('wishlist_entries');

  /// Replaces [WishlistEntry.library] with everything the signed-in user
  /// owns. Called once by AppShell on load.
  static Future<void> loadAll() async {
    final rows = await fetchAllRows(
      'wishlist_entries',
      orderBy: 'date_added',
      thenBy: 'id',
    );
    final entries = rows.map(WishlistEntry.fromRow).toList();
    WishlistEntry.library
      ..clear()
      ..addAll(entries);
  }

  static Future<void> upsert(WishlistEntry entry) {
    return SyncStatus.track(
      'save that entry',
      () => _table.upsert(entry.toRow()),
    );
  }

  static Future<void> delete(String id) {
    return SyncStatus.track(
      'delete that entry',
      () => _table.delete().eq('id', id),
    );
  }
}
