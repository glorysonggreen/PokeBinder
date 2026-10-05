import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../services/binder_repository.dart';
import '../services/card_repository.dart';
import '../theme/pokebinder_motion.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/card_caption.dart';
import '../widgets/card_sort_controls.dart';
import '../widgets/min_tap_target.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/pokebinder_controls.dart';
import 'binder_add_card_screen.dart';
import 'binder_detail_screen.dart';
import 'binder_form_screen.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';
import '../services/audio_service.dart';

export '../widgets/card_sort_controls.dart' show CardSortOption, TimeSortDirection;

enum BinderSortOption { name, newest, oldest, cardCount, value }

extension BinderSortOptionLabel on BinderSortOption {
  String get label {
    switch (this) {
      case BinderSortOption.name:
        return 'Alphabetical';
      case BinderSortOption.newest:
        return 'Newest';
      case BinderSortOption.oldest:
        return 'Oldest';
      case BinderSortOption.cardCount:
        return 'Most Cards';
      case BinderSortOption.value:
        return 'Highest Value';
    }
  }

  IconData get icon {
    switch (this) {
      case BinderSortOption.name:
        return Icons.sort_by_alpha_rounded;
      case BinderSortOption.newest:
        return Icons.schedule_rounded;
      case BinderSortOption.oldest:
        return Icons.history_rounded;
      case BinderSortOption.cardCount:
        return Icons.style_rounded;
      case BinderSortOption.value:
        return Icons.payments_rounded;
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
  final List<BinderData> _binders = BinderData.library;

  List<PokemonCardData> get _unassignedCards => PokemonCardData.library
      .where((c) => c.binderName == kUnassignedBinderName)
      .toList();

  late int _tabIndex = widget.initialTabIndex;

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

  List<PokemonCardData> get _allCards => PokemonCardData.library;

  @override
  void initState() {
    super.initState();
    final initialId = widget.initialBinderId;
    if (initialId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (initialId == kUnassignedBinderId) {
          _openUnassignedDetail();
          return;
        }
        final matches = _binders.where((b) => b.id == initialId);
        if (matches.isNotEmpty) _openBinderDetail(matches.first);
      });
    }
  }

