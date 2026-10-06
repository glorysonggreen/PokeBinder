import 'package:flutter/material.dart';

import '../theme/pokebinder_theme.dart';
import 'enum_parsing.dart';
import 'pokemon_card_data.dart';

enum DeckFormat { standard, expanded, casual }

extension DeckFormatAccent on DeckFormat {
  Color get accentColor {
    switch (this) {
      case DeckFormat.standard:
        return PokeBinderColors.teal;
      case DeckFormat.expanded:
        return PokeBinderColors.goldDeep;
      case DeckFormat.casual:
        return PokeBinderColors.slate;
    }
  }
}

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

  double get totalValue {
    final values = {
      for (final c in PokemonCardData.library) c.id: c.estimatedValue,
    };
    return cards.fold(
      0.0,
      (sum, entry) => sum + (values[entry.cardId] ?? 0) * entry.quantity,
    );
  }

  factory DeckData.fromRow(
    Map<String, dynamic> row, {
    List<DeckCardEntry> cards = const [],
  }) {
    return DeckData(
      id: row['id'] as String,
      name: row['name'] as String,
      format: enumByNameOr(
          DeckFormat.values, row['format'] as String?, DeckFormat.standard),
      targetSize: (row['target_size'] as num?)?.toInt() ?? 60,
      description: row['description'] as String? ?? '',
      cards: cards,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.parse(row['created_at'] as String).toLocal(),
      isPinned: row['is_pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'name': name,
      'format': format.name,
      'target_size': targetSize,
      'description': description,
      'is_pinned': isPinned,
      'created_at': createdAt.toUtc().toIso8601String(),
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

  static final List<DeckData> library = [];
}
