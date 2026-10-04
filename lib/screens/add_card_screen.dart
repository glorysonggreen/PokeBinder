import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/pricing.dart';
import '../models/binder_data.dart';
import '../models/catalog_card.dart';
import '../models/pokemon_card_data.dart';
import '../services/binder_repository.dart';
import '../services/card_repository.dart';
import '../services/catalog_repository.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_sort_controls.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import '../widgets/pokemon_card_widget.dart';
import 'card_form_screen.dart';

/// Puts a card the person just confirmed in the form into their collection:
/// grows the binder if the card sits on a page past its end, adds it to
/// [PokemonCardData.library] and saves it to the database.
///
/// If the form returned a card that is already in the library (the "add to
/// your existing copy" shortcut), that entry is updated instead of adding a
/// second one.
///
/// Shared by every "add a new card" entry point so they all behave the same.
///
/// Returns the entry that was replaced when the card was already in the
/// library, or null when it is new — callers use that to offer Undo.
PokemonCardData? saveNewCard(CardFormResult result) {
  final card = result.card!;
  final library = PokemonCardData.library;
  final index = library.indexWhere((c) => c.id == card.id);
  PokemonCardData? replaced;
  if (index == -1) {
    _growBinderIfNeeded(result.binderId!, result.pageIndex!);
    library.add(card);
  } else {
    replaced = library[index];
    library[index] = card;
  }
  CardRepository.upsert(card);
  return replaced;
}

void _growBinderIfNeeded(String binderId, int pageIndex) {
  if (binderId == kUnassignedBinderId) return;
  final binders = BinderData.library;
  final index = binders.indexWhere((b) => b.id == binderId);
  if (index == -1) return;
  final binder = binders[index];
  if (pageIndex >= binder.pageCount) {
    binders[index] = binder.copyWith(pageCount: pageIndex + 1);
    BinderRepository.upsert(binders[index]);
  }
}


/// Turns a failed catalog request into something the person (or whoever sets
/// the project up) can act on, instead of always blaming the connection.
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

/// How many results are drawn before "Show more" reveals the next batch.
const int _kVisibleChunk = 30;

/// How far the list scrolls before the back-to-top button appears.
const double _kBackToTopOffset = 600;

const Duration _kBackToTopDuration = Duration(milliseconds: 300);

/// The "Add" tab. The person searches the card database, taps a card, and
/// confirms the details of their own copy (condition, quantity, binder…).
/// The card's name, set, number, rarity, artwork and suggested price come from
/// the database, so they can't be mistyped.
///
/// A card that isn't in the database (a promo, a custom card, a card from a
/// newer set) can still be added by hand from the link at the bottom.
class AddCardScreen extends StatefulWidget {
  /// Called after a card has been added so other tabs can refresh.
  final VoidCallback onCardAdded;

  const AddCardScreen({super.key, required this.onCardAdded});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  /// Dropdown value meaning "no set filter".
  static const _allSets = '';

  Timer? _debounce;
  String _query = '';
  String _setId = _allSets;
  List<CatalogSet> _sets = const [];
  List<CatalogCard> _results = [];
  Map<String, DateTime?> _releaseDates = const {};
  bool _loading = false;

  /// True when a name search hit [CatalogRepository.searchCap], so more cards
  /// match than are listed.
  bool _truncated = false;
  String? _error;

  // Sort and filter of the results (applied on the device).
  CardSortOption _sortOption = CardSortOption.alphabetical;
  TimeSortDirection _timeDirection = TimeSortDirection.newest;
  PokemonCardType? _typeFilter;
  String? _subtypeFilter;
  String? _rarityFilter;

  /// How many of the sorted results are drawn.
  int _visibleCount = _kVisibleChunk;

  final _scroll = ScrollController();
  bool _showBackToTop = false;

