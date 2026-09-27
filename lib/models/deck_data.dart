import 'package:flutter/material.dart';

enum DeckFormat { standard, expanded, casual }

extension DeckFormatMeta on DeckFormat {
  String get label {
    switch (this) {
      case DeckFormat.standard:
        return 'Standard';
      case DeckFormat.expanded:
        return 'Expanded';
      case DeckFormat.casual:
        return 'Casual';
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

  /// Distinct icon per format, used anywhere a format is shown (filter
  /// chips, dropdowns, tags) so each one stays visually identifiable.
  IconData get icon {
    switch (this) {
      case DeckFormat.standard:
        return Icons.verified_rounded;
      case DeckFormat.expanded:
        return Icons.open_in_full_rounded;
      case DeckFormat.casual:
        return Icons.coffee_rounded;
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

  factory DeckCardEntry.fromRow(Map<String, dynamic> row) {
    return DeckCardEntry(
      cardId: row['card_id'] as String,
      quantity: (row['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  /// The row to upsert into `deck_cards`. Needs [deckId] since a
  /// [DeckCardEntry] doesn't know which deck it belongs to on its own.
  Map<String, dynamic> toRow(String deckId) {
    return {'deck_id': deckId, 'card_id': cardId, 'quantity': quantity};
  }
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

  /// Builds a deck from a row returned by the `decks` table plus its
  /// already-fetched rows from `deck_cards`.
  factory DeckData.fromRow(
    Map<String, dynamic> row, {
    List<DeckCardEntry> cards = const [],
  }) {
    return DeckData(
      id: row['id'] as String,
      name: row['name'] as String,
      format: DeckFormat.values.byName(row['format'] as String? ?? 'standard'),
      targetSize: (row['target_size'] as num?)?.toInt() ?? 60,
      description: row['description'] as String? ?? '',
      cards: cards,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.parse(row['created_at'] as String),
      isPinned: row['is_pinned'] as bool? ?? false,
    );
  }

  /// The row to upsert into the `decks` table. Doesn't include [cards] —
  /// those are synced separately into `deck_cards`. `user_id` is left out
  /// too, since the column defaults to `auth.uid()` on insert and never
  /// changes on update.
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'name': name,
      'format': format.name,
      'target_size': targetSize,
      'description': description,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
    };
  }

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

  /// The signed-in user's decks, loaded from the `decks` and `deck_cards`
  /// tables by [DeckRepository.loadAll]. Empty until then.
  static final List<DeckData> library = [];
}