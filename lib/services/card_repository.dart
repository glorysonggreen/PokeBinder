import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pokemon_card_data.dart';

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
    final rows = await _table.select();
    PokemonCardData.library
      ..clear()
      ..addAll(rows.map(PokemonCardData.fromRow));
  }

  /// Persists a new or edited card. Fire-and-forget — the local list is
  /// already the source of truth for the UI, so callers don't need to wait
  /// on this to keep the screen responsive.
  static Future<void> upsert(PokemonCardData card) {
    return _table.upsert(card.toRow());
  }

  static Future<void> delete(String id) {
    return _table.delete().eq('id', id);
  }
}