  /// Bumped for every new search so a slow, older response can't overwrite
  /// the results of a newer one.
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
    } catch (_) {
      // The set filter simply stays hidden; searching by name still works.
    }
  }

  void _onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  void _onSetChanged(String id) {
    setState(() {
      _setId = id;
      _results = [];
      // A set reads best in printed order; a name search, alphabetically.
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
    try {
      final setId = _activeSetId;
      final List<CatalogCard> cards;
      if (setId == null) {
        cards = await CatalogRepository.search(query: _query);
      } else {
        // The whole set, in printed order — no paging, instant filtering.
        final all = await CatalogRepository.loadSet(setId);
        cards = CatalogRepository.filterCards(all, _query);
      }
      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = cards;
        _truncated =
            setId == null && cards.length == CatalogRepository.searchCap;
        _visibleCount = _kVisibleChunk;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _loading = false;
        _error = _catalogErrorMessage(e);
      });
    }
  }

  /// Applies a sort / filter change and starts again from the first batch.
  void _update(VoidCallback change) => setState(() {
        change();
        _visibleCount = _kVisibleChunk;
      });

  Future<void> _pick(CatalogCard card) async {
    final result = await Navigator.of(context).push<CardFormResult>(
      MaterialPageRoute(
        builder: (_) => CardFormScreen(
          catalogCard: card,
          binders: BinderData.library,
          defaultBinderId: kUnassignedBinderId,
        ),
      ),
    );
    _handleResult(result);
  }

  Future<void> _addManually() async {
    final result = await Navigator.of(context).push<CardFormResult>(
      MaterialPageRoute(
        builder: (_) => CardFormScreen(
          binders: BinderData.library,
          defaultBinderId: kUnassignedBinderId,
        ),
      ),
    );
    _handleResult(result);
  }

  void _handleResult(CardFormResult? result) {
    if (!mounted || result == null || result.deleted || result.card == null) {
      return;
    }
    final card = result.card!;
    final replaced = saveNewCard(result);
    setState(() {});
    widget.onCardAdded();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          replaced == null
              ? 'Added ${card.name} to your collection.'
              : 'Now you own ${card.quantityOwned} of ${card.name}.',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _undoAdd(card, replaced),
        ),
      ),
    );
  }

  /// Takes back [_handleResult]: removes a card that was just added, or puts
  /// an entry whose quantity was raised back to how it was.
  void _undoAdd(PokemonCardData card, PokemonCardData? replaced) {
    final library = PokemonCardData.library;
    if (replaced == null) {
      library.removeWhere((c) => c.id == card.id);
      CardRepository.delete(card.id);
    } else {
      final index = library.indexWhere((c) => c.id == card.id);
      if (index != -1) library[index] = replaced;
      CardRepository.upsert(replaced);
    }
    if (mounted) {
      setState(() {});
      widget.onCardAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
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
            Text('ADD A CARD', style: PokeBinderText.eyebrow),
            const SizedBox(height: PokeBinderSpacing.sp2),
            Text('Find Your Card', style: PokeBinderText.heading),
            const SizedBox(height: PokeBinderSpacing.sp2),
            Text(
              'Pick it from the card database so the name, set, artwork and '
              'price are always correct.',
              style: PokeBinderText.subtitle,
            ),
            const SizedBox(height: PokeBinderSpacing.sp4),
            CollectionSearchBar(
              hint: 'Search by name or number (e.g. 4/102)',
              onChanged: _onQueryChanged,
            ),
            if (_sets.isNotEmpty) ...[
              const SizedBox(height: PokeBinderSpacing.sp2),
              PokeSearchableDropdownField<String>(
                title: 'Choose a set',
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
            const SizedBox(height: PokeBinderSpacing.sp4),
            ..._body(),
            const SizedBox(height: PokeBinderSpacing.sp5),
            Row(
              children: [
                Text('NOT IN THE DATABASE?', style: PokeBinderText.sectionLabel),
                const SizedBox(width: PokeBinderSpacing.sp2),
                Expanded(
                  child: Divider(
                    color: PokeBinderColors.ink.withValues(alpha: 0.08),
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: PokeBinderSpacing.sp2),
            Text(
              'Promos, custom cards and brand-new sets may be missing. You '
              'can enter those yourself.',
              style: PokeBinderText.subtitle,
            ),
            const SizedBox(height: PokeBinderSpacing.sp3),
            PillButton(
              label: 'Add a Card Manually',
              icon: Icons.edit_outlined,
              ghost: true,
              onTap: _addManually,
            ),
          ],
        ),
      ),
    );
  }

  /// How many copies of each catalog card the person already owns.
  Map<String, int> _ownedByCatalogId() {
    final owned = <String, int>{};
    for (final card in PokemonCardData.library) {
      final id = card.catalogId;
      if (id != null) owned[id] = (owned[id] ?? 0) + card.quantityOwned;
    }
    return owned;
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
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_results.isEmpty) {
      return const [
        _Hint(
          icon: Icons.search_off_rounded,
          text: 'No cards matched. Check the spelling, try another set, or '
              'add the card manually below.',
        ),
      ];
    }
    final owned = _ownedByCatalogId();
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
      if (sorted.subOptionRow != null) sorted.subOptionRow!,
      Row(
        children: [
          Expanded(
            child: Text(
              'SHOWING ${cards.length} ${cards.length == 1 ? 'CARD' : 'CARDS'}'
              '${ownedCards > 0 ? ' · $ownedCards OWNED' : ''}',
              style: PokeBinderText.resultCount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CardSortSelector(
            selected: _sortOption,
            // Time orders by set release date, so it means nothing inside one set.
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
        const _Hint(
          icon: Icons.filter_alt_off_outlined,
          text: 'No cards match this filter. Pick "All" above or change the '
              'sort.',
        ),
      for (final card in cards.take(_visibleCount)) ...[
        _CatalogRow(
          card: card,
          showSet: !inSet,
          owned: owned[card.id] ?? 0,
          onTap: () => _pick(card),
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

/// One search result: small artwork, name, `set · #number`, rarity, and the
/// suggested price. [showSet] is off when the list is already one set's, and
/// [owned] is how many copies the person has (0 hides the tag).
class _CatalogRow extends StatelessWidget {
  final CatalogCard card;
  final bool showSet;
  final int owned;
  final VoidCallback onTap;

  const _CatalogRow({
    required this.card,
    required this.showSet,
    required this.owned,
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
                          _OwnedTag(count: owned),
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

/// "OWNED ×2" next to a card's name.
class _OwnedTag extends StatelessWidget {
  final int count;

  const _OwnedTag({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PokeBinderSpacing.chip,
      decoration: BoxDecoration(
        color: PokeBinderColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'OWNED ×$count',
        style: PokeBinderText.tagLabel(PokeBinderColors.teal),
      ),
    );
  }
}
