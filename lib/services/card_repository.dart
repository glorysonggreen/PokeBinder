import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../models/wishlist_entry.dart';
import 'paged_select.dart';
import 'sync_status.dart';
import 'wishlist_repository.dart';

class CardRepository {
  CardRepository._();

  static const _deleteChunk = 100;

  static SupabaseClient get _client => Supabase.instance.client;

  static SupabaseQueryBuilder get _table => _client.from('cards');

  static Future<void> loadAll() async {
    final rows = await fetchAllRows('cards', orderBy: 'date_added', thenBy: 'id');
    final cards = rows.map(PokemonCardData.fromRow).toList();
    PokemonCardData.library
      ..clear()
      ..addAll(cards);
  }

  static Future<void> upsert(PokemonCardData card) {
    _reconcileTradeEntries(card);
    return SyncStatus.track('save that card', () => _table.upsert(card.toRow()));
  }

  static Future<void> delete(String id) => deleteMany([id]);

  static Future<void> deleteMany(Iterable<String> ids) {
    final list = ids.toSet().toList();
    if (list.isEmpty) return Future.value();
    _removeLocally(list.toSet());
    return SyncStatus.track('delete those cards', () async {
      for (var i = 0; i < list.length; i += _deleteChunk) {
        final end = i + _deleteChunk > list.length ? list.length : i + _deleteChunk;
        final part = list.sublist(i, end);
        await WishlistRepository.deleteBySourceCards(part);
        await _client
            .from('trainer_profiles')
            .update({'favorite_card_id': null}).inFilter('favorite_card_id', part);
        await _table.delete().inFilter('id', part);
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

  static void _removeLocally(Set<String> ids) {
    PokemonCardData.library.removeWhere((c) => ids.contains(c.id));
    WishlistEntry.library.removeWhere(
      (e) => e.sourceCardId != null && ids.contains(e.sourceCardId),
    );
    final decks = DeckData.library;
    for (var i = 0; i < decks.length; i++) {
      final deck = decks[i];
      if (!deck.cards.any((c) => ids.contains(c.cardId))) continue;
      decks[i] = deck.copyWith(
        cards: deck.cards.where((c) => !ids.contains(c.cardId)).toList(),
      );
    }
  }

  static void _reconcileTradeEntries(PokemonCardData card) {
    final entries = WishlistEntry.library;
    for (var i = entries.length - 1; i >= 0; i--) {
      final entry = entries[i];
      if (entry.sourceCardId != card.id) continue;
      if (card.quantityOwned <= 0) {
        entries.removeAt(i);
        WishlistRepository.delete(entry.id);
      } else if (entry.quantity > card.quantityOwned) {
        entries[i] = entry.copyWith(quantity: card.quantityOwned);
        WishlistRepository.upsert(entries[i]);
      }
    }
  }
}
