import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import 'paged_select.dart';
import 'sync_status.dart';

class CardRepository {
  CardRepository._();

  static SupabaseQueryBuilder get _table =>
      Supabase.instance.client.from('cards');

  static Future<void> loadAll() async {
    final rows = await fetchAllRows('cards', orderBy: 'date_added', thenBy: 'id');
    final cards = rows.map(PokemonCardData.fromRow).toList();
    PokemonCardData.library
      ..clear()
      ..addAll(cards);
  }

  static Future<void> upsert(PokemonCardData card) {
    return SyncStatus.track('save that card', () => _table.upsert(card.toRow()));
  }

  static Future<void> delete(String id) {
    _removeFromLocalDecks(id);
    return SyncStatus.track('delete that card', () => _table.delete().eq('id', id));
  }

  static Future<void> deleteMany(Iterable<String> ids) {
    final list = ids.toList();
    if (list.isEmpty) return Future.value();
    list.forEach(_removeFromLocalDecks);
    return SyncStatus.track('delete those cards', () async {
      const chunk = 100;
      for (var i = 0; i < list.length; i += chunk) {
        final end = i + chunk > list.length ? list.length : i + chunk;
        await _table.delete().inFilter('id', list.sublist(i, end));
      }
    });
  }

  static Future<void> renameBinder(
    String oldName,
    String newName, {
    bool resetPage = false,
  }) {
    return SyncStatus.track(
      'update the cards in that binder',
      () => _table
          .update({'binder_name': newName, if (resetPage) 'page': 0})
          .eq('binder_name', oldName),
    );
  }

  static void _removeFromLocalDecks(String cardId) {
    final decks = DeckData.library;
    for (var i = 0; i < decks.length; i++) {
      final deck = decks[i];
      if (!deck.cards.any((c) => c.cardId == cardId)) continue;
      decks[i] = deck.copyWith(
        cards: deck.cards.where((c) => c.cardId != cardId).toList(),
      );
    }
  }
}
