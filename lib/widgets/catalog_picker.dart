import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/pricing.dart';
import '../models/catalog_card.dart';
import '../models/pokemon_card_data.dart';
import '../services/catalog_repository.dart';
import '../theme/pokebinder_theme.dart';
import 'card_sort_controls.dart';
import 'pokebinder_background.dart';
import 'pokebinder_controls.dart';
import 'pokebinder_form_fields.dart';
import 'pokeball.dart';
import 'pokemon_card_widget.dart';
import '../services/audio_service.dart';

String _catalogErrorMessage(Object error) {
  if (error is PostgrestException) {
    final text = '${error.code} ${error.message}'.toLowerCase();
    final missing = error.code == 'PGRST205' ||
        error.code == '42P01' ||
        text.contains('card_catalog') ||
        text.contains('card_sets');
    if (missing) {
      return 'The card database isn\'t set up yet. Run supabase/schema.sql in '
          'the Supabase SQL Editor, then load cards (see SUPABASE_SETUP.md, '
          'step 2).';
    }
    return "The card database returned an error (${error.code ?? 'unknown'}): "
        '${error.message}';
  }
  return "Couldn't reach the card database — check your connection and try "
      'again.';
}

const int _kVisibleChunk = 30;

const double _kBackToTopOffset = 600;

const Duration _kBackToTopDuration = Duration(milliseconds: 300);

class CatalogPicker extends StatefulWidget {
  final List<Widget> header;
  final ValueChanged<CatalogCard> onPick;
  final Map<String, int> Function() counts;
  final String countLabel;

  const CatalogPicker({
    super.key,
    required this.header,
    required this.onPick,
    required this.counts,
    this.countLabel = 'OWNED',
  });

  @override
  State<CatalogPicker> createState() => _CatalogPickerState();
}

class _CatalogPickerState extends State<CatalogPicker> {
  static const _allSets = '';

  Timer? _debounce;
  String _query = '';
  String _setId = _allSets;
  List<CatalogSet> _sets = const [];
  List<CatalogCard> _results = [];
  Map<String, DateTime?> _releaseDates = const {};
  bool _loading = false;

  bool _truncated = false;
  String? _error;

  CardSortOption _sortOption = CardSortOption.alphabetical;
  TimeSortDirection _timeDirection = TimeSortDirection.newest;
  PokemonCardType? _typeFilter;
  String? _subtypeFilter;
  String? _rarityFilter;

  int _visibleCount = _kVisibleChunk;

  final _scroll = ScrollController();
  bool _showBackToTop = false;

  int _searchToken = 0;

