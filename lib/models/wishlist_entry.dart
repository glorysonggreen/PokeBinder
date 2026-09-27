import 'package:flutter/material.dart';
import 'pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';

enum WishlistEntryKind { wishlist, trade }

enum WishlistPriority { high, medium, low }

extension WishlistPriorityDisplay on WishlistPriority {
  String get label {
    switch (this) {
      case WishlistPriority.high:
        return 'High';
      case WishlistPriority.medium:
        return 'Medium';
      case WishlistPriority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case WishlistPriority.high:
        return PokeBinderColors.danger;
      case WishlistPriority.medium:
        return PokeBinderColors.goldDeep;
      case WishlistPriority.low:
        return PokeBinderColors.slate;
    }
  }

  IconData get icon {
    switch (this) {
      case WishlistPriority.high:
        return Icons.arrow_upward_rounded;
      case WishlistPriority.medium:
        return Icons.drag_handle_rounded;
      case WishlistPriority.low:
        return Icons.arrow_downward_rounded;
    }
  }
}

@immutable
class WishlistEntry {
  final String id;
  final String name;
  final String setName;
  final String cardNumber;
  final String rarity;
  final String condition;
  final int quantity;
  final String notes;
  final WishlistEntryKind kind;
  final WishlistPriority priority;
  final double estimatedValue;
  final String askingFor;
  final DateTime dateAdded;

  /// When this entry was added by picking a card straight out of the
  /// collection (e.g. via the Trade List's "Add Cards" picker), this holds
  /// that [PokemonCardData.id] so the picker can find and pre-fill it again.
  /// Entries typed in by hand leave this null.
  final String? sourceCardId;

  /// Asset path for this entry's card image, same as
  /// [PokemonCardData.imageAssetPath]. Falls back to the catalog artwork
  /// (matched by name) when null.
  final String? imageAssetPath;

  WishlistEntry({
    required this.id,
    required this.name,
    required this.setName,
    required this.cardNumber,
    required this.rarity,
    this.condition = 'NM',
    this.quantity = 1,
    this.notes = '',
    required this.kind,
    this.priority = WishlistPriority.medium,
    this.estimatedValue = 0,
    this.askingFor = '',
    this.sourceCardId,
    this.imageAssetPath,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  WishlistEntry copyWith({
    String? name,
    String? setName,
    String? cardNumber,
    String? rarity,
    String? condition,
    int? quantity,
    String? notes,
    WishlistEntryKind? kind,
    WishlistPriority? priority,
    double? estimatedValue,
    String? askingFor,
    String? sourceCardId,
    String? imageAssetPath,
  }) {
    return WishlistEntry(
      id: id,
      name: name ?? this.name,
      setName: setName ?? this.setName,
      cardNumber: cardNumber ?? this.cardNumber,
      rarity: rarity ?? this.rarity,
      condition: condition ?? this.condition,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      kind: kind ?? this.kind,
      priority: priority ?? this.priority,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      askingFor: askingFor ?? this.askingFor,
      sourceCardId: sourceCardId ?? this.sourceCardId,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      dateAdded: dateAdded,
    );
  }

  /// Builds an entry from a row returned by the `wishlist_entries` table.
  factory WishlistEntry.fromRow(Map<String, dynamic> row) {
    return WishlistEntry(
      id: row['id'] as String,
      name: row['name'] as String,
      setName: row['set_name'] as String? ?? '',
      cardNumber: row['card_number'] as String? ?? '',
      rarity: row['rarity'] as String? ?? '',
      condition: row['condition'] as String? ?? 'NM',
      quantity: (row['quantity'] as num?)?.toInt() ?? 1,
      notes: row['notes'] as String? ?? '',
      kind: WishlistEntryKind.values.byName(row['kind'] as String? ?? 'wishlist'),
      priority: WishlistPriority.values
          .byName(row['priority'] as String? ?? 'medium'),
      estimatedValue: (row['estimated_value'] as num?)?.toDouble() ?? 0,
      askingFor: row['asking_for'] as String? ?? '',
      sourceCardId: row['source_card_id'] as String?,
      imageAssetPath: row['image_asset_path'] as String?,
      dateAdded: DateTime.parse(row['date_added'] as String),
    );
  }

  /// The row to upsert into the `wishlist_entries` table. `user_id` is
  /// left out — the column defaults to `auth.uid()` on insert and never
  /// changes on update.
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'name': name,
      'set_name': setName,
      'card_number': cardNumber,
      'rarity': rarity,
      'condition': condition,
      'quantity': quantity,
      'notes': notes,
      'kind': kind.name,
      'priority': priority.name,
      'estimated_value': estimatedValue,
      'asking_for': askingFor,
      'source_card_id': sourceCardId,
      'image_asset_path': imageAssetPath,
      'date_added': dateAdded.toIso8601String(),
    };
  }

  /// The signed-in user's wishlist and trade-list entries, loaded from the
  /// `wishlist_entries` table by [WishlistRepository.loadAll]. Empty until
  /// then.
  static final List<WishlistEntry> library = [];
}