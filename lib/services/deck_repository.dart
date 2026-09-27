import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deck_data.dart';

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
    final deckRows = await _client.from('decks').select();
    final cardRows = await _client.from('deck_cards').select();

    DeckData.library
      ..clear()
      ..addAll(deckRows.map((row) {
        final deckId = row['id'] as String;
        final cards = cardRows
            .where((c) => c['deck_id'] == deckId)
            .map(DeckCardEntry.fromRow)
            .toList();
        return DeckData.fromRow(row, cards: cards);
      }));
  }

  /// Upserts the deck row, then replaces all of its `deck_cards` rows with
  /// [deck.cards] — simplest way to keep the list in sync for a deck this
  /// small, at the cost of a delete-then-insert on every card change.
  static Future<void> upsert(DeckData deck) async {
    await _client.from('decks').upsert(deck.toRow());
    await _client.from('deck_cards').delete().eq('deck_id', deck.id);
    if (deck.cards.isNotEmpty) {
      await _client
          .from('deck_cards')
          .insert(deck.cards.map((c) => c.toRow(deck.id)).toList());
    }
  }

  static Future<void> delete(String id) {
    // deck_cards rows cascade-delete via the foreign key in schema.sql.
    return _client.from('decks').delete().eq('id', id);
  }
}
