import 'package:flutter/material.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';

/// The set of ways a card list can be sorted across the app. Shared by the
/// All Cards screen and the deck-builder's Add Cards screen so both offer
/// an identical sorting experience.
enum CardSortOption {
  time,
  alphabetical,
  pokemon,
  trainer,
  energy,
  set,
  cardNumber,
  rarity,
  condition,
  quantity,
}

extension CardSortOptionLabel on CardSortOption {
  String get label {
    switch (this) {
      case CardSortOption.time:
        return 'Time';
      case CardSortOption.alphabetical:
        return 'Alphabetical';
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
      case CardSortOption.condition:
        return 'Condition';
      case CardSortOption.quantity:
        return 'Quantity';
    }
  }

  IconData get icon {
    switch (this) {
      case CardSortOption.time:
        return Icons.schedule_rounded;
      case CardSortOption.alphabetical:
        return Icons.sort_by_alpha_rounded;
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

/// The sort dropdown used to choose a [CardSortOption]. Renders as a pill
/// button that opens a scrollable popup menu listing every option.
class CardSortSelector extends StatelessWidget {
  final CardSortOption selected;
  final ValueChanged<CardSortOption> onChanged;

  const CardSortSelector({
    super.key,
    required this.selected,
    required this.onChanged,
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemBuilder: (context) => [
          for (final option in CardSortOption.values)
            PopupMenuItem(
              value: option,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: CardSortMenuRow(option: option, selected: option == selected),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              const SizedBox(width: 1),
              const Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: PokeBinderColors.inkSoft,
              ),
            ],
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
        vertical: 8,
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
              style: PokeBinderText.chakraPetch(TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected
                    ? PokeBinderColors.redDeep
                    : PokeBinderColors.ink,
              )),
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

/// A small horizontally-scrolling pill used within [TypeChipRow] and
/// [FilterChipRow].
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
            const SizedBox(width: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: active ? PokeBinderText.chipLabelActive : PokeBinderText.chipLabel,
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally-scrolling row of Pokémon energy-type chips, used as the
/// sub-filter row when sorting by [CardSortOption.pokemon].
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
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in _types.entries)
            Padding(
              padding: const EdgeInsets.only(right: 6),
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

/// Rarity tiers, coarsest-to-rarest, used by [CardSortOption.rarity].
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

/// The result of [applyCardSort]: the filtered/sorted card list, plus the
/// contextual sub-filter row (if any) that belongs under the sort dropdown
/// for the chosen [CardSortOption].
class CardSortResult {
  final List<PokemonCardData> cards;
  final Widget? subOptionRow;

  const CardSortResult({required this.cards, this.subOptionRow});
}

/// The single shared filter + sort algorithm used by every screen that
/// lists cards with a [CardSortSelector]. Keeping this logic in one place
/// guarantees the sorting options and interaction stay identical wherever
/// it's used.
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
      subOptionRow = FilterChipRow(
        options: const {'newest': 'Newest', 'oldest': 'Oldest'},
        selected: timeDirection.name,
        iconFor: (key) => key == 'oldest'
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        onChanged: (value) => onTimeDirectionChanged(
          value == 'oldest' ? TimeSortDirection.oldest : TimeSortDirection.newest,
        ),
      );
      break;
    case CardSortOption.pokemon:
      subOptionRow = TypeChipRow(selected: typeFilter, onChanged: onTypeFilterChanged);
      break;
    case CardSortOption.trainer:
      subOptionRow = FilterChipRow(
        options: kTrainerSubtypeChips,
        selected: subtypeFilter,
        iconFor: trainerSubtypeIcon,
        onChanged: onSubtypeFilterChanged,
      );
      break;
    case CardSortOption.energy:
      subOptionRow = FilterChipRow(
        options: kEnergySubtypeChips,
        selected: subtypeFilter,
        iconFor: energySubtypeIcon,
        onChanged: onSubtypeFilterChanged,
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
    case CardSortOption.rarity:
      final rarityOptions = <String?, String>{
        null: 'All',
        for (final tier in kRarityTiers) tier: kRarityTierLabels[tier]!,
      };
      subOptionRow = FilterChipRow(
        options: rarityOptions,
        selected: rarityFilter,
        iconFor: (key) => key == null ? Icons.apps_rounded : rarityIconFor(key),
        onChanged: onRarityFilterChanged,
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
    case CardSortOption.quantity:
      subOptionRow = null;
  }

  return CardSortResult(cards: filtered, subOptionRow: subOptionRow);
}

/// A generic horizontally-scrolling row of chips keyed by an arbitrary
/// string value, used as the sub-filter row for trainer/energy subtypes,
/// sets, rarity tiers, and conditions.
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
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in options.entries)
            Padding(
              padding: const EdgeInsets.only(right: 6),
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
