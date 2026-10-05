import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/catalog_card.dart';
import 'paged_select.dart';

class CatalogRepository {
  CatalogRepository._();

  static const searchCap = 200;

  static const _maxRows = 1000;

  static List<CatalogSet>? _sets;
  static final Map<String, List<CatalogCard>> _setCards = {};

  static Future<List<CatalogSet>> loadSets() async {
    final cached = _sets;
    if (cached != null) return cached;
    final rows =
        await fetchAllRows('card_sets', orderBy: 'release_date', thenBy: 'id');
    final sets = rows.map(CatalogSet.fromRow).toList().reversed.toList();
    return _sets = sets;
  }

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

  static String _sanitize(String input) =>
      input.replaceAll(RegExp(r'[,()%*\\"]'), ' ').trim();
}
