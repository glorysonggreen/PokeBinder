import 'package:flutter/foundation.dart';

import 'pokemon_card_data.dart';

/// Sentinel binder id representing "no binder" — cards a user has logged
/// but hasn't slotted into a binder yet. Not a real [BinderData]; the
/// screen that owns binder state keeps these cards in a separate list and
/// only uses this id to route form results.
const kUnassignedBinderId = '__unassigned__';

@immutable
class BinderData {
  final String id;
  final String name;
  final PokemonCardType accentType;
  final List<List<PokemonCardData>> pages;
  final String description;
  final int slotsPerPage;

  const BinderData({
    required this.id,
    required this.name,
    required this.accentType,
    required this.pages,
    this.description = '',
    this.slotsPerPage = 9,
  });

  int get pageCount => pages.length;

  int get cardCount =>
      pages.fold(0, (sum, page) => sum + page.length);

  /// Returns a copy of this binder with the given fields replaced. Used by
  /// the Add/Edit Binder form and by card add/move operations, which need a
  /// new pages list rather than a mutation of the original.
  BinderData copyWith({
    String? name,
    PokemonCardType? accentType,
    List<List<PokemonCardData>>? pages,
    String? description,
    int? slotsPerPage,
  }) {
    return BinderData(
      id: id,
      name: name ?? this.name,
      accentType: accentType ?? this.accentType,
      pages: pages ?? this.pages,
      description: description ?? this.description,
      slotsPerPage: slotsPerPage ?? this.slotsPerPage,
    );
  }

  static List<BinderData> get sampleBinders {
    PokemonCardData card(String name) =>
        PokemonCardData.library.firstWhere((c) => c.name == name);

    return [
      BinderData(
        id: 'binder-kanto-starters',
        name: 'Kanto Starters',
        accentType: PokemonCardType.fire,
        pages: [
          [card('Charizard'), card('Blastoise'), card('Venusaur')],
          [card('Squirtle'), card('Bulbasaur')],
        ],
      ),
      BinderData(
        id: 'binder-rare-holos',
        name: 'Rare Holos',
        accentType: PokemonCardType.lightning,
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
        accentType: PokemonCardType.water,
        pages: [
          [card('Gyarados'), card('Vaporeon'), card('Jigglypuff')],
        ],
      ),
    ];
  }
}