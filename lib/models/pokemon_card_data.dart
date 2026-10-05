import 'package:flutter/material.dart';
import 'enum_parsing.dart';

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

const kRarityOptions = [
  'Common',
  'Uncommon',
  'Rare',
  'Double Rare',
  'Illustration Rare',
  'Special Illustration Rare',
  'Hyper Rare',
  'Promo',
  'Other/Additional Rarities',
];

const kConditionOptions = [
  ('Near Mint', 'NM'),
  ('Lightly Played', 'LP'),
  ('Moderately Played', 'MP'),
  ('Damaged', 'DMG'),
];

IconData rarityIconFor(String rarity) {
  switch (rarity) {
    case 'Common':
      return Icons.circle_outlined;
    case 'Uncommon':
      return Icons.star_border_rounded;
    case 'Rare':
      return Icons.star_rounded;
    case 'Double Rare':
      return Icons.stars_rounded;
    case 'Illustration Rare':
      return Icons.brush_rounded;
    case 'Special Illustration Rare':
      return Icons.auto_awesome_rounded;
    case 'Hyper Rare':
      return Icons.workspace_premium_rounded;
    case 'Promo':
      return Icons.local_offer_rounded;
    default:
      return Icons.category_rounded;
  }
}

IconData conditionIconFor(String code) {
  switch (code) {
    case 'NM':
      return Icons.verified_outlined;
    case 'LP':
      return Icons.check_circle_outline_rounded;
    case 'MP':
      return Icons.remove_circle_outline_rounded;
    case 'DMG':
      return Icons.broken_image_outlined;
    default:
      return Icons.help_outline_rounded;
  }
}

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

  IconData get typeIcon {
    switch (this) {
      case PokemonCardType.colorless:
        return Icons.circle;
      case PokemonCardType.grass:
        return Icons.eco_rounded;
      case PokemonCardType.fire:
        return Icons.local_fire_department_rounded;
      case PokemonCardType.water:
        return Icons.water_drop_rounded;
      case PokemonCardType.lightning:
        return Icons.bolt_rounded;
      case PokemonCardType.fighting:
        return Icons.sports_mma_rounded;
      case PokemonCardType.psychic:
        return Icons.psychology_rounded;
      case PokemonCardType.darkness:
        return Icons.dark_mode_rounded;
      case PokemonCardType.metal:
        return Icons.settings_rounded;
      case PokemonCardType.dragon:
        return Icons.all_inclusive_rounded;
      case PokemonCardType.fairy:
        return Icons.local_florist_rounded;
    }
  }
}

@immutable
class PokemonCardData {
  final String id;
  final String name;
  final String setName;
  final String cardNumber;
  final String rarity;
  final PokemonCardType type;
  final CardSupertype supertype;
  final String? subtype;
  final int quantityOwned;
  final String condition;
  final String binderName;
  final int page;
  final double estimatedValue;
  final String notes;
  final String? imageAssetPath;

  final String? catalogId;

  final String? finish;
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
    this.catalogId,
    this.finish,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  factory PokemonCardData.fromRow(Map<String, dynamic> row) {
    return PokemonCardData(
      id: row['id'] as String,
      name: row['name'] as String,
      setName: row['set_name'] as String? ?? '',
      cardNumber: row['card_number'] as String? ?? '',
      rarity: row['rarity'] as String? ?? '',
      type: enumByNameOr(PokemonCardType.values, row['type'] as String?,
          PokemonCardType.colorless),
      supertype: enumByNameOr(CardSupertype.values,
          row['supertype'] as String?, CardSupertype.pokemon),
      subtype: row['subtype'] as String?,
      quantityOwned: (row['quantity_owned'] as num?)?.toInt() ?? 0,
      condition: row['condition'] as String? ?? 'NM',
      binderName: row['binder_name'] as String? ?? 'Unassigned',
      page: (row['page'] as num?)?.toInt() ?? 0,
      estimatedValue: (row['estimated_value'] as num?)?.toDouble() ?? 0,
      notes: row['notes'] as String? ?? '',
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
      'type': type.name,
      'supertype': supertype.name,
      'subtype': subtype,
      'quantity_owned': quantityOwned,
      'condition': condition,
      'binder_name': binderName,
      'page': page,
      'estimated_value': estimatedValue,
      'notes': notes,
      'image_asset_path': imageAssetPath,
      'catalog_id': catalogId,
      if (finish != null) 'finish': finish,
      'date_added': dateAdded.toUtc().toIso8601String(),
    };
  }

  PokemonCardData copyWith({
    String? id,
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
    String? catalogId,
    String? finish,
    DateTime? dateAdded,
  }) {
    return PokemonCardData(
      id: id ?? this.id,
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
      catalogId: catalogId ?? this.catalogId,
      finish: finish ?? this.finish,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  static final List<PokemonCardData> library = [];
}
