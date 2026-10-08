import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wishlist_entry.dart';
import 'paged_select.dart';
import 'sync_status.dart';

class WishlistRepository {
  WishlistRepository._();

  static SupabaseQueryBuilder get _table =>
      Supabase.instance.client.from('wishlist_entries');

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

  static Future<void> deleteBySourceCards(List<String> cardIds) async {
    if (cardIds.isEmpty) return;
    await _table.delete().inFilter('source_card_id', cardIds);
  }
}
