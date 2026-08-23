import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';

enum PokemonCardType {
  colorless,
  grass,
  fire,
  water,
  lightning,
  fighting,
  psychic,
  darkness,
  metal,
  dragon,
  fairy,
}

enum CardSupertype { pokemon, trainer, energy }

extension PokemonCardTypeGradient on PokemonCardType {
  List<Color> get gradientColors {
    switch (this) {
      case PokemonCardType.colorless:
        return const [Color(0xFFE8E1D0), Color(0xFFAFA48C)];
      case PokemonCardType.grass:
        return const [Color(0xFFA8DBA0), Color(0xFF4F8F47)];
      case PokemonCardType.fire:
        return const [Color(0xFFF2A99A), Color(0xFFD6301B)];
      case PokemonCardType.water:
        return const [Color(0xFF8FD0D8), Color(0xFF3E7C8C)];
      case PokemonCardType.lightning:
        return const [Color(0xFFFFD98A), Color(0xFFE8AC3E)];
      case PokemonCardType.fighting:
        return const [Color(0xFFE3A87C), Color(0xFFA8531F)];
      case PokemonCardType.psychic:
        return const [Color(0xFFC9C1E6), Color(0xFF7A6DB0)];
      case PokemonCardType.darkness:
        return const [Color(0xFF8B849A), Color(0xFF332C42)];
      case PokemonCardType.metal:
        return const [Color(0xFFD9D9E3), Color(0xFF8C8C99)];
      case PokemonCardType.dragon:
        return const [Color(0xFFF5CB7E), Color(0xFFC98A2E)];
      case PokemonCardType.fairy:
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
  final CardSupertype supertype;

  /// Only meaningful for Trainer ("Item"/"Supporter"/"Stadium") and Energy
  /// ("Basic"/"Special") cards; null for Pokémon cards, which use [type]
  /// instead.
  final String? subtype;
  final int quantityOwned;
  final String condition;
  final String binderName;
  final int page;
  final double estimatedValue;
  final String notes;

  /// Optional artwork. When null, the card renders a placeholder silhouette
  /// in the type's gradient colors, same as the mockup's SVG critter icons.
  final String? imageAssetPath;

  /// When this card was added to the collection. Drives the "Time" sort
  /// option's Newest/Oldest ordering. Defaults to now for freshly
  /// created/scanned cards.
  final DateTime dateAdded;

  PokemonCardData({
    required this.id,
    required this.name,
    required this.setName,
    required this.cardNumber,
    required this.rarity,
    required this.type,
    this.supertype = CardSupertype.pokemon,
    this.subtype,
    required this.quantityOwned,
    required this.condition,
    required this.binderName,
    required this.page,
    required this.estimatedValue,
    this.notes = '',
    this.imageAssetPath,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  /// Returns a copy of this card with the given fields replaced. Used by the
  /// Add/Edit Card form so an edit produces a new immutable card rather than
  /// mutating the original in place.
  PokemonCardData copyWith({
    String? name,
    String? setName,
    String? cardNumber,
    String? rarity,
    PokemonCardType? type,
    CardSupertype? supertype,
    String? subtype,
    int? quantityOwned,
    String? condition,
    String? binderName,
    int? page,
    double? estimatedValue,
    String? notes,
    String? imageAssetPath,
    DateTime? dateAdded,
  }) {
    return PokemonCardData(
      id: id,
      name: name ?? this.name,
      setName: setName ?? this.setName,
      cardNumber: cardNumber ?? this.cardNumber,
      rarity: rarity ?? this.rarity,
      type: type ?? this.type,
      supertype: supertype ?? this.supertype,
      subtype: subtype ?? this.subtype,
      quantityOwned: quantityOwned ?? this.quantityOwned,
      condition: condition ?? this.condition,
      binderName: binderName ?? this.binderName,
      page: page ?? this.page,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      notes: notes ?? this.notes,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  /// Sample data matching the mockup's Charizard example, for
  /// previewing/testing the screen standalone.
  static final sample = PokemonCardData(
    id: 'sample-charizard',
    dateAdded: DateTime(2023, 1, 15),
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
  static final library = <PokemonCardData>[
    sample,
    PokemonCardData(
      id: 'sample-blastoise',
      dateAdded: DateTime(2023, 2, 1),
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
      imageAssetPath: '../assets/blastoise_base_set.jpg',
    ),
    PokemonCardData(
      id: 'sample-venusaur',
      dateAdded: DateTime(2023, 2, 15),
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
      imageAssetPath: '../assets/venusaur_base_set.jpg',
    ),
    PokemonCardData(
      id: 'sample-squirtle',
      dateAdded: DateTime(2023, 3, 1),
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
      imageAssetPath: '../assets/squirtle_base_set.jpg',
    ),
    PokemonCardData(
      id: 'sample-bulbasaur',
      dateAdded: DateTime(2023, 3, 10),
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
      imageAssetPath: '../assets/bulbasaur_base_set.jpg',
    ),
    PokemonCardData(
      id: 'sample-pikachu',
      dateAdded: DateTime(2023, 4, 5),
      name: 'Pikachu',
      setName: 'Base Set',
      cardNumber: '58/102',
      rarity: 'Common',
      type: PokemonCardType.lightning,
      quantityOwned: 4,
      condition: 'NM',
      binderName: 'Rare Holos',
      page: 1,
      estimatedValue: 450,
      imageAssetPath: '../assets/pikachu_base_set.jpg', 
    ),
    PokemonCardData(
      id: 'sample-raichu',
      dateAdded: DateTime(2023, 4, 20),
      name: 'Raichu',
      setName: 'Base Set',
      cardNumber: '14/102',
      rarity: 'Holo Rare',
      type: PokemonCardType.lightning,
      quantityOwned: 1,
      condition: 'NM',
      binderName: 'Rare Holos',
      page: 1,
      estimatedValue: 1800,
      imageAssetPath: '../assets/raichu_base_set.jpg',
    ),
    PokemonCardData(
      id: 'sample-alakazam',
      dateAdded: DateTime(2023, 5, 12),
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
      imageAssetPath: '../assets/alakazam_base_set.jpg',
    ),
    PokemonCardData(
      id: 'sample-mewtwo',
      dateAdded: DateTime(2023, 6, 1),
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
      imageAssetPath: '../assets/mewtwo_base_set.jpg',
    ),
    PokemonCardData(
      id: 'sample-gyarados',
      dateAdded: DateTime(2023, 6, 18),
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
      imageAssetPath: '../assets/gyarados_base_set.jpg',
    ),
    PokemonCardData(
      id: 'sample-vaporeon',
      dateAdded: DateTime(2023, 7, 9),
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
      imageAssetPath: '../assets/vaporeon_jungle.jpg',
    ),
    PokemonCardData(
      id: 'sample-jigglypuff',
      dateAdded: DateTime(2023, 8, 1),
      name: 'Jigglypuff',
      setName: 'Jungle',
      cardNumber: '54/64',
      rarity: 'Common',
      type: PokemonCardType.colorless,
      quantityOwned: 5,
      condition: 'NM',
      binderName: 'Trade Bait',
      page: 1,
      estimatedValue: 60,
      imageAssetPath: '../assets/jigglypuff_jungle.jpg',
    ),
    PokemonCardData(
      id: 'sample-potion',
      dateAdded: DateTime(2023, 9, 14),
      name: 'Potion',
      setName: 'Base Set',
      cardNumber: '20/102',
      rarity: 'Common',
      type: PokemonCardType.colorless,
      supertype: CardSupertype.trainer,
      subtype: 'Item',
      quantityOwned: 3,
      condition: 'NM',
      binderName: 'Unassigned',
      page: 0,
      estimatedValue: 5,
      imageAssetPath: '../assets/potion_base_set.jpg',
    ),
    PokemonCardData(
      id: 'sample-misty',
      dateAdded: DateTime(2023, 10, 2),
      name: 'Misty',
      setName: 'Gym',
      cardNumber: '18/132',
      rarity: 'Holo Rare',
      type: PokemonCardType.colorless,
      supertype: CardSupertype.trainer,
      subtype: 'Supporter',
      quantityOwned: 2,
      condition: 'NM',
      binderName: 'Unassigned',
      page: 0,
      estimatedValue: 15,
      imageAssetPath: '../assets/misty_gym_heroes.jpg',
    ),
    PokemonCardData(
      id: 'sample-cerulean-city-gym',
      dateAdded: DateTime(2023, 11, 11),
      name: 'Cerulean City Gym',
      setName: 'Gym',
      cardNumber: '108/132',
      rarity: 'Uncommon',
      type: PokemonCardType.colorless,
      supertype: CardSupertype.trainer,
      subtype: 'Stadium',
      quantityOwned: 1,
      condition: 'LP',
      binderName: 'Unassigned',
      page: 0,
      estimatedValue: 22,
      imageAssetPath: '../assets/cerulean_city_gym_gym.jpg',
    ),
    PokemonCardData(
      id: 'sample-fire-energy',
      dateAdded: DateTime(2023, 12, 5),
      name: 'Fire Energy',
      setName: 'Base Set',
      cardNumber: '98/102',
      rarity: 'Common',
      type: PokemonCardType.fire,
      supertype: CardSupertype.energy,
      subtype: 'Basic',
      quantityOwned: 8,
      condition: 'NM',
      binderName: 'Unassigned',
      page: 0,
      estimatedValue: 1,
      imageAssetPath: '../assets/fire_energy_base_set.jpg',
    ),
    PokemonCardData(
      id: 'sample-double-colorless-energy',
      dateAdded: DateTime(2024, 1, 20),
      name: 'Double Colorless Energy',
      setName: 'Base Set',
      cardNumber: '96/102',
      rarity: 'Uncommon',
      type: PokemonCardType.colorless,
      supertype: CardSupertype.energy,
      subtype: 'Special',
      quantityOwned: 2,
      condition: 'NM',
      binderName: 'Unassigned',
      page: 0,
      estimatedValue: 8,
      imageAssetPath: '../assets/double_colorless_energy_base_set.jpg',
    ),
  ];
}