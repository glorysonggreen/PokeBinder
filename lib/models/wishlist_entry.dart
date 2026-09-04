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
      dateAdded: dateAdded,
    );
  }

  static List<WishlistEntry> get sampleEntries => [
        WishlistEntry(
          id: 'wish-pikachu-vmax',
          name: 'Pikachu VMAX',
          setName: 'Vivid Voltage',
          cardNumber: '44/185',
          rarity: 'Hyper Rare',
          quantity: 1,
          kind: WishlistEntryKind.wishlist,
          priority: WishlistPriority.high,
          estimatedValue: 1800,
          dateAdded: DateTime.now().subtract(const Duration(days: 6)),
        ),
        WishlistEntry(
          id: 'wish-mewtwo-ex',
          name: 'Mewtwo EX',
          setName: 'Next Destinies',
          cardNumber: '54/99',
          rarity: 'Double Rare',
          quantity: 2,
          kind: WishlistEntryKind.wishlist,
          priority: WishlistPriority.medium,
          estimatedValue: 950,
          dateAdded: DateTime.now().subtract(const Duration(days: 3)),
        ),
        WishlistEntry(
          id: 'trade-bulbasaur',
          name: 'Bulbasaur',
          setName: 'Base Set',
          cardNumber: '44/102',
          rarity: 'Common',
          condition: 'LP',
          quantity: 2,
          notes: 'Duplicate copy, light edge wear',
          kind: WishlistEntryKind.trade,
          priority: WishlistPriority.low,
          estimatedValue: 110,
          askingFor: 'Any Base Set Fire-type',
          dateAdded: DateTime.now().subtract(const Duration(days: 9)),
        ),
        WishlistEntry(
          id: 'trade-charmander',
          name: 'Charmander',
          setName: 'Base Set',
          cardNumber: '46/102',
          rarity: 'Common',
          quantity: 3,
          kind: WishlistEntryKind.trade,
          priority: WishlistPriority.medium,
          estimatedValue: 90,
          askingFor: 'Pikachu VMAX or store credit',
          dateAdded: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
}