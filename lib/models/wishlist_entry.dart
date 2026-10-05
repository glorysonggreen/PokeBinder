import 'package:flutter/material.dart';
import 'enum_parsing.dart';
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

  final String? sourceCardId;

  final String? imageAssetPath;
  final String? catalogId;
  final String? finish;

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
    this.catalogId,
    this.finish,
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
    String? catalogId,
    String? finish,
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
      catalogId: catalogId ?? this.catalogId,
      finish: finish ?? this.finish,
      dateAdded: dateAdded,
    );
  }

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
      kind: enumByNameOr(WishlistEntryKind.values, row['kind'] as String?,
          WishlistEntryKind.wishlist),
      priority: enumByNameOr(WishlistPriority.values,
          row['priority'] as String?, WishlistPriority.medium),
      estimatedValue: (row['estimated_value'] as num?)?.toDouble() ?? 0,
      askingFor: row['asking_for'] as String? ?? '',
      sourceCardId: row['source_card_id'] as String?,
      imageAssetPath: row['image_asset_path'] as String?,
      catalogId: row['catalog_id'] as String?,
      finish: row['finish'] as String?,
      dateAdded: DateTime.parse(row['date_added'] as String).toLocal(),
    );
  }

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
      'catalog_id': catalogId,
      'finish': finish,
      'date_added': dateAdded.toUtc().toIso8601String(),
    };
  }

  static final List<WishlistEntry> library = [];
}
