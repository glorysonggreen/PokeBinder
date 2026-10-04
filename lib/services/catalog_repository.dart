import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/catalog_card.dart';
import 'paged_select.dart';

/// Read-only access to the shared card database (`card_sets` and
/// `card_catalog`). Unlike the user's own collection, the catalog is never
/// loaded in full — it can hold tens of thousands of cards — so cards are
/// fetched a page at a time as the person searches.
class CatalogRepository {
  CatalogRepository._();

  /// The most cards one name search returns. Results are sorted and filtered
  /// on the device, so they are fetched in one go rather than page by page.
  static const searchCap = 200;

  /// PostgREST never returns more than this many rows per request.
  static const _maxRows = 1000;

  static List<CatalogSet>? _sets;
  static final Map<String, List<CatalogCard>> _setCards = {};

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

  /// Every card of one set in printed order (1, 2, ... 10, SWSH001...).
  /// A set holds a few hundred cards at most, so it is loaded once and kept;
  /// searching inside it is then instant (see [filterCards]).
  static Future<List<CatalogCard>> loadSet(String setId) async {
    final cached = _setCards[setId];
    if (cached != null) return cached;
    final cards = <CatalogCard>[];
    while (true) {
      final page =
          await search(setId: setId, offset: cards.length, limit: _maxRows);
      cards.addAll(page);
      if (page.length < _maxRows) break;
    }
    cards.sort(compareByPrintedNumber);
    return _setCards[setId] = cards;
  }

  /// The cards of [cards] whose name contains [query] or whose printed number
  /// equals it — the same rule [search] applies on the server.
  static List<CatalogCard> filterCards(List<CatalogCard> cards, String query) {
    final text = _sanitize(query).toLowerCase();
    if (text.isEmpty) return cards;
    final number = text.split('/').first.trim();
    return cards
        .where((c) =>
            c.name.toLowerCase().contains(text) ||
            c.number.toLowerCase() == number)
        .toList();
  }

  /// Cards matching [query] (name contains it, or the printed number equals
  /// it — `4` and `4/102` both find card 4), optionally limited to one set.
  /// Returns at most [limit] cards (default [searchCap]) from [offset].
  static Future<List<CatalogCard>> search({
    String query = '',
    String? setId,
    int offset = 0,
    int limit = searchCap,
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
        .range(offset, offset + limit - 1);
    return rows.map(CatalogCard.fromRow).toList();
  }

  /// The characters that have a meaning inside a PostgREST `or(...)` filter
  /// or an ILIKE pattern would otherwise change what is searched for.
  static String _sanitize(String input) =>
      input.replaceAll(RegExp(r'[,()%*\\"]'), ' ').trim();
}
