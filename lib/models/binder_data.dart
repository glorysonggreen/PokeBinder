import 'package:flutter/foundation.dart';
import 'pokemon_card_data.dart';

const kUnassignedBinderId = '__unassigned__';
const kUncategorized = '';

@immutable
class BinderData {
  final String id;
  final String name;
  final List<List<PokemonCardData>> pages;
  final String description;
  final int slotsPerPage;
  final String category;
  final bool isPinned;
  final DateTime? createdAt;

  const BinderData({
    required this.id,
    required this.name,
    required this.pages,
    this.description = '',
    this.slotsPerPage = 9,
    this.category = kUncategorized,
    this.isPinned = false,
    this.createdAt,
  });

  DateTime get createdAtOrEpoch =>
      createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  int get pageCount => pages.length;
  int get cardCount =>
      pages.fold(0, (sum, page) => sum + page.length);

  BinderData copyWith({
    String? name,
    List<List<PokemonCardData>>? pages,
    String? description,
    int? slotsPerPage,
    String? category,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return BinderData(
      id: id,
      name: name ?? this.name,
      pages: pages ?? this.pages,
      description: description ?? this.description,
      slotsPerPage: slotsPerPage ?? this.slotsPerPage,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<BinderData> get sampleBinders {
    PokemonCardData card(String name) =>
        PokemonCardData.library.firstWhere((c) => c.name == name);
    DateTime daysAgo(int days) =>
        DateTime.now().subtract(Duration(days: days));

    return [
      BinderData(
        id: 'binder-kanto-starters',
        name: 'Kanto Starters',
        category: 'Sets',
        isPinned: true,
        createdAt: daysAgo(2),
        pages: [
          [card('Charizard'), card('Blastoise'), card('Venusaur')],
          [card('Squirtle'), card('Bulbasaur')],
        ],
      ),
      BinderData(
        id: 'binder-rare-holos',
        name: 'Rare Holos',
        category: 'Value',
        createdAt: daysAgo(10),
        pages: [
          [
            card('Pikachu'),
            card('Raichu'),
            card('Alakazam'),
            card('Mewtwo'),
          ],
        ],
      ),
      BinderData(
        id: 'binder-trade-bait',
        name: 'Trade Bait',
        category: 'Value',
        createdAt: daysAgo(1),
        pages: [
          [card('Gyarados'), card('Vaporeon'), card('Jigglypuff')],
        ],
      ),
    ];
  }
}