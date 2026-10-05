import 'package:flutter/material.dart';
import '../models/catalog_card.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';

enum CardSortOption {
  alphabetical,
  time,
  pokemon,
  trainer,
  energy,
  set,
  cardNumber,
  rarity,
  price,
  condition,
  quantity,
}

extension CardSortOptionLabel on CardSortOption {
  String get label {
    switch (this) {
      case CardSortOption.alphabetical:
        return 'Alphabetical';
      case CardSortOption.time:
        return 'Time';
      case CardSortOption.pokemon:
        return 'Pokémon';
      case CardSortOption.trainer:
        return 'Trainer';
      case CardSortOption.energy:
        return 'Energy';
      case CardSortOption.set:
        return 'Set';
      case CardSortOption.cardNumber:
        return 'Card Number';
      case CardSortOption.rarity:
        return 'Rarity';
      case CardSortOption.price:
        return 'Price';
      case CardSortOption.condition:
        return 'Condition';
      case CardSortOption.quantity:
        return 'Quantity';
    }
  }

  IconData get icon {
    switch (this) {
      case CardSortOption.alphabetical:
        return Icons.sort_by_alpha_rounded;
      case CardSortOption.time:
        return Icons.schedule_rounded;
      case CardSortOption.pokemon:
        return Icons.catching_pokemon;
      case CardSortOption.trainer:
        return Icons.badge_outlined;
      case CardSortOption.energy:
        return Icons.power_rounded;
      case CardSortOption.set:
        return Icons.collections_bookmark_outlined;
      case CardSortOption.cardNumber:
        return Icons.tag_rounded;
      case CardSortOption.rarity:
        return Icons.diamond_rounded;
      case CardSortOption.price:
        return Icons.payments_rounded;
      case CardSortOption.condition:
        return Icons.health_and_safety_outlined;
      case CardSortOption.quantity:
        return Icons.format_list_numbered_rounded;
    }
  }
}

enum TimeSortDirection { newest, oldest }

extension TimeSortDirectionLabel on TimeSortDirection {
  String get label {
    switch (this) {
      case TimeSortDirection.newest:
        return 'Newest';
      case TimeSortDirection.oldest:
        return 'Oldest';
    }
  }
}

class CardSortSelector extends StatelessWidget {
  final CardSortOption selected;
  final ValueChanged<CardSortOption> onChanged;

  final List<CardSortOption> options;

