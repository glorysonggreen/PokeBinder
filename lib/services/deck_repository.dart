import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import 'paged_select.dart';
import 'sync_status.dart';

/// Syncs [DeckData.library] with the `decks` and `deck_cards` tables.
/// Screens keep mutating `library` directly; they just also call [upsert]
/// or [delete] alongside each mutation so the change is persisted.
class DeckRepository {
  DeckRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Replaces [DeckData.library] with everything the signed-in user owns,
  /// each deck's `cards` filled in from `deck_cards`. Called once by
  /// AppShell on load.
  static Future<void> loadAll() async {
    final deckRows =
        await fetchAllRows('decks', orderBy: 'created_at', thenBy: 'id');
    final cardRows = await fetchAllRows(
      'deck_cards',
      orderBy: 'deck_id',
      thenBy: 'card_id',
    );

    final cardsByDeck = <String, List<DeckCardEntry>>{};
    for (final row in cardRows) {
      cardsByDeck
          .putIfAbsent(row['deck_id'] as String, () => [])
          .add(DeckCardEntry.fromRow(row));
    }

    final decks = deckRows
        .map((row) => DeckData.fromRow(
              row,
              cards: cardsByDeck[row['id'] as String] ?? const [],
            ))
        .toList();
    DeckData.library
      ..clear()
      ..addAll(decks);
  }

  /// Saves the deck row, then makes its `deck_cards` rows match
  /// [deck.cards].
  ///
  /// This used to delete *all* of the deck's rows and then re-insert them.
  /// If the insert failed (a card id that no longer exists, a dropped
  /// connection) the deck was left empty on the server even though it looked
  /// fine locally. Now the current rows are upserted first and only the
  /// leftovers are deleted afterwards, so a failure part-way leaves a
  /// slightly stale deck rather than an empty one.
  ///
  /// Entries are skipped if their card is no longer in the collection or
  /// their quantity isn't positive — either one would make the whole save
  /// fail (foreign key / `quantity > 0` check) and lose the other changes.
  static Future<void> upsert(DeckData deck) {
    final ownedIds = PokemonCardData.library.map((c) => c.id).toSet();
    final entries = deck.cards
        .where((c) => c.quantity > 0 && ownedIds.contains(c.cardId))
        .toList();

    return SyncStatus.track('save that deck', () async {
      await _client.from('decks').upsert(deck.toRow());

      if (entries.isNotEmpty) {
        await _client.from('deck_cards').upsert(
              entries.map((c) => c.toRow(deck.id)).toList(),
              onConflict: 'deck_id,card_id',
            );
      }

      final keep = entries.map((c) => c.cardId).toSet();
      final existing =
          await _client.from('deck_cards').select('card_id').eq('deck_id', deck.id);
      final stale = existing
          .map((row) => row['card_id'] as String)
          .where((id) => !keep.contains(id))
          .toList();
      if (stale.isNotEmpty) {
        await _client
            .from('deck_cards')
            .delete()
            .eq('deck_id', deck.id)
            .inFilter('card_id', stale);
      }
    });
  }

  static Future<void> delete(String id) {
    // deck_cards rows cascade-delete via the foreign key in schema.sql.
    return SyncStatus.track(
      'delete that deck',
      () => _client.from('decks').delete().eq('id', id),
    );
  }
}
