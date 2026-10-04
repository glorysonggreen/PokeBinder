import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/binder_data.dart';
import '../models/catalog_card.dart';
import '../models/pokemon_card_data.dart';
import '../services/binder_repository.dart';
import '../services/card_repository.dart';
import '../services/catalog_repository.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokebinder_form_fields.dart';
import '../widgets/pokemon_card_widget.dart';
import 'card_form_screen.dart';

/// Puts a card the person just confirmed in the form into their collection:
/// grows the binder if the card sits on a page past its end, adds it to
/// [PokemonCardData.library] and saves it to the database.
///
/// Shared by every "add a new card" entry point so they all behave the same.
void saveNewCard(CardFormResult result) {
  final card = result.card!;
  _growBinderIfNeeded(result.binderId!, result.pageIndex!);
  PokemonCardData.library.add(card);
  CardRepository.upsert(card);
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
  bool _loading = false;
  bool _hasMore = false;
  String? _error;

  /// Bumped for every new search so a slow, older response can't overwrite
  /// the results of a newer one.
  int _searchToken = 0;

  bool get _hasCriteria => _query.trim().isNotEmpty || _setId != _allSets;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSets() async {
    try {
      final sets = await CatalogRepository.loadSets();
      if (!mounted) return;
      setState(() => _sets = sets);
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
    setState(() => _setId = id);
    _runSearch();
  }

  String? get _activeSetId => _setId == _allSets ? null : _setId;

  Future<void> _runSearch() async {
    final token = ++_searchToken;
    if (!_hasCriteria) {
      setState(() {
        _results = [];
        _hasMore = false;
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
      final cards = await CatalogRepository.search(
        query: _query,
        setId: _activeSetId,
      );
      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = cards;
        _hasMore = cards.length == CatalogRepository.pageSize;
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

  Future<void> _loadMore() async {
    final token = _searchToken;
    setState(() => _loading = true);
    try {
      final more = await CatalogRepository.search(
        query: _query,
        setId: _activeSetId,
        offset: _results.length,
      );
      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = [..._results, ...more];
        _hasMore = more.length == CatalogRepository.pageSize;
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
    saveNewCard(result);
    widget.onCardAdded();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${result.card!.name} to your collection.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: ListView(
          padding: PokeBinderSpacing.page,
          children: [
            Text('ADD A CARD', style: PokeBinderText.eyebrow),
            const SizedBox(height: PokeBinderSpacing.sp2),
            Text('Find your card', style: PokeBinderText.heading),
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
              PokeDropdownField<String>(
                value: _setId,
                icon: Icons.collections_bookmark_outlined,
                options: [
                  const PokeDropdownOption(_allSets, 'All sets',
                      icon: Icons.layers_outlined),
                  for (final set in _sets) PokeDropdownOption(set.id, set.name),
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
          onTap: _results.isEmpty ? _runSearch : _loadMore,
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
    return [
      for (final card in _results) ...[
        _CatalogRow(card: card, onTap: () => _pick(card)),
        const SizedBox(height: PokeBinderSpacing.sp2),
      ],
      if (_hasMore)
        _loading
            ? const Padding(
                padding: EdgeInsets.all(PokeBinderSpacing.sp3),
                child: Center(child: CircularProgressIndicator()),
              )
            : PillButton(label: 'Show More', ghost: true, onTap: _loadMore),
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
/// suggested price.
class _CatalogRow extends StatelessWidget {
  final CatalogCard card;
  final VoidCallback onTap;

  const _CatalogRow({required this.card, required this.onTap});

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
                    Text(
                      card.name,
                      style: PokeBinderText.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: PokeBinderSpacing.sp0),
                    Text(
                      '${card.setName} · #${card.displayNumber}',
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
                    price == null ? '—' : '₱${price.toStringAsFixed(0)}',
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
