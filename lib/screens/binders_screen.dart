import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/pokebinder_controls.dart';
import 'binder_form_screen.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

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

enum BinderSortOption { name, recent, cardCount }

extension BinderSortOptionLabel on BinderSortOption {
  String get label {
    switch (this) {
      case BinderSortOption.name:
        return 'Alphabetically';
      case BinderSortOption.recent:
        return 'Recently added';
      case BinderSortOption.cardCount:
        return 'Most cards';
    }
  }

  IconData get icon {
    switch (this) {
      case BinderSortOption.name:
        return Icons.sort_by_alpha_rounded;
      case BinderSortOption.recent:
        return Icons.schedule_rounded;
      case BinderSortOption.cardCount:
        return Icons.style_rounded;
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
  final List<PokemonCardData> _unassignedCards = PokemonCardData.library
      .where((c) => c.supertype != CardSupertype.pokemon)
      .toList();

  int _tabIndex = 0;

  late BinderData _selectedBinder = _binders.first;
  int _pageIndex = 0;
  bool _showingUnassigned = false;

  String _binderSearch = '';
  BinderSortOption _binderSort = BinderSortOption.name;
  bool _viewingAllBinders = false;
  String _cardSearch = '';
  CardSortOption _sortOption = CardSortOption.time;
  PokemonCardType? _typeFilter;
  String? _subtypeFilter;
  String? _setFilter;
  String? _rarityFilter;
  String? _conditionFilter;
  TimeSortDirection _timeDirection = TimeSortDirection.newest;

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
      _viewingAllBinders = false;
    });
  }

  void _selectUnassigned() {
    setState(() {
      _showingUnassigned = true;
      _viewingAllBinders = false;
    });
  }

  void _toggleViewAllBinders() {
    setState(() => _viewingAllBinders = !_viewingAllBinders);
  }

  void _toggleBinderPin(BinderData binder) {
    setState(() {
      final index = _binders.indexWhere((b) => b.id == binder.id);
      if (index == -1) return;
      final updated = _binders[index].copyWith(isPinned: !_binders[index].isPinned);
      _binders[index] = updated;
      if (_selectedBinder.id == binder.id) _selectedBinder = updated;
    });
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
                        binderSort: _binderSort,
                        viewingAllBinders: _viewingAllBinders,
                        onSearchChanged: (v) =>
                            setState(() => _binderSearch = v),
                        onBinderSortChanged: (option) =>
                            setState(() => _binderSort = option),
                        onToggleViewAllBinders: _toggleViewAllBinders,
                        onSelectBinder: _selectBinder,
                        onSelectUnassigned: _selectUnassigned,
                        onTogglePin: _toggleBinderPin,
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
                        conditionFilter: _conditionFilter,
                        timeDirection: _timeDirection,
                        onSearchChanged: (v) =>
                            setState(() => _cardSearch = v),
                        onSortChanged: (option) => setState(() {
                          _sortOption = option;
                          _typeFilter = null;
                          _subtypeFilter = null;
                          _setFilter = null;
                          _rarityFilter = null;
                          _conditionFilter = null;
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
                        onConditionFilterChanged: (c) =>
                            setState(() => _conditionFilter = c),
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

class _BindersTab extends StatelessWidget {
  final List<BinderData> binders;
  final BinderData selectedBinder;
  final int pageIndex;
  final List<PokemonCardData> unassignedCards;
  final bool showingUnassigned;
  final BinderSortOption binderSort;
  final bool viewingAllBinders;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<BinderSortOption> onBinderSortChanged;
  final VoidCallback onToggleViewAllBinders;
  final ValueChanged<BinderData> onSelectBinder;
  final VoidCallback onSelectUnassigned;
  final ValueChanged<BinderData> onTogglePin;
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
    required this.binderSort,
    required this.viewingAllBinders,
    required this.onSearchChanged,
    required this.onBinderSortChanged,
    required this.onToggleViewAllBinders,
    required this.onSelectBinder,
    required this.onSelectUnassigned,
    required this.onTogglePin,
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
          if (binders.length > 1) ...[
            _BinderToolbar(
              sortOption: binderSort,
              onSortChanged: onBinderSortChanged,
            ),
            const SizedBox(height: PokeBinderSpacing.sp3),
          ],
          _BinderListPanel(
            binders: binders,
            selectedBinder: selectedBinder,
            showingUnassigned: showingUnassigned,
            unassignedCount: unassignedCards.length,
            sortOption: binderSort,
            viewingAllBinders: viewingAllBinders,
            onToggleViewAllBinders: onToggleViewAllBinders,
            onSelect: onSelectBinder,
            onSelectUnassigned: onSelectUnassigned,
            onTogglePin: onTogglePin,
          ),
          if (!viewingAllBinders) ...[
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
                          const SizedBox(height: PokeBinderSpacing.sp1),
                          Text(
                            card.name,
                            style: PokeBinderText.cardName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
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
                        const SizedBox(height: PokeBinderSpacing.sp1),
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
        ],
      ),
    );
  }
}

class _AllCardsTab extends StatelessWidget {
  final List<PokemonCardData> cards;
  final String search;
  final CardSortOption sortOption;
  final PokemonCardType? typeFilter;
  final String? subtypeFilter;
  final String? setFilter;
  final String? rarityFilter;
  final String? conditionFilter;
  final TimeSortDirection timeDirection;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CardSortOption> onSortChanged;
  final ValueChanged<PokemonCardType?> onTypeFilterChanged;
  final ValueChanged<String?> onSubtypeFilterChanged;
  final ValueChanged<String?> onSetFilterChanged;
  final ValueChanged<String?> onRarityFilterChanged;
  final ValueChanged<String?> onConditionFilterChanged;
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
    required this.conditionFilter,
    required this.timeDirection,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onTypeFilterChanged,
    required this.onSubtypeFilterChanged,
    required this.onSetFilterChanged,
    required this.onRarityFilterChanged,
    required this.onConditionFilterChanged,
    required this.onTimeDirectionChanged,
    required this.onCardTap,
  });

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

  static String _rarityTier(String rawRarity) {
    switch (rawRarity) {
      case 'Common':
        return 'Common';
      case 'Uncommon':
        return 'Uncommon';
      case 'Rare':
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

  static IconData _rarityTierIcon(String tier) => rarityIconFor(tier);

  static const _conditionOrder = <String>['NM', 'LP', 'MP', 'DMG'];

  static const _conditionLabels = <String, String>{
    'NM': 'Near Mint',
    'LP': 'Lightly Played',
    'MP': 'Moderately Played',
    'DMG': 'Damaged',
  };

  static IconData _conditionIcon(String code) => conditionIconFor(code);

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
        bySupertype.where((c) => _matchesEnergyFilter(c, subtypeFilter)),
      CardSortOption.set =>
        bySupertype.where((c) => setFilter == null || c.setName == setFilter),
      CardSortOption.rarity =>
        bySupertype.where(
            (c) => rarityFilter == null || _rarityTier(c.rarity) == rarityFilter),
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
      case CardSortOption.condition:
        int conditionRankOf(PokemonCardData c) =>
            _conditionOrder.indexOf(c.condition);

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
        subOptionRow = _SubtypeChipRow(
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
        subOptionRow = _TypeChipRow(selected: typeFilter, onChanged: onTypeFilterChanged);
        break;
      case CardSortOption.trainer:
        subOptionRow = _SubtypeChipRow(
          options: _kTrainerSubtypeChips,
          selected: subtypeFilter,
          iconFor: _trainerSubtypeIcon,
          onChanged: onSubtypeFilterChanged,
        );
        break;
      case CardSortOption.energy:
        subOptionRow = _SubtypeChipRow(
          options: _kEnergySubtypeChips,
          selected: subtypeFilter,
          iconFor: _energySubtypeIcon,
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
          iconFor: (key) => key == null
              ? Icons.apps_rounded
              : Icons.collections_bookmark_outlined,
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
          iconFor: (key) =>
              key == null ? Icons.apps_rounded : _rarityTierIcon(key),
          onChanged: onRarityFilterChanged,
        );
        break;
      case CardSortOption.condition:
        final conditionOptions = <String?, String>{
          null: 'All',
          for (final code in _conditionOrder) code: _conditionLabels[code]!,
        };
        subOptionRow = _SubtypeChipRow(
          options: conditionOptions,
          selected: conditionFilter,
          iconFor: (key) =>
              key == null ? Icons.apps_rounded : _conditionIcon(key),
          onChanged: onConditionFilterChanged,
        );
        break;
      case CardSortOption.alphabetical:
      case CardSortOption.cardNumber:
      case CardSortOption.quantity:
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
                          const SizedBox(height: PokeBinderSpacing.sp1),
                          Text(
                            card.name,
                            style: PokeBinderText.cardName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
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

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: PokeBinderSpacing.sp2,
      ),
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

const int kMaxBindersPerSection = 4;
const int kMaxPinnedBinders = 2;

class _BinderSection {
  final String title;
  final List<BinderData> binders;
  final int totalCount;
  final bool includesUnsorted;

  const _BinderSection({
    required this.title,
    required this.binders,
    required this.totalCount,
    this.includesUnsorted = false,
  });

  int get _shownCount => binders.length + (includesUnsorted ? 1 : 0);
  int get hiddenCount => totalCount - _shownCount;
}

class _BinderListPanel extends StatelessWidget {
  final List<BinderData> binders;
  final BinderData selectedBinder;
  final bool showingUnassigned;
  final int unassignedCount;
  final BinderSortOption sortOption;
  final bool viewingAllBinders;
  final VoidCallback onToggleViewAllBinders;
  final ValueChanged<BinderData> onSelect;
  final VoidCallback onSelectUnassigned;
  final ValueChanged<BinderData> onTogglePin;

  const _BinderListPanel({
    required this.binders,
    required this.selectedBinder,
    required this.showingUnassigned,
    required this.unassignedCount,
    required this.sortOption,
    required this.viewingAllBinders,
    required this.onToggleViewAllBinders,
    required this.onSelect,
    required this.onSelectUnassigned,
    required this.onTogglePin,
  });

  int _compare(BinderData a, BinderData b) {
    switch (sortOption) {
      case BinderSortOption.name:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case BinderSortOption.recent:
        return b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch);
      case BinderSortOption.cardCount:
        return b.cardCount.compareTo(a.cardCount);
    }
  }

  List<_BinderSection> _buildSections() {
    final pinned = binders.where((b) => b.isPinned).toList()..sort(_compare);
    final rest = binders.where((b) => !b.isPinned).toList()..sort(_compare);

    final sections = <_BinderSection>[];

    if (pinned.isNotEmpty) {
      sections.add(_BinderSection(
        title: 'Pinned Binders',
        binders: viewingAllBinders ? pinned : pinned.take(kMaxPinnedBinders).toList(),
        totalCount: pinned.length,
      ));
    }

    final allSlotsForBinders = (kMaxBindersPerSection - 1).clamp(0, kMaxBindersPerSection);
    sections.add(_BinderSection(
      title: 'All Binders',
      binders: viewingAllBinders ? rest : rest.take(allSlotsForBinders).toList(),
      totalCount: rest.length + 1,
      includesUnsorted: true,
    ));

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final hiddenCount =
        sections.fold<int>(0, (sum, section) => sum + section.hiddenCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              _SectionHeader(
                title: section.title,
                count: section.totalCount,
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final binder in section.binders)
                    SizedBox(
                      width: tileWidth,
                      child: _BinderGridTile(
                        binder: binder,
                        selected: !viewingAllBinders &&
                            !showingUnassigned &&
                            binder.id == selectedBinder.id,
                        onTap: () => onSelect(binder),
                        onTogglePin: () => onTogglePin(binder),
                      ),
                    ),
                  if (section.includesUnsorted)
                    SizedBox(
                      width: tileWidth,
                      child: _BinderGridTile.unassigned(
                        count: unassignedCount,
                        selected: !viewingAllBinders && showingUnassigned,
                        onTap: onSelectUnassigned,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
            ],
            if (hiddenCount > 0 || viewingAllBinders)
              GestureDetector(
                onTap: onToggleViewAllBinders,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        viewingAllBinders
                            ? 'Show Less'
                            : 'View All Binders (+$hiddenCount)',
                        style: PokeBinderText.backLink,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        viewingAllBinders
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 14,
                        color: PokeBinderText.backLink.color,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text('${title.toUpperCase()} · $count', style: PokeBinderText.sectionLabel),
    );
  }
}

class _BinderGridTile extends StatelessWidget {
  final BinderData? binder;
  final bool selected;
  final bool muted;
  final String? overrideTitle;
  final String? overrideSubtitle;
  final IconData? overrideIcon;
  final VoidCallback onTap;
  final VoidCallback? onTogglePin;

  const _BinderGridTile({
    required this.binder,
    required this.selected,
    this.muted = false,
    this.overrideTitle,
    this.overrideSubtitle,
    this.overrideIcon,
    required this.onTap,
    this.onTogglePin,
  });

  const _BinderGridTile.unassigned({
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) : this(
          binder: null,
          selected: selected,
          muted: true,
          overrideTitle: 'Unassigned Cards',
          overrideSubtitle: '$count ${count == 1 ? 'card' : 'cards'} · no binder',
          overrideIcon: Icons.inbox_rounded,
          onTap: onTap,
        );

  @override
  Widget build(BuildContext context) {
    final title = overrideTitle ?? binder!.name;
    final subtitle = overrideSubtitle ??
        '${binder!.pageCount} ${binder!.pageCount == 1 ? 'page' : 'pages'} · '
            '${binder!.cardCount} ${binder!.cardCount == 1 ? 'card' : 'cards'}';
    final icon = overrideIcon ?? Icons.menu_book_rounded;
    final isPinned = binder?.isPinned ?? false;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: PokeBinderColors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? PokeBinderColors.red.withValues(alpha: 0.5)
                : PokeBinderColors.ink.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: PokeBinderColors.ink.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: muted ? null : PokeBinderColors.redGradient,
                    color: muted ? PokeBinderColors.cream2 : null,
                    border: muted
                        ? Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.12))
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: muted ? PokeBinderColors.inkSoft : PokeBinderColors.white,
                  ),
                ),
                const Spacer(),
                if (onTogglePin != null)
                  GestureDetector(
                    onTap: onTogglePin,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        size: 14,
                        color: isPinned
                            ? PokeBinderColors.red
                            : PokeBinderColors.inkSoft.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PokeBinderText.listRowTitle.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? PokeBinderColors.redDeep : PokeBinderColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PokeBinderText.listRowSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _BinderToolbar extends StatelessWidget {
  final BinderSortOption sortOption;
  final ValueChanged<BinderSortOption> onSortChanged;

  const _BinderToolbar({
    required this.sortOption,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BinderSortSelector(selected: sortOption, onChanged: onSortChanged),
      ],
    );
  }
}

class _BinderSortSelector extends StatelessWidget {
  final BinderSortOption selected;
  final ValueChanged<BinderSortOption> onChanged;

  const _BinderSortSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: PokeBinderColors.red.withValues(alpha: 0.06),
        splashColor: PokeBinderColors.red.withValues(alpha: 0.06),
        hoverColor: PokeBinderColors.red.withValues(alpha: 0.05),
      ),
      child: PopupMenuButton<BinderSortOption>(
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
        constraints: const BoxConstraints(minWidth: 175),
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemBuilder: (context) => [
          for (final option in BinderSortOption.values)
            PopupMenuItem(
              value: option,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _BinderSortMenuRow(option: option, selected: option == selected),
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

class _BinderSortMenuRow extends StatelessWidget {
  final BinderSortOption option;
  final bool selected;

  const _BinderSortMenuRow({required this.option, required this.selected});

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
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in _types.entries)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _Chip(
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
    if (type == PokemonCardType.colorless) return Icons.circle;
    if (type == PokemonCardType.dragon) return Icons.all_inclusive_rounded;
    return _elementIcon(type.name);
  }
}

IconData _elementIcon(String elementKey) {
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

IconData _trainerSubtypeIcon(String? key) {
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

IconData _energySubtypeIcon(String? key) {
  switch (key) {
    case 'Basic':
      return Icons.crop_square_rounded;
    case 'Special':
      return Icons.flare_rounded;
    case null:
      return Icons.apps_rounded;
    default:
      return _elementIcon(key);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
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
              color: active
                  ? PokeBinderColors.white
                  : PokeBinderColors.inkSoft,
            ),
            const SizedBox(width: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: active
                  ? PokeBinderText.chipLabelActive
                  : PokeBinderText.chipLabel,
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

const _kTrainerSubtypeChips = <String?, String>{
  null: 'All',
  'Item': 'Items',
  'Supporter': 'Supporters',
  'Stadium': 'Stadiums',
};

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

class _SubtypeChipRow extends StatelessWidget {
  final Map<String?, String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  final IconData Function(String? key) iconFor;

  const _SubtypeChipRow({
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
              child: _Chip(
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

class _SortSelector extends StatelessWidget {
  final CardSortOption selected;
  final ValueChanged<CardSortOption> onChanged;

  const _SortSelector({required this.selected, required this.onChanged});

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
              child: _SortMenuRow(option: option, selected: option == selected),
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

class _SortMenuRow extends StatelessWidget {
  final CardSortOption option;
  final bool selected;

  const _SortMenuRow({required this.option, required this.selected});

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
            SizedBox(height: PokeBinderSpacing.sp2),
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