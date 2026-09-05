import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_sort_controls.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

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

  final List<BinderData> _binders = BinderData.sampleBinders;

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

  Future<void> _openCardDetails(PokemonCardData card) async {
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

  void _handleCardSaved(PokemonCardData oldCard, CardFormResult result) {
    setState(() {
      final index =
          PokemonCardData.library.indexWhere((c) => c.id == oldCard.id);
      if (index == -1) return;
      if (result.deleted) {
        PokemonCardData.library.removeAt(index);
        _quantities.remove(oldCard.id);
      } else {
        PokemonCardData.library[index] = result.card!;
        final owned = result.card!.quantityOwned;
        final picked = _quantities[oldCard.id];
        if (picked != null && picked > owned) {
          if (owned <= 0) {
            _quantities.remove(oldCard.id);
          } else {
            _quantities[oldCard.id] = owned;
          }
        }
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
                              indent: 82,
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
                                onTapCard: () => _openCardDetails(card),
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
  final VoidCallback onTapCard;

  const _DeckCardPickerRow({
    required this.card,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;

    return Container(
      color: selected
          ? PokeBinderColors.red.withValues(alpha: 0.045)
          : Colors.transparent,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTapCard,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: kCardElevation,
                      ),
                      child: CardThumbnail(
                          card: card, width: 56, height: 78, borderRadius: 5),
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
                          const SizedBox(height: 3),
                          Text(
                            '${card.setName} · #${card.cardNumber} · ${card.rarity}',
                            style: PokeBinderText.listRowSubtitle
                                .copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selected
                                ? 'Own ${card.quantityOwned} · $quantity In Deck'
                                : 'Own ${card.quantityOwned}',
                            style: PokeBinderText.listRowSubtitle.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: PokeBinderColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _CardMetaRow(card: card),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

/// Second line of extra card info shown under the "Own …" line: condition,
/// binder location, and estimated value, matching the icon+label tags used
/// on the Deck Details and Wishlist card rows so the same fields read the
/// same way everywhere in the app.
class _CardMetaRow extends StatelessWidget {
  final PokemonCardData card;

  const _CardMetaRow({required this.card});

  @override
  Widget build(BuildContext context) {
    final metaStyle = PokeBinderText.listRowSubtitle.copyWith(fontSize: 9);
    return Wrap(
      spacing: 7,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (card.condition.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(conditionIconFor(card.condition),
                  size: 11, color: PokeBinderColors.teal),
              const SizedBox(width: 3),
              Text(
                kConditionOptions
                    .firstWhere((c) => c.$2 == card.condition,
                        orElse: () => (card.condition, card.condition))
                    .$1,
                style: metaStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: PokeBinderColors.teal,
                ),
              ),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 11, color: PokeBinderColors.inkSoft),
            const SizedBox(width: 3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 90),
              child: Text(
                card.binderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: metaStyle,
              ),
            ),
          ],
        ),
        if (card.estimatedValue > 0)
          Text(
            '\$${card.estimatedValue.toStringAsFixed(0)}',
            style: metaStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: PokeBinderColors.goldDeep,
            ),
          ),
      ],
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
          Icon(
            Icons.search_off_rounded,
            size: 26,
            color: PokeBinderColors.inkSoft.withValues(alpha: 0.4),
          ),
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