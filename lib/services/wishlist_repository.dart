import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wishlist_entry.dart';
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
    final rows = await _table.select();
    WishlistEntry.library
      ..clear()
      ..addAll(rows.map(WishlistEntry.fromRow));
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
