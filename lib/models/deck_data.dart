import 'package:flutter/foundation.dart';

enum DeckFormat { standard, expanded, casual }

extension DeckFormatMeta on DeckFormat {
  String get label {
    switch (this) {
      case DeckFormat.standard:
        return 'Standard';
      case DeckFormat.expanded:
        return 'Expanded';
      case DeckFormat.casual:
        return 'Casual / Kitchen table';
    }
  }

  /// Compact version of [label] for use in small tags/chips.
  String get shortLabel {
    switch (this) {
      case DeckFormat.standard:
        return 'Standard';
      case DeckFormat.expanded:
        return 'Expanded';
      case DeckFormat.casual:
        return 'Casual';
    }
  }
}

@immutable
class DeckCardEntry {
  final String cardId;
  final int quantity;

  const DeckCardEntry({required this.cardId, required this.quantity});

  DeckCardEntry copyWith({int? quantity}) =>
      DeckCardEntry(cardId: cardId, quantity: quantity ?? this.quantity);
}

@immutable
class DeckData {
  final String id;
  final String name;
  final DeckFormat format;
  final int targetSize;
  final String description;
  final List<DeckCardEntry> cards;
  final DateTime createdAt;
  final bool isPinned;

  DeckData({
    required this.id,
    required this.name,
    this.format = DeckFormat.standard,
    this.targetSize = 60,
    this.description = '',
    List<DeckCardEntry>? cards,
    DateTime? createdAt,
    this.isPinned = false,
  })  : cards = cards ?? const [],
        createdAt = createdAt ?? DateTime.now();

  int get cardCount => cards.fold(0, (sum, c) => sum + c.quantity);

  DeckData copyWith({
    String? name,
    DeckFormat? format,
    int? targetSize,
    String? description,
    List<DeckCardEntry>? cards,
    bool? isPinned,
  }) {
    return DeckData(
      id: id,
      name: name ?? this.name,
      format: format ?? this.format,
      targetSize: targetSize ?? this.targetSize,
      description: description ?? this.description,
      cards: cards ?? this.cards,
      createdAt: createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  static List<DeckData> get sampleDecks => [
        DeckData(
          id: 'deck-fire-starter-rush',
          name: 'Fire Starter Rush',
          format: DeckFormat.standard,
          targetSize: 15,
          description: 'Aggressive fire deck built around Charizard.',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          isPinned: true,
          cards: const [
            DeckCardEntry(cardId: 'sample-charizard', quantity: 2),
            DeckCardEntry(cardId: 'sample-fire-energy', quantity: 8),
            DeckCardEntry(cardId: 'sample-potion', quantity: 3),
            DeckCardEntry(cardId: 'sample-double-colorless-energy', quantity: 2),
          ],
        ),
        DeckData(
          id: 'deck-water-control',
          name: 'Water Control',
          format: DeckFormat.standard,
          targetSize: 20,
          description: 'Stall the game out with Blastoise and healing.',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
          cards: const [
            DeckCardEntry(cardId: 'sample-squirtle', quantity: 3),
            DeckCardEntry(cardId: 'sample-blastoise', quantity: 2),
            DeckCardEntry(cardId: 'sample-potion', quantity: 4),
            DeckCardEntry(cardId: 'sample-gyarados', quantity: 2),
            DeckCardEntry(cardId: 'sample-vaporeon', quantity: 2),
          ],
        ),
      ];
}