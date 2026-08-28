import 'package:flutter/material.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_sort_controls.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';

class DeckAddCardScreen extends StatefulWidget {
  final String deckName;
  final List<DeckCardEntry> initialEntries;

  const DeckAddCardScreen({
    super.key,
    required this.deckName,
    required this.initialEntries,
  });

  @override
  State<DeckAddCardScreen> createState() => _DeckAddCardScreenState();
}

class _DeckAddCardScreenState extends State<DeckAddCardScreen> {
  late final Map<String, int> _quantities = {
    for (final entry in widget.initialEntries) entry.cardId: entry.quantity,
  };

  String _query = '';
  CardSortOption _sortOption = CardSortOption.alphabetical;
  PokemonCardType? _typeFilter;
  String? _subtypeFilter;
  String? _setFilter;
  String? _rarityFilter;
  String? _conditionFilter;
  TimeSortDirection _timeDirection = TimeSortDirection.newest;

  List<PokemonCardData> get _ownedCards =>
      PokemonCardData.library.where((c) => c.quantityOwned > 0).toList();

  int get _totalSelected => _quantities.values.fold(0, (sum, q) => sum + q);

  void _resetSubFilters() {
    _typeFilter = null;
    _subtypeFilter = null;
    _setFilter = null;
    _rarityFilter = null;
    _conditionFilter = null;
  }

  void _increment(PokemonCardData card) {
    setState(() {
      final current = _quantities[card.id] ?? 0;
      if (current < card.quantityOwned) {
        _quantities[card.id] = current + 1;
      }
    });
  }

  void _decrement(String cardId) {
    setState(() {
      final next = (_quantities[cardId] ?? 0) - 1;
      if (next <= 0) {
        _quantities.remove(cardId);
      } else {
        _quantities[cardId] = next;
      }
    });
  }

  void _done() {
    final entries = [
      for (final entry in _quantities.entries)
        DeckCardEntry(cardId: entry.key, quantity: entry.value),
    ];
    Navigator.of(context).pop(entries);
  }

  @override
  Widget build(BuildContext context) {
    final result = applyCardSort(
      cards: _ownedCards,
      search: _query,
      sortOption: _sortOption,
      typeFilter: _typeFilter,
      subtypeFilter: _subtypeFilter,
      setFilter: _setFilter,
      rarityFilter: _rarityFilter,
      conditionFilter: _conditionFilter,
      timeDirection: _timeDirection,
      onTypeFilterChanged: (v) => setState(() => _typeFilter = v),
      onSubtypeFilterChanged: (v) => setState(() => _subtypeFilter = v),
      onSetFilterChanged: (v) => setState(() => _setFilter = v),
      onRarityFilterChanged: (v) => setState(() => _rarityFilter = v),
      onConditionFilterChanged: (v) => setState(() => _conditionFilter = v),
      onTimeDirectionChanged: (v) => setState(() => _timeDirection = v),
    );
    final filtered = result.cards;
    final subOptionRow = result.subOptionRow;

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Add Cards', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Search your collection for cards to add to '
                '"${widget.deckName}".',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              CollectionSearchBar(
                hint: 'Search your binders for a card to add…',
                onChanged: (value) => setState(() => _query = value),
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
                    '${filtered.length} CARD${filtered.length == 1 ? '' : 'S'} FOUND'
                    '${_totalSelected > 0 ? ' · $_totalSelected IN DECK' : ''}',
                    style: PokeBinderText.resultCount,
                  ),
                  CardSortSelector(
                    selected: _sortOption,
                    onChanged: (option) => setState(() {
                      _sortOption = option;
                      _resetSubFilters();
                      _timeDirection = TimeSortDirection.newest;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),

              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyResults()
                    : Container(
                        decoration: BoxDecoration(
                          color: PokeBinderColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: PokeBinderColors.ink.withValues(alpha: 0.08)),
                          boxShadow: kCardElevation,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              thickness: 1,
                              indent: 62,
                              color: PokeBinderColors.ink.withValues(alpha: 0.06),
                            ),
                            itemBuilder: (context, index) {
                              final card = filtered[index];
                              final quantity = _quantities[card.id] ?? 0;
                              final atMax = quantity >= card.quantityOwned;
                              return _DeckCardPickerRow(
                                card: card,
                                quantity: quantity,
                                onIncrement: atMax ? null : () => _increment(card),
                                onDecrement: () => _decrement(card.id),
                              );
                            },
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              PillButton(
                label: _totalSelected == 0
                    ? 'Done'
                    : 'Done · $_totalSelected card${_totalSelected == 1 ? '' : 's'}',
                icon: Icons.check,
                onTap: _done,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckCardPickerRow extends StatelessWidget {
  final PokemonCardData card;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;

  const _DeckCardPickerRow({
    required this.card,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;

    return Container(
      color: selected
          ? PokeBinderColors.red.withValues(alpha: 0.045)
          : Colors.transparent,
      padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: kCardElevation,
            ),
            child: CardThumbnail(card: card, width: 40, height: 56, borderRadius: 8),
          ),
          const SizedBox(width: PokeBinderSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: PokeBinderColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${card.setName} · own ${card.quantityOwned}'
                  '${selected ? ' · $quantity in deck' : ''}',
                  style: PokeBinderText.listRowSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: PokeBinderSpacing.sp2),
          _QuantityStepper(
            quantity: quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: PokeBinderColors.cream2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: quantity > 0 ? onDecrement : null,
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: PokeBinderText.chakraPetch(TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: quantity > 0
                    ? PokeBinderColors.redDeep
                    : PokeBinderColors.inkSoft,
              )),
            ),
          ),
          _StepperButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 14,
            color: onTap != null
                ? PokeBinderColors.redDeep
                : PokeBinderColors.inkSoft.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 22)),
          const SizedBox(height: PokeBinderSpacing.sp2),
          Text(
            'No cards match your search.',
            textAlign: TextAlign.center,
            style: PokeBinderText.subtitle,
          ),
        ],
      ),
    );
  }
}
