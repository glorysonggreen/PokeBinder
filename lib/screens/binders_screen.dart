import 'package:flutter/material.dart';

import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/pokebinder_controls.dart';
import 'binder_form_screen.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

/// How the All Cards tab orders/groups the collection. Time and
/// Alphabetical (plus Card Number/Rarity/Quantity) span every supertype;
/// Pokémon/Trainer/Energy additionally restrict the list to that supertype
/// and swap the chip row beneath the search bar to that supertype's own
/// subcategories. Set and Rarity swap the chip row to the sets/rarities
/// actually present in the collection.
enum CardSortOption {
  time,
  alphabetical,
  pokemon,
  trainer,
  energy,
  set,
  cardNumber,
  rarity,
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
      case CardSortOption.quantity:
        return 'Quantity';
    }
  }
}

/// Sub-option for [CardSortOption.time]: which end of the timeline the
/// list starts from.
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

class BindersScreen extends StatefulWidget {
  const BindersScreen({super.key});

  @override
  State<BindersScreen> createState() => _BindersScreenState();
}

class _BindersScreenState extends State<BindersScreen> {
  final List<BinderData> _binders = BinderData.sampleBinders;

  /// Trainer/Energy sample cards start out unassigned since the sample
  /// binders (Kanto Starters, Rare Holos, Trade Bait) are Pokémon-only.
  final List<PokemonCardData> _unassignedCards = PokemonCardData.library
      .where((c) => c.supertype != CardSupertype.pokemon)
      .toList();

  int _tabIndex = 0; // 0 = Binders, 1 = All Cards

  late BinderData _selectedBinder = _binders.first;
  int _pageIndex = 0;
  bool _showingUnassigned = false;

  String _binderSearch = '';
  String _cardSearch = '';
  CardSortOption _sortOption = CardSortOption.time;
  PokemonCardType? _typeFilter;
  String? _subtypeFilter;
  String? _setFilter;
  String? _rarityFilter;
  TimeSortDirection _timeDirection = TimeSortDirection.newest;

  /// Every card across every binder/page plus the unassigned bucket,
  /// flattened for the All Cards tab. The binders and `_unassignedCards`
  /// are the single source of truth — this is just a view over them.
  List<PokemonCardData> get _allCards => [
        for (final binder in _binders)
          for (final page in binder.pages) ...page,
        ..._unassignedCards,
      ];

