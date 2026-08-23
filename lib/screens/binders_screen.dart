import 'package:flutter/material.dart';

import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/pokebinder_controls.dart';
import 'binder_form_screen.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

/// How the All Cards tab orders/groups the collection. Recent and
/// Alphabetical span every supertype; Pokémon/Trainer/Energy additionally
/// restrict the list to that supertype and swap the chip row beneath the
/// search bar to that supertype's own subcategories.
enum CardSortOption { recent, alphabetical, pokemon, trainer, energy }

extension CardSortOptionLabel on CardSortOption {
  String get label {
    switch (this) {
      case CardSortOption.recent:
        return 'Recent';
      case CardSortOption.alphabetical:
        return 'Alphabetical';
      case CardSortOption.pokemon:
        return 'Pokémon';
      case CardSortOption.trainer:
        return 'Trainer';
      case CardSortOption.energy:
        return 'Energy';
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
  CardSortOption _sortOption = CardSortOption.recent;
  PokemonCardType? _typeFilter;
  String? _subtypeFilter;

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
                        onSearchChanged: (v) =>
                            setState(() => _cardSearch = v),
                        onSortChanged: (option) => setState(() {
                          _sortOption = option;
                          // A stale chip selection from the previous
                          // category wouldn't make sense in the new one.
                          _typeFilter = null;
                          _subtypeFilter = null;
                        }),
                        onTypeFilterChanged: (t) =>
                            setState(() => _typeFilter = t),
                        onSubtypeFilterChanged: (s) =>
                            setState(() => _subtypeFilter = s),
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
            label: '＋ New binder',
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
                  child: Text('✎ Edit', style: PokeBinderText.backLink),
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
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CardSortOption> onSortChanged;
  final ValueChanged<PokemonCardType?> onTypeFilterChanged;
  final ValueChanged<String?> onSubtypeFilterChanged;
  final ValueChanged<PokemonCardData> onCardTap;

  const _AllCardsTab({
    required this.cards,
    required this.search,
    required this.sortOption,
    required this.typeFilter,
    required this.subtypeFilter,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onTypeFilterChanged,
    required this.onSubtypeFilterChanged,
    required this.onCardTap,
  });

  /// Trainer/Energy cards don't have an elemental [PokemonCardType], so the
  /// chip row only makes sense for those categories once a supertype is
  /// selected. Recent/Alphabetical show every card, so they keep the
  /// original elemental-type chips.
  bool get _showsSubtypeChips =>
      sortOption == CardSortOption.trainer || sortOption == CardSortOption.energy;

  @override
  Widget build(BuildContext context) {
    final bySupertype = switch (sortOption) {
      CardSortOption.pokemon =>
        cards.where((c) => c.supertype == CardSupertype.pokemon),
      CardSortOption.trainer =>
        cards.where((c) => c.supertype == CardSupertype.trainer),
      CardSortOption.energy =>
        cards.where((c) => c.supertype == CardSupertype.energy),
      CardSortOption.recent || CardSortOption.alphabetical => cards,
    };

    final byChip = _showsSubtypeChips
        ? bySupertype.where(
            (c) => subtypeFilter == null || c.subtype == subtypeFilter)
        : bySupertype.where(
            (c) => typeFilter == null || c.type == typeFilter);

    final filtered = byChip
        .where((c) => c.name.toLowerCase().contains(search.toLowerCase()))
        .toList();

    if (sortOption == CardSortOption.alphabetical) {
      filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
          _showsSubtypeChips
              ? _SubtypeChipRow(
                  options: sortOption == CardSortOption.trainer
                      ? _kTrainerSubtypeChips
                      : _kEnergySubtypeChips,
                  selected: subtypeFilter,
                  onChanged: onSubtypeFilterChanged,
                )
              : _TypeChipRow(selected: typeFilter, onChanged: onTypeFilterChanged),
          const SizedBox(height: PokeBinderSpacing.sp2),
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
      ),
      child: Column(
        children: [
          for (var i = 0; i < binders.length; i++)
            _BinderListRow(
              binder: binders[i],
              selected: !showingUnassigned && binders[i].id == selectedBinder.id,
              showDivider: true,
              onTap: () => onSelect(binders[i]),
            ),
          _UnassignedListRow(
            count: unassignedCount,
            selected: showingUnassigned,
            onTap: onSelectUnassigned,
          ),
        ],
      ),
    );
  }
}

class _UnassignedListRow extends StatelessWidget {
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _UnassignedListRow({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? PokeBinderColors.red.withValues(alpha: 0.07) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: PokeBinderColors.ink.withValues(alpha: 0.08),
                border: Border.all(
                  color: PokeBinderColors.ink.withValues(alpha: 0.18),
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 18,
                color: PokeBinderColors.inkSoft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unassigned', style: PokeBinderText.listRowTitle),
                  Text(
                    '$count ${count == 1 ? 'card' : 'cards'} · no binder',
                    style: PokeBinderText.listRowSubtitle,
                  ),
                ],
              ),
            ),
            Text('›', style: PokeBinderText.listRowSubtitle),
          ],
        ),
      ),
    );
  }
}

class _BinderListRow extends StatelessWidget {
  final BinderData binder;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  const _BinderListRow({
    required this.binder,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? PokeBinderColors.red.withValues(alpha: 0.07)
              : null,
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: PokeBinderColors.ink.withValues(alpha: 0.07),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: binder.accentType.gradientColors,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(binder.name, style: PokeBinderText.listRowTitle),
                  Text(
                    '${binder.pageCount} pages · ${binder.cardCount} cards',
                    style: PokeBinderText.listRowSubtitle,
                  ),
                ],
              ),
            ),
            Text('›', style: PokeBinderText.listRowSubtitle),
          ],
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
    PokemonCardType.fire: '🔥 Fire',
    PokemonCardType.water: '💧 Water',
    PokemonCardType.grass: '🌿 Grass',
    PokemonCardType.electric: '⚡ Electric',
    PokemonCardType.psychic: '🔮 Psychic',
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
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE0402A), PokeBinderColors.red],
                )
              : null,
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
  'Item': '🎒 Item',
  'Supporter': '🧑 Supporter',
  'Stadium': '🏟️ Stadium',
};

const _kEnergySubtypeChips = <String?, String>{
  null: 'All',
  'Basic': '⚡ Basic',
  'Special': '✨ Special',
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