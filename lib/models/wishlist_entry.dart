import 'package:flutter/foundation.dart';
enum WishlistEntryKind { wishlist, trade }

@immutable
class WishlistEntry {
  final String id;
  final String name;
  final String setName;
  final int quantity;
  final String notes;
  final WishlistEntryKind kind;
  final DateTime dateAdded;

  WishlistEntry({
    required this.id,
    required this.name,
    this.setName = '',
    this.quantity = 1,
    this.notes = '',
    required this.kind,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  WishlistEntry copyWith({
    String? name,
    String? setName,
    int? quantity,
    String? notes,
    WishlistEntryKind? kind,
  }) {
    return WishlistEntry(
      id: id,
      name: name ?? this.name,
      setName: setName ?? this.setName,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      kind: kind ?? this.kind,
      dateAdded: dateAdded,
    );
  }

  static List<WishlistEntry> get sampleEntries => [
        WishlistEntry(
          id: 'wish-pikachu-vmax',
          name: 'Pikachu VMAX',
          setName: 'Vivid Voltage',
          quantity: 1,
          kind: WishlistEntryKind.wishlist,
          dateAdded: DateTime.now().subtract(const Duration(days: 6)),
        ),
        WishlistEntry(
          id: 'wish-mewtwo-ex',
          name: 'Mewtwo EX',
          setName: 'Next Destinies',
          quantity: 2,
          kind: WishlistEntryKind.wishlist,
          dateAdded: DateTime.now().subtract(const Duration(days: 3)),
        ),
        WishlistEntry(
          id: 'trade-bulbasaur',
          name: 'Bulbasaur',
          setName: 'Base Set',
          quantity: 2,
          notes: 'Duplicate copy, light edge wear',
          kind: WishlistEntryKind.trade,
          dateAdded: DateTime.now().subtract(const Duration(days: 9)),
        ),
        WishlistEntry(
          id: 'trade-charmander',
          name: 'Charmander',
          setName: 'Base Set',
          quantity: 3,
          kind: WishlistEntryKind.trade,
          dateAdded: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
}
