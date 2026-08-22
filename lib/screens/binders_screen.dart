import 'package:flutter/material.dart';

import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/pokebinder_controls.dart';
import 'card_details_screen.dart';

/// The PokeBinder "Binders" screen, matching the mockup's Collection
/// screen: a top tab bar switching between a binder-by-binder page view
/// and a flat, filterable grid of every card.
class BindersScreen extends StatefulWidget {
  const BindersScreen({super.key});

  @override
  State<BindersScreen> createState() => _BindersScreenState();
}

class _BindersScreenState extends State<BindersScreen> {
  final List<BinderData> _binders = BinderData.sampleBinders;

  int _tabIndex = 0; // 0 = Binders, 1 = All Cards

  late BinderData _selectedBinder = _binders.first;
  int _pageIndex = 0;

  String _binderSearch = '';
  String _cardSearch = '';
  PokemonCardType? _typeFilter;

  void _openCard(PokemonCardData card) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CardDetailsScreen(card: card)),
    );
  }

  void _selectBinder(BinderData binder) {
    setState(() {
      _selectedBinder = binder;
      _pageIndex = 0;
    });
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
              const Text('COLLECTION', style: PokeBinderText.eyebrow),
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
                        onSearchChanged: (v) =>
                            setState(() => _binderSearch = v),
                        onSelectBinder: _selectBinder,
                        onPrevPage: _pageIndex > 0
                            ? () => setState(() => _pageIndex--)
                            : null,
                        onNextPage:
                            _pageIndex < _selectedBinder.pageCount - 1
                                ? () => setState(() => _pageIndex++)
                                : null,
                        onCardTap: _openCard,
                      )
                    : _AllCardsTab(
                        search: _cardSearch,
                        typeFilter: _typeFilter,
                        onSearchChanged: (v) =>
                            setState(() => _cardSearch = v),
                        onTypeFilterChanged: (t) =>
                            setState(() => _typeFilter = t),
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
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<BinderData> onSelectBinder;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;
  final ValueChanged<PokemonCardData> onCardTap;

  const _BindersTab({
    required this.binders,
    required this.selectedBinder,
    required this.pageIndex,
    required this.onSearchChanged,
    required this.onSelectBinder,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentPageCards = selectedBinder.pages.isEmpty
        ? const <PokemonCardData>[]
        : selectedBinder.pages[pageIndex];

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
            onTap: () {
              // Hook up to the existing "Create binder" flow, if one
              // already exists in this project.
            },
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          _BinderListPanel(
            binders: binders,
            selectedBinder: selectedBinder,
            onSelect: onSelectBinder,
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          Text(
            '${selectedBinder.name} — Page ${pageIndex + 1}'.toUpperCase(),
            style: PokeBinderText.sectionLabel,
          ),
          const SizedBox(height: PokeBinderSpacing.sp2),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: PokeBinderSpacing.sp2,
            crossAxisSpacing: PokeBinderSpacing.sp2,
            childAspectRatio: kPokemonCardAspectRatio,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final card in currentPageCards)
                BinderCardTile(card: card, onTap: () => onCardTap(card)),
              AddCardTile(onTap: () {}),
            ],
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
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
          const SizedBox(height: PokeBinderSpacing.sp3),
          PillButton(
            label: '✎ Add card manually',
            ghost: true,
            onTap: () {
              // Hook up to the existing "Add card" flow, if one already
              // exists in this project.
            },
          ),
        ],
      ),
    );
  }
}

/// The "All Cards" sub-tab: search, type filter chips, and a flat grid of
/// every matching card with its name beneath it.
class _AllCardsTab extends StatelessWidget {
  final String search;
  final PokemonCardType? typeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PokemonCardType?> onTypeFilterChanged;
  final ValueChanged<PokemonCardData> onCardTap;

  const _AllCardsTab({
    required this.search,
    required this.typeFilter,
    required this.onSearchChanged,
    required this.onTypeFilterChanged,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = PokemonCardData.library.where((card) {
      final matchesSearch =
          card.name.toLowerCase().contains(search.toLowerCase());
      final matchesType = typeFilter == null || card.type == typeFilter;
      return matchesSearch && matchesType;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchBar(
            hint: 'Search all ${PokemonCardData.library.length} cards by name…',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          _TypeChipRow(selected: typeFilter, onChanged: onTypeFilterChanged),
          const SizedBox(height: PokeBinderSpacing.sp2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SHOWING ${filtered.length} CARDS',
                style: PokeBinderText.resultCount,
              ),
              const Text('SORT: RECENT', style: PokeBinderText.resultCount),
            ],
          ),
          const SizedBox(height: PokeBinderSpacing.sp2),
          if (filtered.isEmpty)
            const _EmptyState()
          else
            GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: PokeBinderSpacing.sp3,
              crossAxisSpacing: PokeBinderSpacing.sp2,
              childAspectRatio: kPokemonCardAspectRatio * 0.86,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final card in filtered)
                  Column(
                    children: [
                      Expanded(
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
                    ],
                  ),
              ],
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

/// Matches the mockup's `.panel` containing `.list-row`s.
class _BinderListPanel extends StatelessWidget {
  final List<BinderData> binders;
  final BinderData selectedBinder;
  final ValueChanged<BinderData> onSelect;

  const _BinderListPanel({
    required this.binders,
    required this.selectedBinder,
    required this.onSelect,
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
              selected: binders[i].id == selectedBinder.id,
              showDivider: i != binders.length - 1,
              onTap: () => onSelect(binders[i]),
            ),
        ],
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
