import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/catalog_card.dart';
import 'paged_select.dart';

/// Read-only access to the shared card database (`card_sets` and
/// `card_catalog`). Unlike the user's own collection, the catalog is never
/// loaded in full — it can hold tens of thousands of cards — so cards are
/// fetched a page at a time as the person searches.
class CatalogRepository {
  CatalogRepository._();

  static const pageSize = 30;

  static List<CatalogSet>? _sets;

  /// Every set, newest first. Small (a few hundred rows at most), so it is
  /// loaded once and kept.
  static Future<List<CatalogSet>> loadSets() async {
    final cached = _sets;
    if (cached != null) return cached;
    final rows =
        await fetchAllRows('card_sets', orderBy: 'release_date', thenBy: 'id');
    final sets = rows.map(CatalogSet.fromRow).toList().reversed.toList();
    return _sets = sets;
  }

  /// Cards matching [query] (name contains it, or the printed number equals
  /// it — `4` and `4/102` both find card 4), optionally limited to one set.
  /// Returns at most [pageSize] cards starting at [offset].
  static Future<List<CatalogCard>> search({
    String query = '',
    String? setId,
    int offset = 0,
  }) async {
    var request = Supabase.instance.client
        .from('card_catalog')
        .select('*, card_sets(name, printed_total)');

    if (setId != null) request = request.eq('set_id', setId);

    final text = _sanitize(query);
    if (text.isNotEmpty) {
      final number = text.split('/').first.trim();
      request = request.or('name.ilike.%$text%,number.eq.$number');
    }

    final rows = await request
        .order('name', ascending: true)
        .order('id', ascending: true)
        .range(offset, offset + pageSize - 1);
    return rows.map(CatalogCard.fromRow).toList();
  }

  /// The characters that have a meaning inside a PostgREST `or(...)` filter
  /// or an ILIKE pattern would otherwise change what is searched for.
  static String _sanitize(String input) =>
      input.replaceAll(RegExp(r'[,()%*\\"]'), ' ').trim();
}
