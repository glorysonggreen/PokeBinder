import 'package:flutter/material.dart';

import '../theme/pokebinder_theme.dart';

/// The energy type shown on a Pokémon card. Drives the card artwork's
/// gradient background, matching the type-colored tiles seen throughout
/// the mockup (binder grid, search results, etc).
enum PokemonCardType { fire, water, grass, electric, psychic, normal }

extension PokemonCardTypeGradient on PokemonCardType {
  /// Gradient colors lifted from the mockup's .card-tile background values
  /// for each type, e.g. fire: linear-gradient(160deg,#f2a99a,#d6301b).
  List<Color> get gradientColors {
    switch (this) {
      case PokemonCardType.fire:
        return const [Color(0xFFF2A99A), Color(0xFFD6301B)];
      case PokemonCardType.water:
        return const [Color(0xFF8FD0D8), Color(0xFF3E7C8C)];
      case PokemonCardType.grass:
        return const [Color(0xFFA8DBA0), Color(0xFF4F8F47)];
      case PokemonCardType.electric:
        return const [Color(0xFFFFD98A), Color(0xFFE8AC3E)];
      case PokemonCardType.psychic:
        return const [Color(0xFFC9C1E6), Color(0xFF7A6DB0)];
      case PokemonCardType.normal:
        return const [Color(0xFFF7C9DC), Color(0xFFD987AC)];
    }
  }
}

/// Only the fields the Card Details screen actually displays, matching the
/// mockup's "Card Details" screen (name, set line, qty/condition,
/// binder/page, est. value, notes).
///
/// If a Pokemon card model already exists elsewhere in this project, reuse
/// that one instead of this file and drop this duplicate.
@immutable
class PokemonCardData {
  final String id;
  final String name;
  final String setName;
  final String cardNumber;
  final String rarity;
  final PokemonCardType type;
  final int quantityOwned;
  final String condition;
  final String binderName;
  final int page;
  final double estimatedValue;
  final String notes;

  /// Optional artwork. When null, the card renders a placeholder silhouette
  /// in the type's gradient colors, same as the mockup's SVG critter icons.
  final String? imageAssetPath;

  const PokemonCardData({
    required this.id,
    required this.name,
    required this.setName,
    required this.cardNumber,
    required this.rarity,
    required this.type,
    required this.quantityOwned,
    required this.condition,
    required this.binderName,
    required this.page,
    required this.estimatedValue,
    this.notes = '',
    this.imageAssetPath,
  });

  /// Sample data matching the mockup's Charizard example, for
  /// previewing/testing the screen standalone.
  static const sample = PokemonCardData(
    id: 'sample-charizard',
    name: 'Charizard',
    setName: 'Base Set',
    cardNumber: '4/102',
    rarity: 'Holo Rare',
    type: PokemonCardType.fire,
    quantityOwned: 2,
    condition: 'NM',
    binderName: 'Rare Holos',
    page: 1,
    estimatedValue: 6200,
    notes: 'Kept in top loader, light corner wear on back.',
    imageAssetPath: '../assets/charizard_base_set.jpg',
  );

  /// The full sample collection shown across the Binders and All Cards
  /// screens, matching the mockup's "All Cards" example set (12 cards).
  /// Only Charizard has real artwork checked into assets/ so far — every
  /// other card intentionally has no imageAssetPath, so the binder grid
  /// shows the universal card back for it, same as it will for any card
  /// added before its own artwork is scanned in.
  static const library = <PokemonCardData>[
    sample,
    PokemonCardData(
      id: 'sample-blastoise',
      name: 'Blastoise',
      setName: 'Base Set',
      cardNumber: '2/102',
      rarity: 'Holo Rare',
      type: PokemonCardType.water,
      quantityOwned: 1,
      condition: 'NM',
      binderName: 'Kanto Starters',
      page: 1,
      estimatedValue: 3400,
    ),
    PokemonCardData(
      id: 'sample-venusaur',
      name: 'Venusaur',
      setName: 'Base Set',
      cardNumber: '15/102',
      rarity: 'Holo Rare',
      type: PokemonCardType.grass,
      quantityOwned: 1,
      condition: 'LP',
      binderName: 'Kanto Starters',
      page: 1,
      estimatedValue: 2900,
    ),
    PokemonCardData(
      id: 'sample-squirtle',
      name: 'Squirtle',
      setName: 'Base Set',
      cardNumber: '63/102',
      rarity: 'Common',
      type: PokemonCardType.water,
      quantityOwned: 3,
      condition: 'NM',
      binderName: 'Kanto Starters',
      page: 2,
      estimatedValue: 120,
    ),
    PokemonCardData(
      id: 'sample-bulbasaur',
      name: 'Bulbasaur',
      setName: 'Base Set',
      cardNumber: '44/102',
      rarity: 'Common',
      type: PokemonCardType.grass,
      quantityOwned: 2,
      condition: 'NM',
      binderName: 'Kanto Starters',
      page: 2,
      estimatedValue: 110,
    ),
    PokemonCardData(
      id: 'sample-pikachu',
      name: 'Pikachu',
      setName: 'Base Set',
      cardNumber: '58/102',
      rarity: 'Common',
      type: PokemonCardType.electric,
      quantityOwned: 4,
      condition: 'NM',
      binderName: 'Rare Holos',
      page: 1,
      estimatedValue: 450,
    ),
    PokemonCardData(
      id: 'sample-raichu',
      name: 'Raichu',
      setName: 'Base Set',
      cardNumber: '14/102',
      rarity: 'Holo Rare',
      type: PokemonCardType.electric,
      quantityOwned: 1,
      condition: 'NM',
      binderName: 'Rare Holos',
      page: 1,
      estimatedValue: 1800,
    ),
    PokemonCardData(
      id: 'sample-alakazam',
      name: 'Alakazam',
      setName: 'Base Set',
      cardNumber: '1/102',
      rarity: 'Holo Rare',
      type: PokemonCardType.psychic,
      quantityOwned: 1,
      condition: 'MP',
      binderName: 'Rare Holos',
      page: 1,
      estimatedValue: 2100,
    ),
    PokemonCardData(
      id: 'sample-mewtwo',
      name: 'Mewtwo',
      setName: 'Base Set',
      cardNumber: '10/102',
      rarity: 'Holo Rare',
      type: PokemonCardType.psychic,
      quantityOwned: 1,
      condition: 'NM',
      binderName: 'Rare Holos',
      page: 1,
      estimatedValue: 3100,
    ),
    PokemonCardData(
      id: 'sample-gyarados',
      name: 'Gyarados',
      setName: 'Base Set',
      cardNumber: '6/102',
      rarity: 'Holo Rare',
      type: PokemonCardType.water,
      quantityOwned: 1,
      condition: 'LP',
      binderName: 'Trade Bait',
      page: 1,
      estimatedValue: 1600,
    ),
    PokemonCardData(
      id: 'sample-vaporeon',
      name: 'Vaporeon',
      setName: 'Jungle',
      cardNumber: '12/64',
      rarity: 'Holo Rare',
      type: PokemonCardType.water,
      quantityOwned: 1,
      condition: 'NM',
      binderName: 'Trade Bait',
      page: 1,
      estimatedValue: 1450,
    ),
    PokemonCardData(
      id: 'sample-jigglypuff',
      name: 'Jigglypuff',
      setName: 'Jungle',
      cardNumber: '54/64',
      rarity: 'Common',
      type: PokemonCardType.normal,
      quantityOwned: 5,
      condition: 'NM',
      binderName: 'Trade Bait',
      page: 1,
      estimatedValue: 60,
    ),
  ];
}