  const CardSortSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.options = CardSortOption.values,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: PokeBinderColors.red.withValues(alpha: 0.06),
        splashColor: PokeBinderColors.red.withValues(alpha: 0.06),
        hoverColor: PokeBinderColors.red.withValues(alpha: 0.05),
      ),
      child: PopupMenuButton<CardSortOption>(
        initialValue: selected,
        onSelected: onChanged,
        offset: const Offset(0, 32),
        color: PokeBinderColors.white,
        elevation: 8,
        shadowColor: PokeBinderColors.ink.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        ),
        constraints: const BoxConstraints(minWidth: 190),
        padding: const EdgeInsets.symmetric(vertical: PokeBinderSpacing.sp2),
        itemBuilder: (context) => [
          for (final option in options)
            PopupMenuItem(
              value: option,
              height: 38,
              padding: const EdgeInsets.symmetric(
                horizontal: PokeBinderSpacing.sp1,
              ),
              child: CardSortMenuRow(option: option, selected: option == selected),
            ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Center(
            child: Container(
              padding: PokeBinderSpacing.chip,
              decoration: BoxDecoration(
                color: PokeBinderColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SORT: ${selected.label.toUpperCase()}',
                      style: PokeBinderText.resultCount),
                  const SizedBox(width: PokeBinderSpacing.sp0),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 15,
                    color: PokeBinderColors.inkSoft,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardSortMenuRow extends StatelessWidget {
  final CardSortOption option;
  final bool selected;

  const CardSortMenuRow({super.key, required this.option, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp2,
        vertical: PokeBinderSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: selected ? PokeBinderColors.red.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(
            option.icon,
            size: 16,
            color: selected ? PokeBinderColors.red : PokeBinderColors.inkSoft,
          ),
          const SizedBox(width: PokeBinderSpacing.sp2),
          Expanded(
            child: Text(
              option.label,
              style: PokeBinderText.pillLabel(selected: selected),
            ),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: PokeBinderSpacing.sp1),
              child: Icon(
                Icons.check_rounded,
                size: 15,
                color: PokeBinderColors.red,
              ),
            ),
        ],
      ),
    );
  }
}

class CardFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const CardFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: PokeBinderSpacing.sp3,
          vertical: PokeBinderSpacing.sp2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? null : PokeBinderColors.cream2,
          gradient: active ? PokeBinderColors.redGradient : null,
          border: active
              ? null
              : Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.06)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: PokeBinderColors.redDeep.withValues(alpha: 0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? PokeBinderColors.white : PokeBinderColors.inkSoft,
            ),
            const SizedBox(width: PokeBinderSpacing.sp1),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: active ? PokeBinderText.chipLabelActive : PokeBinderText.chipLabel,
              child: Text(label),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class TypeChipRow extends StatelessWidget {
  final PokemonCardType? selected;
  final ValueChanged<PokemonCardType?> onChanged;

  const TypeChipRow({super.key, required this.selected, required this.onChanged});

  static const _types = <PokemonCardType?, String>{
    null: 'All',
    PokemonCardType.colorless: 'Colorless',
    PokemonCardType.grass: 'Grass',
    PokemonCardType.fire: 'Fire',
    PokemonCardType.water: 'Water',
    PokemonCardType.lightning: 'Lightning',
    PokemonCardType.fighting: 'Fighting',
    PokemonCardType.psychic: 'Psychic',
    PokemonCardType.darkness: 'Darkness',
    PokemonCardType.metal: 'Metal',
    PokemonCardType.dragon: 'Dragon',
    PokemonCardType.fairy: 'Fairy',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kFilterChipRowHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in _types.entries)
            Padding(
              padding: const EdgeInsets.only(right: PokeBinderSpacing.sp1),
              child: CardFilterChip(
                label: entry.value,
                icon: _typeIcon(entry.key),
                active: selected == entry.key,
                onTap: () => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }

  static IconData _typeIcon(PokemonCardType? type) {
    if (type == null) return Icons.apps_rounded;
    return type.typeIcon;
  }
}

IconData elementIcon(String elementKey) {
  switch (elementKey) {
    case 'grass':
      return Icons.eco_rounded;
    case 'fire':
      return Icons.local_fire_department_rounded;
    case 'water':
      return Icons.water_drop_rounded;
    case 'lightning':
      return Icons.bolt_rounded;
    case 'fighting':
      return Icons.sports_mma_rounded;
    case 'psychic':
      return Icons.psychology_rounded;
    case 'darkness':
      return Icons.dark_mode_rounded;
    case 'metal':
      return Icons.settings_rounded;
    case 'fairy':
      return Icons.local_florist_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}

IconData trainerSubtypeIcon(String? key) {
  switch (key) {
    case 'Item':
      return Icons.inventory_2_outlined;
    case 'Supporter':
      return Icons.person_outline_rounded;
    case 'Stadium':
      return Icons.stadium_outlined;
    default:
      return Icons.apps_rounded;
  }
}

IconData energySubtypeIcon(String? key) {
  switch (key) {
    case 'Basic':
      return Icons.crop_square_rounded;
    case 'Special':
      return Icons.flare_rounded;
    case null:
      return Icons.apps_rounded;
    default:
      return elementIcon(key);
  }
}

const kTrainerSubtypeChips = <String?, String>{
  null: 'All',
  'Item': 'Items',
  'Supporter': 'Supporters',
  'Stadium': 'Stadiums',
};

const kEnergySubtypeChips = <String?, String>{
  null: 'All',
  'Basic': 'Basic',
  'Special': 'Special',
  'grass': 'Grass',
  'fire': 'Fire',
  'water': 'Water',
  'lightning': 'Lightning',
  'fighting': 'Fighting',
  'psychic': 'Psychic',
  'darkness': 'Darkness',
  'metal': 'Metal',
  'fairy': 'Fairy',
};

const kRarityTiers = <String>[
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

const kRarityTierLabels = <String, String>{
  'Common': 'Common',
  'Uncommon': 'Uncommon',
  'Rare': 'Rare',
  'Double Rare': 'Double Rare',
  'Illustration Rare': 'Illustration Rare',
  'Special Illustration Rare': 'Special Illustration Rare',
  'Hyper Rare': 'Hyper Rare',
  'Promo': 'Promo',
  'Other/Additional Rarities': 'Other/Additional Rarities',
};

String rarityTierOf(String rawRarity) {
  return kRarityTierLabels.containsKey(rawRarity)
      ? rawRarity
      : 'Other/Additional Rarities';
}

const kConditionOrder = <String>['NM', 'LP', 'MP', 'DMG'];

const kConditionLabels = <String, String>{
  'NM': 'Near Mint',
  'LP': 'Lightly Played',
  'MP': 'Moderately Played',
  'DMG': 'Damaged',
};

bool matchesEnergyFilter(PokemonCardData card, String? filterKey) {
  if (filterKey == null) return true;
  if (filterKey == 'Basic' || filterKey == 'Special') {
    return card.subtype == filterKey;
  }
  return card.type.name == filterKey;
}

List<String> setOptionsIn(List<PokemonCardData> allCards) {
  final seen = <String>{};
  final ordered = <String>[];
  for (final card in allCards) {
    if (seen.add(card.setName)) ordered.add(card.setName);
  }
  return ordered;
}

int cardNumberValue(PokemonCardData card) {
  final leading = card.cardNumber.split('/').first;
  return int.tryParse(leading.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

class CardSortResult {
  final List<PokemonCardData> cards;
  final Widget? subOptionRow;

  const CardSortResult({required this.cards, this.subOptionRow});
}

CardSortResult applyCardSort({
  required List<PokemonCardData> cards,
  required String search,
  required CardSortOption sortOption,
  required PokemonCardType? typeFilter,
  required String? subtypeFilter,
  required String? setFilter,
  required String? rarityFilter,
  required String? conditionFilter,
  required TimeSortDirection timeDirection,
  required ValueChanged<PokemonCardType?> onTypeFilterChanged,
  required ValueChanged<String?> onSubtypeFilterChanged,
  required ValueChanged<String?> onSetFilterChanged,
  required ValueChanged<String?> onRarityFilterChanged,
  required ValueChanged<String?> onConditionFilterChanged,
  required ValueChanged<TimeSortDirection> onTimeDirectionChanged,
}) {
  final bySupertype = switch (sortOption) {
    CardSortOption.pokemon =>
      cards.where((c) => c.supertype == CardSupertype.pokemon),
    CardSortOption.trainer =>
      cards.where((c) => c.supertype == CardSupertype.trainer),
    CardSortOption.energy =>
      cards.where((c) => c.supertype == CardSupertype.energy),
    CardSortOption.time ||
    CardSortOption.alphabetical ||
    CardSortOption.set ||
    CardSortOption.cardNumber ||
    CardSortOption.rarity ||
    CardSortOption.price ||
    CardSortOption.condition ||
    CardSortOption.quantity =>
      cards,
  };

  final byChip = switch (sortOption) {
    CardSortOption.pokemon =>
      bySupertype.where((c) => typeFilter == null || c.type == typeFilter),
    CardSortOption.trainer =>
      bySupertype.where(
          (c) => subtypeFilter == null || c.subtype == subtypeFilter),
    CardSortOption.energy =>
      bySupertype.where((c) => matchesEnergyFilter(c, subtypeFilter)),
    CardSortOption.set =>
      bySupertype.where((c) => setFilter == null || c.setName == setFilter),
    CardSortOption.rarity =>
      bySupertype.where((c) =>
          rarityFilter == null || rarityTierOf(c.rarity) == rarityFilter),
    CardSortOption.condition =>
      bySupertype.where(
          (c) => conditionFilter == null || c.condition == conditionFilter),
    CardSortOption.time ||
    CardSortOption.alphabetical ||
    CardSortOption.cardNumber ||
    CardSortOption.price ||
    CardSortOption.quantity =>
      bySupertype,
  };

  final filtered = byChip
      .where((c) => c.name.toLowerCase().contains(search.toLowerCase()))
      .toList();

  switch (sortOption) {
    case CardSortOption.time:
      filtered.sort((a, b) => timeDirection == TimeSortDirection.newest
          ? b.dateAdded.compareTo(a.dateAdded)
          : a.dateAdded.compareTo(b.dateAdded));
      break;
    case CardSortOption.alphabetical:
      filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case CardSortOption.set:
      filtered.sort((a, b) {
        final bySet = a.setName.compareTo(b.setName);
        return bySet != 0
            ? bySet
            : cardNumberValue(a).compareTo(cardNumberValue(b));
      });
      break;
    case CardSortOption.cardNumber:
      filtered.sort(
          (a, b) => cardNumberValue(a).compareTo(cardNumberValue(b)));
      break;
    case CardSortOption.rarity:
      int rankOf(PokemonCardData c) => kRarityTiers.indexOf(rarityTierOf(c.rarity));

      filtered.sort((a, b) {
        final byRank = rankOf(a).compareTo(rankOf(b));
        return byRank != 0
            ? byRank
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      break;
    case CardSortOption.price:
      filtered.sort((a, b) {
        final byValue = b.estimatedValue.compareTo(a.estimatedValue);
        return byValue != 0
            ? byValue
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      break;
    case CardSortOption.condition:
      int conditionRankOf(PokemonCardData c) =>
          kConditionOrder.indexOf(c.condition);

      filtered.sort((a, b) {
        final byRank = conditionRankOf(a).compareTo(conditionRankOf(b));
        return byRank != 0
            ? byRank
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      break;
    case CardSortOption.quantity:
      filtered.sort((a, b) => b.quantityOwned.compareTo(a.quantityOwned));
      break;
    case CardSortOption.pokemon:
      if (typeFilter == null) {
        filtered.sort((a, b) {
          final byType = a.type.index.compareTo(b.type.index);
          return byType != 0
              ? byType
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      }
      break;
    case CardSortOption.trainer:
    case CardSortOption.energy:
      break;
  }

  Widget? subOptionRow;
  switch (sortOption) {
    case CardSortOption.time:
    case CardSortOption.pokemon:
    case CardSortOption.trainer:
    case CardSortOption.energy:
    case CardSortOption.rarity:
      subOptionRow = sortSubOptionRow(
        sortOption: sortOption,
        typeFilter: typeFilter,
        subtypeFilter: subtypeFilter,
        rarityFilter: rarityFilter,
        timeDirection: timeDirection,
        onTypeFilterChanged: onTypeFilterChanged,
        onSubtypeFilterChanged: onSubtypeFilterChanged,
        onRarityFilterChanged: onRarityFilterChanged,
        onTimeDirectionChanged: onTimeDirectionChanged,
      );
      break;
    case CardSortOption.set:
      final setOptions = <String?, String>{
        null: 'All',
        for (final setName in setOptionsIn(cards)) setName: setName,
      };
      subOptionRow = FilterChipRow(
        options: setOptions,
        selected: setFilter,
        iconFor: (key) =>
            key == null ? Icons.apps_rounded : Icons.collections_bookmark_outlined,
        onChanged: onSetFilterChanged,
      );
      break;
    case CardSortOption.condition:
      final conditionOptions = <String?, String>{
        null: 'All',
        for (final code in kConditionOrder) code: kConditionLabels[code]!,
      };
      subOptionRow = FilterChipRow(
        options: conditionOptions,
        selected: conditionFilter,
        iconFor: (key) => key == null ? Icons.apps_rounded : conditionIconFor(key),
        onChanged: onConditionFilterChanged,
      );
      break;
    case CardSortOption.alphabetical:
    case CardSortOption.cardNumber:
    case CardSortOption.price:
    case CardSortOption.quantity:
      subOptionRow = null;
  }

  return CardSortResult(cards: filtered, subOptionRow: subOptionRow);
}

Widget? sortSubOptionRow({
  required CardSortOption sortOption,
  required PokemonCardType? typeFilter,
  required String? subtypeFilter,
  required String? rarityFilter,
  required TimeSortDirection timeDirection,
  required ValueChanged<PokemonCardType?> onTypeFilterChanged,
  required ValueChanged<String?> onSubtypeFilterChanged,
  required ValueChanged<String?> onRarityFilterChanged,
  required ValueChanged<TimeSortDirection> onTimeDirectionChanged,
}) {
  switch (sortOption) {
    case CardSortOption.time:
      return FilterChipRow(
        options: const {'newest': 'Newest', 'oldest': 'Oldest'},
        selected: timeDirection.name,
        iconFor: (key) => key == 'oldest'
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        onChanged: (value) => onTimeDirectionChanged(
          value == 'oldest' ? TimeSortDirection.oldest : TimeSortDirection.newest,
        ),
      );
    case CardSortOption.pokemon:
      return TypeChipRow(selected: typeFilter, onChanged: onTypeFilterChanged);
    case CardSortOption.trainer:
      return FilterChipRow(
        options: kTrainerSubtypeChips,
        selected: subtypeFilter,
        iconFor: trainerSubtypeIcon,
        onChanged: onSubtypeFilterChanged,
      );
    case CardSortOption.energy:
      return FilterChipRow(
        options: kEnergySubtypeChips,
        selected: subtypeFilter,
        iconFor: energySubtypeIcon,
        onChanged: onSubtypeFilterChanged,
      );
    case CardSortOption.rarity:
      return FilterChipRow(
        options: <String?, String>{
          null: 'All',
          for (final tier in kRarityTiers) tier: kRarityTierLabels[tier]!,
        },
        selected: rarityFilter,
        iconFor: (key) => key == null ? Icons.apps_rounded : rarityIconFor(key),
        onChanged: onRarityFilterChanged,
      );
    case CardSortOption.alphabetical:
    case CardSortOption.set:
    case CardSortOption.cardNumber:
    case CardSortOption.price:
    case CardSortOption.condition:
    case CardSortOption.quantity:
      return null;
  }
}

const kCatalogSortOptions = <CardSortOption>[
  CardSortOption.alphabetical,
  CardSortOption.time,
  CardSortOption.pokemon,
  CardSortOption.trainer,
  CardSortOption.energy,
  CardSortOption.cardNumber,
  CardSortOption.rarity,
  CardSortOption.price,
];

class CatalogSortResult {
  final List<CatalogCard> cards;
  final Widget? subOptionRow;

  const CatalogSortResult({required this.cards, this.subOptionRow});
}

CatalogSortResult applyCatalogSort({
  required List<CatalogCard> cards,
  required CardSortOption sortOption,
  required PokemonCardType? typeFilter,
  required String? subtypeFilter,
  required String? rarityFilter,
  required TimeSortDirection timeDirection,
  required DateTime? Function(CatalogCard card) releaseDateOf,
  required ValueChanged<PokemonCardType?> onTypeFilterChanged,
  required ValueChanged<String?> onSubtypeFilterChanged,
  required ValueChanged<String?> onRarityFilterChanged,
  required ValueChanged<TimeSortDirection> onTimeDirectionChanged,
}) {
  bool keep(CatalogCard c) => switch (sortOption) {
        CardSortOption.pokemon => c.supertype == CardSupertype.pokemon &&
            (typeFilter == null || c.type == typeFilter),
        CardSortOption.trainer => c.supertype == CardSupertype.trainer &&
            (subtypeFilter == null || c.subtype == subtypeFilter),
        CardSortOption.energy => c.supertype == CardSupertype.energy &&
            (subtypeFilter == null ||
                c.subtype == subtypeFilter ||
                c.type.name == subtypeFilter),
        CardSortOption.rarity =>
          rarityFilter == null || rarityTierOf(c.rarity) == rarityFilter,
        _ => true,
      };
  final filtered = cards.where(keep).toList();

  int inSetOrder(CatalogCard a, CatalogCard b) {
    final bySet = a.setId.compareTo(b.setId);
    return bySet != 0 ? bySet : compareByPrintedNumber(a, b);
  }

  int byName(CatalogCard a, CatalogCard b) {
    final r = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return r != 0 ? r : inSetOrder(a, b);
  }

  switch (sortOption) {
    case CardSortOption.time:
      filtered.sort((a, b) {
        final da = releaseDateOf(a);
        final db = releaseDateOf(b);
        final byDate = da == null || db == null ? 0 : da.compareTo(db);
        if (byDate != 0) {
          return timeDirection == TimeSortDirection.newest ? -byDate : byDate;
        }
        return inSetOrder(a, b);
      });
    case CardSortOption.cardNumber:
      filtered.sort((a, b) {
        final byNumber = compareByPrintedNumber(a, b);
        return byNumber != 0 ? byNumber : a.setId.compareTo(b.setId);
      });
    case CardSortOption.rarity:
      int rankOf(CatalogCard c) => kRarityTiers.indexOf(rarityTierOf(c.rarity));

      filtered.sort((a, b) {
        final byRank = rankOf(a).compareTo(rankOf(b));
        return byRank != 0 ? byRank : byName(a, b);
      });
    case CardSortOption.price:
      filtered.sort((a, b) {
        final byPrice = (b.marketPricePhp ?? -1).compareTo(a.marketPricePhp ?? -1);
        return byPrice != 0 ? byPrice : byName(a, b);
      });
    case CardSortOption.pokemon:
      filtered.sort((a, b) {
        final byType =
            typeFilter == null ? a.type.index.compareTo(b.type.index) : 0;
        return byType != 0 ? byType : byName(a, b);
      });
    default:
      filtered.sort(byName);
  }

  return CatalogSortResult(
    cards: filtered,
    subOptionRow: sortSubOptionRow(
      sortOption: sortOption,
      typeFilter: typeFilter,
      subtypeFilter: subtypeFilter,
      rarityFilter: rarityFilter,
      timeDirection: timeDirection,
      onTypeFilterChanged: onTypeFilterChanged,
      onSubtypeFilterChanged: onSubtypeFilterChanged,
      onRarityFilterChanged: onRarityFilterChanged,
      onTimeDirectionChanged: onTimeDirectionChanged,
    ),
  );
}

class FilterChipRow extends StatelessWidget {
  final Map<String?, String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final IconData Function(String? key) iconFor;

  const FilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.iconFor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kFilterChipRowHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in options.entries)
            Padding(
              padding: const EdgeInsets.only(right: PokeBinderSpacing.sp1),
              child: CardFilterChip(
                label: entry.value,
                icon: iconFor(entry.key),
                active: selected == entry.key,
                onTap: () => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}