  bool get _hasCriteria => _query.trim().isNotEmpty || _setId != _allSets;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadSets();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scroll.offset > _kBackToTopOffset;
    if (show != _showBackToTop) setState(() => _showBackToTop = show);
  }

  Future<void> _loadSets() async {
    try {
      final sets = await CatalogRepository.loadSets();
      if (!mounted) return;
      setState(() {
        _sets = sets;
        _releaseDates = {for (final set in sets) set.id: set.releaseDate};
      });
    } catch (_) {}
  }

  void _onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  void _clearSearch() {
    _debounce?.cancel();
    setState(() => _query = '');
    _onSetChanged(_allSets);
  }

  void _onSetChanged(String id) {
    setState(() {
      _setId = id;
      _results = [];
      _sortOption =
          id == _allSets ? CardSortOption.alphabetical : CardSortOption.cardNumber;
      _typeFilter = _subtypeFilter = _rarityFilter = null;
    });
    _runSearch();
  }

  String? get _activeSetId => _setId == _allSets ? null : _setId;

  Future<void> _runSearch() async {
    final token = ++_searchToken;
    if (!_hasCriteria) {
      setState(() {
        _results = [];
        _truncated = false;
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    PokeBinderAudio.play(Sfx.scan);
    if (_sets.isEmpty) _loadSets();
    try {
      final setId = _activeSetId;
      final List<CatalogCard> cards;
      if (setId == null) {
        cards = await CatalogRepository.search(query: _query);
      } else {
        final all = await CatalogRepository.loadSet(setId);
        cards = CatalogRepository.filterCards(all, _query);
      }
      if (!mounted || token != _searchToken) return;
      PokeBinderAudio.play(cards.isEmpty ? Sfx.scanNone : Sfx.scanFound);
      setState(() {
        _results = cards;
        _truncated =
            setId == null && cards.length == CatalogRepository.searchCap;
        _visibleCount = _kVisibleChunk;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || token != _searchToken) return;
      PokeBinderAudio.play(Sfx.error);
      setState(() {
        _loading = false;
        _error = _catalogErrorMessage(e);
      });
    }
  }

  void _update(VoidCallback change) => setState(() {
        change();
        _visibleCount = _kVisibleChunk;
      });

  @override
  Widget build(BuildContext context) {
    return PokeBinderScaffold(
      floatingActionButton: _showBackToTop
          ? FloatingActionButton.small(
              tooltip: 'Back to top',
              backgroundColor: PokeBinderColors.white,
              foregroundColor: PokeBinderColors.redDeep,
              onPressed: () => _scroll.animateTo(
                0,
                duration: _kBackToTopDuration,
                curve: Curves.easeOut,
              ),
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            )
          : null,
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: PokeBinderSpacing.page,
          children: [
            ...widget.header,
            CollectionSearchBar(
              hint: 'Search by name or number (e.g. 4/102)',
              text: _query,
              onChanged: _onQueryChanged,
            ),
            if (_sets.isNotEmpty) ...[
              const SizedBox(height: PokeBinderSpacing.sp3),
              PokeSearchableDropdownField<String>(
                title: 'Choose a Set',
                searchHint: 'Search sets…',
                noMatchesTitle: 'No sets match your search.',
                value: _setId,
                icon: Icons.collections_bookmark_outlined,
                options: [
                  const PokeDropdownOption(_allSets, 'All sets',
                      icon: Icons.layers_outlined),
                  for (final set in _sets)
                    PokeDropdownOption(
                      set.id,
                      set.name,
                      subtitle: set.releaseDate?.year.toString(),
                      group: set.series.isEmpty ? null : set.series,
                    ),
                ],
                onChanged: _onSetChanged,
              ),
            ],
            const SizedBox(height: PokeBinderSpacing.sp3),
            ..._body(),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    if (!_hasCriteria) {
      return [
        const _Hint(
          icon: Icons.search_rounded,
          text: 'Type a card name or number, or choose a set to browse it.',
        ),
      ];
    }
    if (_error != null) {
      return [
        Text(_error!, style: PokeBinderText.formError),
        const SizedBox(height: PokeBinderSpacing.sp2),
        PillButton(
          label: 'Try Again',
          ghost: true,
          onTap: _runSearch,
        ),
      ];
    }
    if (_loading && _results.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(PokeBinderSpacing.sp5),
          child: Center(child: PokeballLoader(size: 44)),
        ),
      ];
    }
    if (_results.isEmpty) {
      return [
        EmptyFilterState(
          title: 'No cards matched your search.',
          subtitle: 'Check the spelling or try another set.',
          onClearFilters: _clearSearch,
        ),
      ];
    }
    final owned = widget.counts();
    final sorted = applyCatalogSort(
      cards: _results,
      sortOption: _sortOption,
      typeFilter: _typeFilter,
      subtypeFilter: _subtypeFilter,
      rarityFilter: _rarityFilter,
      timeDirection: _timeDirection,
      releaseDateOf: (card) => _releaseDates[card.setId],
      onTypeFilterChanged: (value) => _update(() => _typeFilter = value),
      onSubtypeFilterChanged: (value) => _update(() => _subtypeFilter = value),
      onRarityFilterChanged: (value) => _update(() => _rarityFilter = value),
      onTimeDirectionChanged: (value) => _update(() => _timeDirection = value),
    );
    final cards = sorted.cards;
    final ownedCards = cards.where((c) => owned.containsKey(c.id)).length;
    final inSet = _activeSetId != null;
    final remaining = cards.length - _visibleCount;
    final nextBatch = remaining < _kVisibleChunk ? remaining : _kVisibleChunk;
    return [
      if (sorted.subOptionRow != null) ...[
        sorted.subOptionRow!,
        const SizedBox(height: PokeBinderSpacing.sp2),
      ],
      Row(
        children: [
          Expanded(
            child: Text(
              'SHOWING ${cards.length} ${cards.length == 1 ? 'CARD' : 'CARDS'}'
              '${ownedCards > 0 ? ' · $ownedCards ${widget.countLabel}' : ''}',
              style: PokeBinderText.resultCount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CardSortSelector(
            selected: _sortOption,
            options: inSet
                ? [
                    for (final option in kCatalogSortOptions)
                      if (option != CardSortOption.time) option,
                  ]
                : kCatalogSortOptions,
            onChanged: (option) => _update(() {
              _sortOption = option;
              _typeFilter = _subtypeFilter = _rarityFilter = null;
            }),
          ),
        ],
      ),
      const SizedBox(height: PokeBinderSpacing.sp2),
      if (cards.isEmpty)
        EmptyFilterState(
          title: 'No cards match this filter.',
          subtitle: 'Try a different filter or sort.',
          onClearFilters: () => _update(
            () => _typeFilter = _subtypeFilter = _rarityFilter = null,
          ),
        ),
      for (final card in cards.take(_visibleCount)) ...[
        _CatalogRow(
          card: card,
          showSet: !inSet,
          owned: owned[card.id] ?? 0,
          countLabel: widget.countLabel,
          onTap: () => widget.onPick(card),
        ),
        const SizedBox(height: PokeBinderSpacing.sp2),
      ],
      if (remaining > 0)
        PillButton(
          label: 'Show $nextBatch More · $remaining Left',
          ghost: true,
          onTap: () => setState(() => _visibleCount += _kVisibleChunk),
        ),
      if (_truncated)
        Padding(
          padding: const EdgeInsets.only(top: PokeBinderSpacing.sp2),
          child: Text(
            'Only the first ${CatalogRepository.searchCap} matches are listed. '
            'Search more specifically or pick a set to see the rest.',
            style: PokeBinderText.subtitle,
          ),
        ),
    ];
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: PokeBinderColors.inkSoft),
          const SizedBox(width: PokeBinderSpacing.sp3),
          Expanded(child: Text(text, style: PokeBinderText.subtitle)),
        ],
      ),
    );
  }
}

class _CatalogRow extends StatelessWidget {
  final CatalogCard card;
  final bool showSet;
  final int owned;
  final String countLabel;
  final VoidCallback onTap;

  const _CatalogRow({
    required this.card,
    required this.showSet,
    required this.owned,
    required this.countLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = card.marketPricePhp;
    return Material(
      color: PokeBinderColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(PokeBinderSpacing.sp2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.09)),
          ),
          child: Row(
            children: [
              CardThumbnail(
                card: null,
                imageAssetPath: card.imageSmall,
                width: 44,
                height: 61,
              ),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            card.name,
                            style: PokeBinderText.rowTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (owned > 0) ...[
                          const SizedBox(width: PokeBinderSpacing.sp2),
                          _CountTag(label: countLabel, count: owned),
                        ],
                      ],
                    ),
                    const SizedBox(height: PokeBinderSpacing.sp0),
                    Text(
                      showSet
                          ? '${card.setName} · #${card.displayNumber}'
                          : '#${card.displayNumber}',
                      style: PokeBinderText.listRowSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: PokeBinderSpacing.sp1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(rarityIconFor(card.rarity),
                            size: 11, color: PokeBinderColors.goldDeep),
                        const SizedBox(width: PokeBinderSpacing.sp1),
                        Flexible(
                          child: Text(
                            card.rarityRaw ?? card.rarity,
                            style: PokeBinderText.listRowSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price == null ? '—' : formatPeso(price),
                    style: PokeBinderText.chipLabel,
                  ),
                  const SizedBox(height: PokeBinderSpacing.sp1),
                  const Icon(Icons.add_circle_outline_rounded,
                      size: 20, color: PokeBinderColors.redDeep),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountTag extends StatelessWidget {
  final String label;
  final int count;

  const _CountTag({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PokeBinderSpacing.chip,
      decoration: BoxDecoration(
        color: PokeBinderColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label ×$count',
        style: PokeBinderText.tagLabel(PokeBinderColors.teal),
      ),
    );
  }
}
