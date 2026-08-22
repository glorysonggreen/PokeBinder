import 'package:flutter/foundation.dart';

import 'pokemon_card_data.dart';

@immutable
class BinderData {
  final String id;
  final String name;
  final PokemonCardType accentType;
  final List<List<PokemonCardData>> pages;

  const BinderData({
    required this.id,
    required this.name,
    required this.accentType,
    required this.pages,
  });

  int get pageCount => pages.length;

  int get cardCount =>
      pages.fold(0, (sum, page) => sum + page.length);

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
        accentType: PokemonCardType.electric,
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