  void _openCard(PokemonCardData card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardDetailsScreen(
          card: card,
          binders: _binders,
          onSave: _handleCardSaved,
        ),
      ),
    );
  }

  void _selectBinder(BinderData binder) {
    setState(() {
      _selectedBinder = binder;
      _pageIndex = 0;
      _showingUnassigned = false;
    });
  }

  void _selectUnassigned() {
    setState(() => _showingUnassigned = true);
  }

  Future<void> _openNewBinder() async {
    final result = await Navigator.of(context).push<BinderFormResult>(
      MaterialPageRoute(builder: (_) => const BinderFormScreen()),
    );
    if (result?.binder == null) return;

    setState(() {
      _binders.add(result!.binder!);
      _selectedBinder = result.binder!;
      _pageIndex = 0;
      _showingUnassigned = false;
    });
  }

  Future<void> _openEditBinder() async {
    final result = await Navigator.of(context).push<BinderFormResult>(
      MaterialPageRoute(
        builder: (_) => BinderFormScreen(existingBinder: _selectedBinder),
      ),
    );
    if (result == null) return;

    if (result.deleted) {
      if (_binders.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You need at least one binder.")),
        );
        return;
      }
      setState(() {
        // Cards in the deleted binder move to Unassigned rather than
        // disappearing.
        final deleted = _binders.firstWhere((b) => b.id == _selectedBinder.id);
        for (final page in deleted.pages) {
          for (final card in page) {
            _unassignedCards.add(card.copyWith(binderName: 'Unassigned', page: 0));
          }
        }
        _binders.removeWhere((b) => b.id == _selectedBinder.id);
        _selectedBinder = _binders.first;
        _pageIndex = 0;
      });
      return;
    }

    final updated = result.binder!;
    setState(() {
      final index = _binders.indexWhere((b) => b.id == updated.id);
      if (index != -1) _binders[index] = updated;
      _selectedBinder = updated;
      if (_pageIndex >= updated.pageCount) {
        _pageIndex = updated.pageCount - 1;
      }
    });
  }

  Future<void> _openAddCard() async {
    final result = await Navigator.of(context).push<CardFormResult>(
      MaterialPageRoute(
        builder: (_) => CardFormScreen(
          binders: _binders,
          defaultBinderId:
              _showingUnassigned ? kUnassignedBinderId : _selectedBinder.id,
          defaultPageNumber: _showingUnassigned ? 1 : _pageIndex + 1,
        ),
      ),
    );
    if (result == null || result.deleted) return;
    setState(
      () => _insertCard(result.card!, result.binderId!, result.pageIndex!),
    );
  }

  void _handleCardSaved(PokemonCardData oldCard, CardFormResult result) {
    setState(() {
      _removeCardById(oldCard.id);
      if (!result.deleted) {
        _insertCard(result.card!, result.binderId!, result.pageIndex!);
      }
    });
  }

  /// Removes any card with [id] from wherever it currently sits (a binder
  /// page or the unassigned bucket). No-op if it isn't found.
  void _removeCardById(String id) {
    if (_unassignedCards.any((c) => c.id == id)) {
      _unassignedCards.removeWhere((c) => c.id == id);
      return;
    }
    for (var i = 0; i < _binders.length; i++) {
      final pages = _binders[i].pages;
      for (var p = 0; p < pages.length; p++) {
        if (pages[p].any((c) => c.id == id)) {
          final newPages = [
            for (final page in pages) [...page],
          ];
          newPages[p].removeWhere((c) => c.id == id);
          _binders[i] = _binders[i].copyWith(pages: newPages);
          return;
        }
      }
    }
  }

  /// Inserts [card] into the given binder's page (padding with empty pages
  /// if [pageIndex] is beyond the binder's current page count), or into the
  /// unassigned bucket if [binderId] is [kUnassignedBinderId].
  void _insertCard(PokemonCardData card, String binderId, int pageIndex) {
    if (binderId == kUnassignedBinderId) {
      _unassignedCards.add(card);
      return;
    }

    final index = _binders.indexWhere((b) => b.id == binderId);
    if (index == -1) return;

    final binder = _binders[index];
    final newPages = [
      for (final page in binder.pages) [...page],
      for (var i = binder.pageCount; i <= pageIndex; i++) <PokemonCardData>[],
    ];
    newPages[pageIndex].add(card);

    final updated = binder.copyWith(pages: newPages);
    _binders[index] = updated;
    if (_selectedBinder.id == binderId) {
      _selectedBinder = updated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBinders = _binders
        .where((b) => b.name.toLowerCase().contains(_binderSearch.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp4,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COLLECTION', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp3),
              _TopTabBar(
                index: _tabIndex,
                labels: const ['Binders', 'All Cards'],
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              Expanded(
                child: _tabIndex == 0
                    ? _BindersTab(
                        binders: filteredBinders,
                        selectedBinder: _selectedBinder,
                        pageIndex: _pageIndex,
                        unassignedCards: _unassignedCards,
                        showingUnassigned: _showingUnassigned,
                        onSearchChanged: (v) =>
                            setState(() => _binderSearch = v),
                        onSelectBinder: _selectBinder,
                        onSelectUnassigned: _selectUnassigned,
                        onPrevPage: _pageIndex > 0
                            ? () => setState(() => _pageIndex--)
                            : null,
                        onNextPage:
                            _pageIndex < _selectedBinder.pageCount - 1
                                ? () => setState(() => _pageIndex++)
                                : null,
                        onCardTap: _openCard,
                        onNewBinder: _openNewBinder,
                        onEditBinder: _openEditBinder,
                        onAddCard: _openAddCard,
                      )
                    : _AllCardsTab(
                        cards: _allCards,
                        search: _cardSearch,
                        sortOption: _sortOption,
                        typeFilter: _typeFilter,
                        subtypeFilter: _subtypeFilter,
                        setFilter: _setFilter,
                        rarityFilter: _rarityFilter,
                        timeDirection: _timeDirection,
                        onSearchChanged: (v) =>
                            setState(() => _cardSearch = v),
                        onSortChanged: (option) => setState(() {
                          _sortOption = option;
                          // A stale chip selection from the previous
                          // category wouldn't make sense in the new one.
                          _typeFilter = null;
                          _subtypeFilter = null;
                          _setFilter = null;
                          _rarityFilter = null;
                          _timeDirection = TimeSortDirection.newest;
                        }),
                        onTypeFilterChanged: (t) =>
                            setState(() => _typeFilter = t),
                        onSubtypeFilterChanged: (s) =>
                            setState(() => _subtypeFilter = s),
                        onSetFilterChanged: (s) =>
                            setState(() => _setFilter = s),
                        onRarityFilterChanged: (r) =>
                            setState(() => _rarityFilter = r),
                        onTimeDirectionChanged: (d) =>
                            setState(() => _timeDirection = d),
                        onCardTap: _openCard,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches the mockup's `.tabbar-top`.
class _TopTabBar extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _TopTabBar({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: PokeBinderColors.ink.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 7),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == index
                            ? PokeBinderColors.red
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: i == index
                        ? PokeBinderText.tabLabelActive
                        : PokeBinderText.tabLabelInactive,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The "Binders" sub-tab: search, binder list, and the selected binder's
/// current page as a 3-column grid.
class _BindersTab extends StatelessWidget {
  final List<BinderData> binders;
  final BinderData selectedBinder;
  final int pageIndex;
  final List<PokemonCardData> unassignedCards;
  final bool showingUnassigned;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<BinderData> onSelectBinder;
  final VoidCallback onSelectUnassigned;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;
  final ValueChanged<PokemonCardData> onCardTap;
  final VoidCallback onNewBinder;
  final VoidCallback onEditBinder;
  final VoidCallback onAddCard;

  const _BindersTab({
    required this.binders,
    required this.selectedBinder,
    required this.pageIndex,
    required this.unassignedCards,
    required this.showingUnassigned,
    required this.onSearchChanged,
    required this.onSelectBinder,
    required this.onSelectUnassigned,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onCardTap,
    required this.onNewBinder,
    required this.onEditBinder,
    required this.onAddCard,
  });

  @override
  Widget build(BuildContext context) {
    final currentPageCards = showingUnassigned
        ? unassignedCards
        : (selectedBinder.pages.isEmpty
            ? const <PokemonCardData>[]
            : selectedBinder.pages[pageIndex]);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchBar(
            hint: 'Search binders…',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          PillButton(
            label: 'New Binder',
            icon: Icons.add,
            onTap: onNewBinder,
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          _BinderListPanel(
            binders: binders,
            selectedBinder: selectedBinder,
            showingUnassigned: showingUnassigned,
            unassignedCount: unassignedCards.length,
            onSelect: onSelectBinder,
            onSelectUnassigned: onSelectUnassigned,
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showingUnassigned
                    ? 'UNASSIGNED CARDS'
                    : '${selectedBinder.name} — Page ${pageIndex + 1}'
                        .toUpperCase(),
                style: PokeBinderText.sectionLabel,
              ),
              if (!showingUnassigned)
                InkWell(
                  onTap: onEditBinder,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: PokeBinderText.backLink.color,
                      ),
                      const SizedBox(width: 4),
                      Text('Edit', style: PokeBinderText.backLink),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: PokeBinderSpacing.sp2),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 3;
              const crossAxisSpacing = PokeBinderSpacing.sp2;
              final cardWidth = (constraints.maxWidth -
                      crossAxisSpacing * (crossAxisCount - 1)) /
                  crossAxisCount;
              final cardHeight = cardWidth / kPokemonCardImageAspectRatio;

              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: PokeBinderSpacing.sp2,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisExtent: cardHeight + 4 + kCardCaptionHeight,
                ),
                children: [
                  for (final card in currentPageCards)
                    Column(
                      children: [
                        SizedBox(
                          height: cardHeight,
                          child: BinderCardTile(
                            card: card,
                            onTap: () => onCardTap(card),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.name,
                          style: PokeBinderText.cardName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${card.setName} · #${card.cardNumber}',
                          style: PokeBinderText.cardMeta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  Column(
                    children: [
                      SizedBox(
                        height: cardHeight,
                        child: AddCardTile(onTap: onAddCard),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add Card Manually',
                        style: PokeBinderText.cardName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          if (!showingUnassigned)
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: '‹ Prev',
                    ghost: true,
                    enabled: onPrevPage != null,
                    onTap: onPrevPage ?? () {},
                  ),
                ),
                const SizedBox(width: PokeBinderSpacing.sp2),
                Expanded(
                  child: PillButton(
                    label: 'Next ›',
                    ghost: true,
                    enabled: onNextPage != null,
                    onTap: onNextPage ?? () {},
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The "All Cards" sub-tab: search, a sort/category selector, a chip row
/// that adapts to the selected category, and a flat grid of every matching
/// card with its name beneath it.
class _AllCardsTab extends StatelessWidget {
  final List<PokemonCardData> cards;
  final String search;
  final CardSortOption sortOption;
  final PokemonCardType? typeFilter;
  final String? subtypeFilter;
  final String? setFilter;
  final String? rarityFilter;
  final TimeSortDirection timeDirection;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CardSortOption> onSortChanged;
  final ValueChanged<PokemonCardType?> onTypeFilterChanged;
  final ValueChanged<String?> onSubtypeFilterChanged;
  final ValueChanged<String?> onSetFilterChanged;
  final ValueChanged<String?> onRarityFilterChanged;
  final ValueChanged<TimeSortDirection> onTimeDirectionChanged;
  final ValueChanged<PokemonCardData> onCardTap;

  const _AllCardsTab({
    required this.cards,
    required this.search,
    required this.sortOption,
    required this.typeFilter,
    required this.subtypeFilter,
    required this.setFilter,
    required this.rarityFilter,
    required this.timeDirection,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onTypeFilterChanged,
    required this.onSubtypeFilterChanged,
    required this.onSetFilterChanged,
    required this.onRarityFilterChanged,
    required this.onTimeDirectionChanged,
    required this.onCardTap,
  });

  /// The modern Pokémon TCG rarity ladder, in ascending order. The Rarity
  /// scrollbar always shows all of these (even if the collection doesn't
  /// currently have a card in every tier), since this is a fixed
  /// classification rather than something derived from the data.
  static const _rarityTiers = <String>[
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

  /// Buckets a card's raw [PokemonCardData.rarity] string into one of the
  /// [_rarityTiers]. Older/looser rarity labels fold into the closest
  /// modern tier — e.g. "Holo Rare" is a Rare — and anything unrecognized
  /// falls into "Other/Additional Rarities" rather than being dropped.
  static String _rarityTier(String rawRarity) {
    switch (rawRarity) {
      case 'Common':
        return 'Common';
      case 'Uncommon':
        return 'Uncommon';
      case 'Rare':
      case 'Holo Rare':
      case 'Rare Holo':
        return 'Rare';
      case 'Double Rare':
        return 'Double Rare';
      case 'Illustration Rare':
        return 'Illustration Rare';
      case 'Special Illustration Rare':
        return 'Special Illustration Rare';
      case 'Hyper Rare':
        return 'Hyper Rare';
      case 'Promo':
        return 'Promo';
      default:
        return 'Other/Additional Rarities';
    }
  }

  /// A friendlier chip label for each rarity tier.
  static const _rarityTierLabels = <String, String>{
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

  /// Energy cards are filterable by either their elemental [type] (Grass,
  /// Fire, Water, …) or their [subtype] (Basic/Special) — two different
  /// underlying fields collapsed into a single scrollbar selection. Keys
  /// for the elemental options are the [PokemonCardType.name] strings;
  /// 'Basic' and 'Special' are matched against [subtype] instead.
  static bool _matchesEnergyFilter(PokemonCardData card, String? filterKey) {
    if (filterKey == null) return true;
    if (filterKey == 'Basic' || filterKey == 'Special') {
      return card.subtype == filterKey;
    }
    return card.type.name == filterKey;
  }

  List<String> _setOptionsIn(List<PokemonCardData> allCards) {
    final seen = <String>{};
    final ordered = <String>[];
    for (final card in allCards) {
      if (seen.add(card.setName)) ordered.add(card.setName);
    }
    return ordered;
  }

  /// Parses the leading number out of a "4/102"-style card number, for
  /// numeric (rather than lexical) sorting. Falls back to 0 if it can't be
  /// parsed, so odd/blank card numbers sort first rather than crashing.
  static int _cardNumberValue(PokemonCardData card) {
    final leading = card.cardNumber.split('/').first;
    return int.tryParse(leading.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
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
        bySupertype.where((c) => _matchesEnergyFilter(c, subtypeFilter)),
      CardSortOption.set =>
        bySupertype.where((c) => setFilter == null || c.setName == setFilter),
      CardSortOption.rarity =>
        bySupertype.where(
            (c) => rarityFilter == null || _rarityTier(c.rarity) == rarityFilter),
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
              : _cardNumberValue(a).compareTo(_cardNumberValue(b));
        });
        break;
      case CardSortOption.cardNumber:
        filtered.sort(
            (a, b) => _cardNumberValue(a).compareTo(_cardNumberValue(b)));
        break;
      case CardSortOption.rarity:
        int rankOf(PokemonCardData c) => _rarityTiers.indexOf(_rarityTier(c.rarity));

        filtered.sort((a, b) {
          final byRank = rankOf(a).compareTo(rankOf(b));
          return byRank != 0
              ? byRank
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case CardSortOption.quantity:
        filtered.sort((a, b) => b.quantityOwned.compareTo(a.quantityOwned));
        break;
      case CardSortOption.pokemon:
      case CardSortOption.trainer:
      case CardSortOption.energy:
        break;
    }

    // The scrollbar beneath the search bar always reflects only the
    // sub-options relevant to the currently selected sort category.
    Widget? subOptionRow;
    switch (sortOption) {
      case CardSortOption.time:
        subOptionRow = _SubtypeChipRow(
          options: const {'newest': 'Newest', 'oldest': 'Oldest'},
          selected: timeDirection.name,
          onChanged: (value) => onTimeDirectionChanged(
            value == 'oldest' ? TimeSortDirection.oldest : TimeSortDirection.newest,
          ),
        );
        break;
      case CardSortOption.pokemon:
        subOptionRow = _TypeChipRow(selected: typeFilter, onChanged: onTypeFilterChanged);
        break;
      case CardSortOption.trainer:
        subOptionRow = _SubtypeChipRow(
          options: _kTrainerSubtypeChips,
          selected: subtypeFilter,
          onChanged: onSubtypeFilterChanged,
        );
        break;
      case CardSortOption.energy:
        subOptionRow = _SubtypeChipRow(
          options: _kEnergySubtypeChips,
          selected: subtypeFilter,
          onChanged: onSubtypeFilterChanged,
        );
        break;
      case CardSortOption.set:
        final setOptions = <String?, String>{
          null: 'All',
          for (final setName in _setOptionsIn(cards)) setName: setName,
        };
        subOptionRow = _SubtypeChipRow(
          options: setOptions,
          selected: setFilter,
          onChanged: onSetFilterChanged,
        );
        break;
      case CardSortOption.rarity:
        final rarityOptions = <String?, String>{
          null: 'All',
          for (final tier in _rarityTiers) tier: _rarityTierLabels[tier]!,
        };
        subOptionRow = _SubtypeChipRow(
          options: rarityOptions,
          selected: rarityFilter,
          onChanged: onRarityFilterChanged,
        );
        break;
      case CardSortOption.alphabetical:
      case CardSortOption.cardNumber:
      case CardSortOption.quantity:
        // These categories have no meaningful sub-options, so no
        // scrollbar is shown beneath the search bar.
        subOptionRow = null;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchBar(
            hint: 'Search all ${cards.length} cards by name…',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          if (subOptionRow != null) ...[
            subOptionRow,
            const SizedBox(height: PokeBinderSpacing.sp2),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SHOWING ${filtered.length} CARDS',
                style: PokeBinderText.resultCount,
              ),
              _SortSelector(selected: sortOption, onChanged: onSortChanged),
            ],
          ),
          const SizedBox(height: PokeBinderSpacing.sp2),
          if (filtered.isEmpty)
            const _EmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const crossAxisCount = 3;
                const crossAxisSpacing = PokeBinderSpacing.sp2;
                final cardWidth = (constraints.maxWidth -
                        crossAxisSpacing * (crossAxisCount - 1)) /
                    crossAxisCount;
                final cardHeight = cardWidth / kPokemonCardImageAspectRatio;

                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: PokeBinderSpacing.sp3,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisExtent: cardHeight + 4 + kCardCaptionHeight,
                  ),
                  children: [
                    for (final card in filtered)
                      Column(
                        children: [
                          SizedBox(
                            height: cardHeight,
                            child: BinderCardTile(
                              card: card,
                              onTap: () => onCardTap(card),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.name,
                            style: PokeBinderText.cardName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${card.setName} · #${card.cardNumber}',
                            style: PokeBinderText.cardMeta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Matches the mockup's `.search-bar`.
class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: PokeBinderColors.inkSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 11.5, color: PokeBinderColors.ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFFA89C86)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Matches the mockup's `.panel` containing `.list-row`s, plus a trailing
/// "Unassigned" row for cards with no binder.
class _BinderListPanel extends StatelessWidget {
  final List<BinderData> binders;
  final BinderData selectedBinder;
  final bool showingUnassigned;
  final int unassignedCount;
  final ValueChanged<BinderData> onSelect;
  final VoidCallback onSelectUnassigned;

  const _BinderListPanel({
    required this.binders,
    required this.selectedBinder,
    required this.showingUnassigned,
    required this.unassignedCount,
    required this.onSelect,
    required this.onSelectUnassigned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: PokeBinderColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < binders.length; i++)
            _BinderListRow(
              icon: Icons.menu_book_rounded,
              title: binders[i].name,
              subtitle:
                  '${binders[i].pageCount} ${binders[i].pageCount == 1 ? 'page' : 'pages'} · '
                  '${binders[i].cardCount} ${binders[i].cardCount == 1 ? 'card' : 'cards'}',
              selected: !showingUnassigned && binders[i].id == selectedBinder.id,
              showDivider: true,
              onTap: () => onSelect(binders[i]),
            ),
          _BinderListRow(
            icon: Icons.inbox_rounded,
            title: 'Unassigned',
            subtitle: '$unassignedCount ${unassignedCount == 1 ? 'card' : 'cards'} · no binder',
            selected: showingUnassigned,
            showDivider: false,
            muted: true,
            onTap: onSelectUnassigned,
          ),
        ],
      ),
    );
  }
}

/// A single row in the binder list — used for both real binders and the
/// trailing "Unassigned" bucket ([muted] swaps the leading icon to the
/// neutral inbox styling used for that row).
class _BinderListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool showDivider;
  final bool muted;
  final VoidCallback onTap;

  const _BinderListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.showDivider,
    this.muted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: selected ? PokeBinderColors.red.withValues(alpha: 0.07) : null,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: PokeBinderColors.ink.withValues(alpha: 0.07),
                ),
              )
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3,
                height: 30,
                margin: const EdgeInsets.only(right: 9),
                decoration: BoxDecoration(
                  color: selected ? PokeBinderColors.red : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: muted ? null : PokeBinderColors.redGradient,
                  color: muted ? PokeBinderColors.cream2 : null,
                  border: muted
                      ? Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.12))
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: muted ? PokeBinderColors.inkSoft : PokeBinderColors.white,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PokeBinderText.listRowTitle.copyWith(
                        fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                        color: selected ? PokeBinderColors.redDeep : PokeBinderColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: PokeBinderText.listRowSubtitle),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: selected
                    ? PokeBinderColors.red.withValues(alpha: 0.7)
                    : PokeBinderColors.inkSoft.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches the mockup's `.chip-row` / `.chip` type filters.
class _TypeChipRow extends StatelessWidget {
  final PokemonCardType? selected;
  final ValueChanged<PokemonCardType?> onChanged;

  const _TypeChipRow({required this.selected, required this.onChanged});

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
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in _types.entries)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _Chip(
                label: entry.value,
                active: selected == entry.key,
                onTap: () => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? null : PokeBinderColors.cream2,
          gradient: active ? PokeBinderColors.redGradient : null,
        ),
        child: Text(
          label,
          style: active ? PokeBinderText.chipLabelActive : PokeBinderText.chipLabel,
        ),
      ),
    );
  }
}

/// Chip options shown when Sort is set to Trainer or Energy, replacing the
/// elemental-type chips (which don't apply to those supertypes).
const _kTrainerSubtypeChips = <String?, String>{
  null: 'All',
  'Item': 'Items',
  'Supporter': 'Supporters',
  'Stadium': 'Stadiums',
};

/// The subtype value stored on energy cards is 'Basic' (matching the TCG's
/// own terminology). Energy's scrollbar mixes two different fields: the
/// elemental options below filter by [PokemonCardData.type] (keyed by the
/// enum's [PokemonCardType.name]), while 'Basic'/'Special' filter by
/// [PokemonCardData.subtype] — see [_AllCardsTab._matchesEnergyFilter].
const _kEnergySubtypeChips = <String?, String>{
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

/// A string-keyed equivalent of [_TypeChipRow], for the Trainer/Energy
/// subtype chips.
class _SubtypeChipRow extends StatelessWidget {
  final Map<String?, String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _SubtypeChipRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in options.entries)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _Chip(
                label: entry.value,
                active: selected == entry.key,
                onTap: () => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

/// The "SORT: RECENT ▾" control, matching the mockup's `.result-count`
/// styling but tappable, opening a menu of every [CardSortOption].
class _SortSelector extends StatelessWidget {
  final CardSortOption selected;
  final ValueChanged<CardSortOption> onChanged;

  const _SortSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CardSortOption>(
      initialValue: selected,
      onSelected: onChanged,
      offset: const Offset(0, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        for (final option in CardSortOption.values)
          PopupMenuItem(
            value: option,
            height: 36,
            child: Text(
              option.label,
              style: option == selected
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SORT: ${selected.label.toUpperCase()}',
              style: PokeBinderText.resultCount),
          const Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: PokeBinderColors.inkSoft,
          ),
        ],
      ),
    );
  }
}

/// Matches the mockup's `.empty-state`.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 26),
      child: Center(
        child: Column(
          children: [
            Text('🔍', style: TextStyle(fontSize: 22)),
            SizedBox(height: 6),
            Text(
              'No cards match your search.',
              style: PokeBinderText.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}