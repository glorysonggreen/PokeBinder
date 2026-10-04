import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import 'paged_select.dart';
import 'sync_status.dart';

/// Syncs [PokemonCardData.library] with the `cards` table. Screens keep
/// mutating `library` directly (unchanged from before this file existed);
/// they just also call [upsert] or [delete] alongside each mutation so the
/// change is persisted.
class CardRepository {
  CardRepository._();

  static SupabaseQueryBuilder get _table =>
      Supabase.instance.client.from('cards');

  /// Replaces [PokemonCardData.library] with everything the signed-in user
  /// owns. Called once by AppShell on load.
  static Future<void> loadAll() async {
    final rows = await fetchAllRows('cards', orderBy: 'date_added', thenBy: 'id');
    // Parse first, then swap, so a bad row can't leave the list half-empty.
    final cards = rows.map(PokemonCardData.fromRow).toList();
    PokemonCardData.library
      ..clear()
      ..addAll(cards);
  }

  /// Persists a new or edited card. Fire-and-forget — the local list is
  /// already the source of truth for the UI, so callers don't need to wait
  /// on this to keep the screen responsive.
  static Future<void> upsert(PokemonCardData card) {
    return SyncStatus.track('save that card', () => _table.upsert(card.toRow()));
  }

  /// Deletes a card. The database cascades the delete to every `deck_cards`
  /// row that uses it, so the same is applied to [DeckData.library] here —
  /// otherwise a deck would keep a ghost entry locally, and the next save of
  /// that deck would try to re-insert a `card_id` that no longer exists.
  static Future<void> delete(String id) {
    _removeFromLocalDecks(id);
    return SyncStatus.track('delete that card', () => _table.delete().eq('id', id));
  }

  /// Moves every card whose `binder_name` is [oldName] to [newName] in a
  /// single request (optionally resetting `page` to 0, used when a binder is
  /// deleted and its cards fall back to Unassigned). Renaming a binder used
  /// to send one upsert per card — hundreds of requests for a big binder.
  /// The caller is still responsible for updating the in-memory library.
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
