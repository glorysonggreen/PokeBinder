import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/card_sort_controls.dart';
import '../widgets/pokebinder_controls.dart';
import 'binder_form_screen.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

export '../widgets/card_sort_controls.dart' show CardSortOption, TimeSortDirection;

enum BinderSortOption { name, recent, cardCount }

extension BinderSortOptionLabel on BinderSortOption {
  String get label {
    switch (this) {
      case BinderSortOption.name:
        return 'Alphabetically';
      case BinderSortOption.recent:
        return 'Recently Added';
      case BinderSortOption.cardCount:
        return 'Most Cards';
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
  final int initialTabIndex;
  final String? initialBinderId;

  const BindersScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialBinderId,
  });

  @override
  State<BindersScreen> createState() => _BindersScreenState();
}

class _BindersScreenState extends State<BindersScreen> {
  final List<BinderData> _binders = BinderData.sampleBinders;
  final List<PokemonCardData> _unassignedCards = PokemonCardData.library
      .where((c) => c.supertype != CardSupertype.pokemon)
      .toList();

  late int _tabIndex = widget.initialTabIndex;

  late BinderData _selectedBinder = widget.initialBinderId != null
      ? _binders.firstWhere(
          (b) => b.id == widget.initialBinderId,
          orElse: () => _binders.first,
        )
      : _binders.first;
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
          CollectionSearchBar(
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

  @override
  Widget build(BuildContext context) {
    final result = applyCardSort(
      cards: cards,
      search: search,
      sortOption: sortOption,
      typeFilter: typeFilter,
      subtypeFilter: subtypeFilter,
      setFilter: setFilter,
      rarityFilter: rarityFilter,
      conditionFilter: conditionFilter,
      timeDirection: timeDirection,
      onTypeFilterChanged: onTypeFilterChanged,
      onSubtypeFilterChanged: onSubtypeFilterChanged,
      onSetFilterChanged: onSetFilterChanged,
      onRarityFilterChanged: onRarityFilterChanged,
      onConditionFilterChanged: onConditionFilterChanged,
      onTimeDirectionChanged: onTimeDirectionChanged,
    );
    final filtered = result.cards;
    final subOptionRow = result.subOptionRow;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollectionSearchBar(
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
              CardSortSelector(selected: sortOption, onChanged: onSortChanged),
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