  Future<void> _openCard(PokemonCardData card) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardDetailsScreen(
          card: card,
          binders: _binders,
          onSave: _handleCardSaved,
        ),
      ),
    );
  }

  void _toggleViewAllBinders() {
    setState(() => _viewingAllBinders = !_viewingAllBinders);
  }

  void _toggleBinderPin(BinderData binder) {
    PokeBinderAudio.play(binder.isPinned ? Sfx.toggleOff : Sfx.star);
    setState(() {
      final index = _binders.indexWhere((b) => b.id == binder.id);
      if (index == -1) return;
      _binders[index] = _binders[index].copyWith(isPinned: !_binders[index].isPinned);
    });
    final updated = _binders.where((b) => b.id == binder.id);
    if (updated.isNotEmpty) BinderRepository.upsert(updated.first);
  }

  Future<void> _openNewBinder() async {
    final result = await Navigator.of(context).push<BinderFormResult>(
      MaterialPageRoute(builder: (_) => const BinderFormScreen()),
    );
    if (result?.binder == null) return;

    PokeBinderAudio.play(Sfx.success);
    setState(() => _binders.add(result!.binder!));
    BinderRepository.upsert(result!.binder!);
    if (!mounted) return;
    await _openBinderDetail(result!.binder!);
  }

  Future<void> _openBinderDetail(BinderData binder) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BinderDetailScreen(
          binderId: binder.id,
          binders: _binders,
          unassignedCards: () => _unassignedCards,
          onCardTap: _openCard,
          onAddCard: _openAddCardFor,
          onCardRemoved: _removeCardFromBinder,
          onBinderChanged: _applyBinderChange,
          onBinderDeleted: _applyBinderDeletion,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openUnassignedDetail() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BinderDetailScreen(
          binderId: null,
          binders: _binders,
          unassignedCards: () => _unassignedCards,
          onCardTap: _openCard,
          onAddCard: _openAddCardFor,
          onCardRemoved: _removeCardFromBinder,
          onBinderChanged: _applyBinderChange,
          onBinderDeleted: _applyBinderDeletion,
        ),
      ),
    );
    setState(() {});
  }

  void _applyBinderChange(BinderData updated) {
    setState(() {
      final index = _binders.indexWhere((b) => b.id == updated.id);
      if (index == -1) return;
      final previousName = _binders[index].name;
      if (previousName != updated.name) {
        _renameCardsBinder(previousName, updated.name);
      }
      _binders[index] = updated;
    });
    BinderRepository.upsert(updated);
  }

  void _applyBinderDeletion(BinderData deleted) {
    setState(() {
      _renameCardsBinder(deleted.name, kUnassignedBinderName, resetPage: true);
      _binders.removeWhere((b) => b.id == deleted.id);
    });
    BinderRepository.delete(deleted.id);
  }

  void _renameCardsBinder(String oldName, String newName,
      {bool resetPage = false}) {
    final library = PokemonCardData.library;
    var changed = false;
    for (var i = 0; i < library.length; i++) {
      if (library[i].binderName != oldName) continue;
      library[i] = library[i].copyWith(
        binderName: newName,
        page: resetPage ? 0 : null,
      );
      changed = true;
    }
    if (changed) {
      CardRepository.renameBinder(oldName, newName, resetPage: resetPage);
    }
  }

  void _removeCardFromBinder(PokemonCardData card) {
    var found = true;
    setState(() {
      final index = PokemonCardData.library.indexWhere((c) => c.id == card.id);
      if (index == -1) {
        found = false;
        return;
      }
      PokemonCardData.library[index] = PokemonCardData.library[index]
          .copyWith(binderName: kUnassignedBinderName, page: 0);
    });
    if (!found) return;
    PokeBinderAudio.play(Sfx.cardMove);
    CardRepository.upsert(
      PokemonCardData.library.firstWhere((c) => c.id == card.id),
    );
  }

  Future<void> _openAddCardFor({
    required String? binderId,
    required int pageIndex,
  }) async {
    if (binderId == null) return;

    final binderIndex = _binders.indexWhere((b) => b.id == binderId);
    if (binderIndex == -1) return;
    final binder = _binders[binderIndex];

    final picks = await Navigator.of(context).push<List<BinderCardPick>>(
      MaterialPageRoute(
        builder: (_) => BinderAddCardScreen(
          binderName: binder.name,
          pageIndex: pageIndex,
          availableCards: () => _cardsOutsideBinder(binder.id),
          onCardTap: _openCard,
        ),
      ),
    );
    if (picks == null || picks.isEmpty) return;

    PokeBinderAudio.play(Sfx.cardMove);
    setState(() => _moveCardsToBinder(picks, binder.id, pageIndex));
  }

  List<PokemonCardData> _cardsOutsideBinder(String binderId) {
    final matches = _binders.where((b) => b.id == binderId);
    if (matches.isEmpty) return PokemonCardData.library;
    final binderName = matches.first.name;
    return PokemonCardData.library
        .where((c) => c.binderName != binderName)
        .toList();
  }

  void _growBinderIfNeeded(String binderId, int pageIndex) {
    if (binderId == kUnassignedBinderId) return;
    final index = _binders.indexWhere((b) => b.id == binderId);
    if (index == -1) return;
    final binder = _binders[index];
    if (pageIndex >= binder.pageCount) {
      _binders[index] = binder.copyWith(pageCount: pageIndex + 1);
      BinderRepository.upsert(_binders[index]);
    }
  }

  void _moveCardsToBinder(
    List<BinderCardPick> picks,
    String binderId,
    int pageIndex,
  ) {
    final binderIndex = _binders.indexWhere((b) => b.id == binderId);
    if (binderIndex == -1) return;
    _growBinderIfNeeded(binderId, pageIndex);
    final binderName = _binders[binderIndex].name;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final library = PokemonCardData.library;

    for (var i = 0; i < picks.length; i++) {
      final pick = picks[i];
      final cardIndex = library.indexWhere((c) => c.id == pick.cardId);
      if (cardIndex == -1) continue;
      final card = library[cardIndex];
      final count =
          pick.quantity > card.quantityOwned ? card.quantityOwned : pick.quantity;
      if (count < 1) continue;

      if (count == card.quantityOwned) {
        library[cardIndex] =
            card.copyWith(binderName: binderName, page: pageIndex + 1);
        CardRepository.upsert(library[cardIndex]);
      } else {
        library[cardIndex] =
            card.copyWith(quantityOwned: card.quantityOwned - count);
        CardRepository.upsert(library[cardIndex]);
        final newCard = card.copyWith(
          id: 'card-$stamp-$i',
          quantityOwned: count,
          binderName: binderName,
          page: pageIndex + 1,
        );
        library.add(newCard);
        CardRepository.upsert(newCard);
      }
    }
  }

  void _handleCardSaved(PokemonCardData oldCard, CardFormResult result) {
    setState(() {
      final index =
          PokemonCardData.library.indexWhere((c) => c.id == oldCard.id);
      if (result.deleted) {
        if (index != -1) PokemonCardData.library.removeAt(index);
        return;
      }
      _growBinderIfNeeded(result.binderId!, result.pageIndex!);
      if (index != -1) {
        PokemonCardData.library[index] = result.card!;
      } else {
        PokemonCardData.library.add(result.card!);
      }
    });
    if (result.deleted) {
      CardRepository.delete(oldCard.id);
    } else {
      CardRepository.upsert(result.card!);
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
              const SizedBox(height: PokeBinderSpacing.sp4),
              _TopTabBar(
                index: _tabIndex,
                labels: const ['Binders', 'All Cards'],
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              Expanded(
                child: FadeSlideIn.fade(
                  key: ValueKey(_tabIndex),
                  child: _tabIndex == 0
                      ? _BindersTab(
                          binders: filteredBinders,
                          search: _binderSearch,
                          unassignedCount: _unassignedCards.length,
                          binderSort: _binderSort,
                          viewingAllBinders: _viewingAllBinders,
                          onSearchChanged: (v) =>
                              setState(() => _binderSearch = v),
                          onBinderSortChanged: (option) =>
                              setState(() => _binderSort = option),
                          onToggleViewAllBinders: _toggleViewAllBinders,
                          onSelectBinder: _openBinderDetail,
                          onSelectUnassigned: _openUnassignedDetail,
                          onTogglePin: _toggleBinderPin,
                          onNewBinder: _openNewBinder,
                          onClearFilters: () =>
                              setState(() => _binderSearch = ''),
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
                          onClearFilters: () => setState(() {
                            _cardSearch = '';
                            _typeFilter = null;
                            _subtypeFilter = null;
                            _setFilter = null;
                            _rarityFilter = null;
                            _conditionFilter = null;
                          }),
                        ),
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
              padding: const EdgeInsets.only(right: PokeBinderSpacing.sp4),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: PokeBinderMotion.fast,
                  curve: PokeBinderMotion.curve,
                  padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp2),
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
                  child: AnimatedDefaultTextStyle(
                    duration: PokeBinderMotion.fast,
                    style: i == index
                        ? PokeBinderText.tabLabelActive
                        : PokeBinderText.tabLabelInactive,
                    child: Text(labels[i]),
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
  final String search;
  final int unassignedCount;
  final BinderSortOption binderSort;
  final bool viewingAllBinders;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<BinderSortOption> onBinderSortChanged;
  final VoidCallback onToggleViewAllBinders;
  final ValueChanged<BinderData> onSelectBinder;
  final VoidCallback onSelectUnassigned;
  final ValueChanged<BinderData> onTogglePin;
  final VoidCallback onNewBinder;
  final VoidCallback onClearFilters;

  const _BindersTab({
    required this.binders,
    required this.search,
    required this.unassignedCount,
    required this.binderSort,
    required this.viewingAllBinders,
    required this.onSearchChanged,
    required this.onBinderSortChanged,
    required this.onToggleViewAllBinders,
    required this.onSelectBinder,
    required this.onSelectUnassigned,
    required this.onTogglePin,
    required this.onNewBinder,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final showEmptyState = binders.isEmpty && search.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollectionSearchBar(
            hint: 'Search binders…',
            text: search,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          PillButton(
            label: 'New Binder',
            icon: Icons.add,
            onTap: onNewBinder,
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          if (showEmptyState)
            EmptyFilterState(
              title: 'No binders match your search.',
              subtitle: 'Try a different search term.',
              onClearFilters: onClearFilters,
            )
          else ...[
            if (binders.length > 1) ...[
              _BinderToolbar(
                sortOption: binderSort,
                onSortChanged: onBinderSortChanged,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
            ],
            _BinderListPanel(
              binders: binders,
              unassignedCount: unassignedCount,
              sortOption: binderSort,
              viewingAllBinders: viewingAllBinders,
              onToggleViewAllBinders: onToggleViewAllBinders,
              onSelect: onSelectBinder,
              onSelectUnassigned: onSelectUnassigned,
              onTogglePin: onTogglePin,
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
  final VoidCallback onClearFilters;

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
    required this.onClearFilters,
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
            text: search,
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
            EmptyFilterState(
              title: 'No cards match your filters.',
              subtitle: 'Try a different search or filter.',
              onClearFilters: onClearFilters,
            )
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
                    for (final (i, card) in filtered.indexed)
                      FadeSlideIn(
                        index: i,
                        child: Column(
                          children: [
                            SizedBox(
                              height: cardHeight,
                              child: BinderCardTile(
                                card: card,
                                onTap: () => onCardTap(card),
                              ),
                            ),
                            const SizedBox(height: PokeBinderSpacing.sp1),
                            CardCaption(card: card),
                          ],
                        ),
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
  final int unassignedCount;
  final BinderSortOption sortOption;
  final bool viewingAllBinders;
  final VoidCallback onToggleViewAllBinders;
  final ValueChanged<BinderData> onSelect;
  final VoidCallback onSelectUnassigned;
  final ValueChanged<BinderData> onTogglePin;

  const _BinderListPanel({
    required this.binders,
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
      case BinderSortOption.newest:
        return b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch);
      case BinderSortOption.oldest:
        return a.createdAtOrEpoch.compareTo(b.createdAtOrEpoch);
      case BinderSortOption.cardCount:
        return b.cardCount.compareTo(a.cardCount);
      case BinderSortOption.value:
        return b.totalValue.compareTo(a.totalValue);
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
                  for (final (i, binder) in section.binders.indexed)
                    FadeSlideIn(
                      index: i,
                      child: SizedBox(
                        width: tileWidth,
                        child: _BinderGridTile(
                          binder: binder,
                          onTap: () => onSelect(binder),
                          onTogglePin: () => onTogglePin(binder),
                        ),
                      ),
                    ),
                  if (section.includesUnsorted)
                    SizedBox(
                      width: tileWidth,
                      child: _BinderGridTile.unassigned(
                        count: unassignedCount,
                        onTap: onSelectUnassigned,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
            ],
            if (hiddenCount > 0 || viewingAllBinders)
              MinTapTarget(
                onTap: onToggleViewAllBinders,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewingAllBinders
                          ? 'Show Less'
                          : 'View All Binders (+$hiddenCount)',
                      style: PokeBinderText.backLink,
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp1),
                    AnimatedRotation(
                      turns: viewingAllBinders ? 0.5 : 0,
                      duration: PokeBinderMotion.fast,
                      curve: PokeBinderMotion.curve,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 14,
                        color: PokeBinderText.backLink.color,
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.only(left: PokeBinderSpacing.sp0),
      child: Text('${title.toUpperCase()} · $count', style: PokeBinderText.sectionLabel),
    );
  }
}

class _BinderGridTile extends StatelessWidget {
  final BinderData? binder;
  final bool muted;
  final String? overrideTitle;
  final String? overrideSubtitle;
  final IconData? overrideIcon;
  final VoidCallback onTap;
  final VoidCallback? onTogglePin;

  const _BinderGridTile({
    required this.binder,
    this.muted = false,
    this.overrideTitle,
    this.overrideSubtitle,
    this.overrideIcon,
    required this.onTap,
    this.onTogglePin,
  });

  const _BinderGridTile.unassigned({
    required int count,
    required VoidCallback onTap,
  }) : this(
          binder: null,
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

    return PressableScale(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(PokeBinderSpacing.sp3),
        decoration: BoxDecoration(
          color: PokeBinderColors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: PokeBinderColors.ink.withValues(alpha: 0.08),
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
            SizedBox(
              height: kMinTapTarget,
              child: Row(
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
                    MinTapTarget(
                      onTap: onTogglePin,
                      semanticLabel: isPinned ? 'Unpin binder' : 'Pin binder',
                      child: BouncySwitcher(
                        child: Icon(
                          isPinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                          key: ValueKey(isPinned),
                          size: 14,
                          color: isPinned
                              ? PokeBinderColors.red
                              : PokeBinderColors.inkSoft.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: PokeBinderSpacing.sp2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PokeBinderText.listRowTitle.copyWith(
                fontWeight: FontWeight.w600,
                color: PokeBinderColors.ink,
              ),
            ),
            const SizedBox(height: PokeBinderSpacing.sp0),
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
        padding: const EdgeInsets.symmetric(vertical: PokeBinderSpacing.sp2),
        itemBuilder: (context) => [
          for (final option in BinderSortOption.values)
            PopupMenuItem(
              value: option,
              height: 38,
              padding: const EdgeInsets.symmetric(
                horizontal: PokeBinderSpacing.sp1,
              ),
              child: _BinderSortMenuRow(option: option, selected: option == selected),
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

class _BinderSortMenuRow extends StatelessWidget {
  final BinderSortOption option;
  final bool selected;

  const _BinderSortMenuRow({required this.option, required this.selected});

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
