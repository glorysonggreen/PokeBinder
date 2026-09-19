import 'package:flutter/material.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_sort_controls.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';

/// One card the user picked in [BinderAddCardScreen], and how many of its
/// copies should be moved into the binder.
@immutable
class BinderCardPick {
  final String cardId;
  final int quantity;

  const BinderCardPick({required this.cardId, required this.quantity});
}

/// Lets the user pick cards straight out of their collection to place in a
/// binder, the same way the Deck Planner's add-cards screen lets them pick cards for a deck:
/// search/filter/sort the collection, step a quantity up or down per card,
/// and confirm once at the bottom.
///
/// Unlike a deck (which just references cards), a card lives in exactly one
/// place, so picking a card *moves* it here from wherever it's stored now.
/// The stepper controls how many copies move; picking fewer than the owned
/// count leaves the remaining copies where they were.
class BinderAddCardScreen extends StatefulWidget {
  final String binderName;

  /// Zero-based page the cards will be placed on.
  final int pageIndex;

  /// Cards that can be added: the whole collection minus whatever is already
  /// in this binder. A function (not a list) so it always reflects the live
  /// collection, e.g. after a card is edited from the details screen.
  final List<PokemonCardData> Function() availableCards;

  /// Opens the card's details screen. The owner performs the actual edit;
  /// this screen re-reads [availableCards] when it returns.
  final Future<void> Function(PokemonCardData card) onCardTap;

  const BinderAddCardScreen({
    super.key,
    required this.binderName,
    required this.pageIndex,
    required this.availableCards,
    required this.onCardTap,
  });

  @override
  State<BinderAddCardScreen> createState() => _BinderAddCardScreenState();
}

class _BinderAddCardScreenState extends State<BinderAddCardScreen> {
  final Map<String, int> _quantities = {};

  String _query = '';
  CardSortOption _sortOption = CardSortOption.alphabetical;
  PokemonCardType? _typeFilter;
  String? _subtypeFilter;
  String? _setFilter;
  String? _rarityFilter;
  String? _conditionFilter;
  TimeSortDirection _timeDirection = TimeSortDirection.newest;

  List<PokemonCardData> get _candidateCards =>
      widget.availableCards().where((c) => c.quantityOwned > 0).toList();

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
    await widget.onCardTap(card);
    if (!mounted) return;
    setState(_reconcileSelections);
  }

  /// After a card was edited elsewhere, drop or shrink any pick that no
  /// longer makes sense (card deleted, moved into this binder, or fewer
  /// copies owned than were selected).
  void _reconcileSelections() {
    final owned = {
      for (final card in widget.availableCards()) card.id: card.quantityOwned,
    };
    for (final id in _quantities.keys.toList()) {
      final max = owned[id] ?? 0;
      if (max <= 0) {
        _quantities.remove(id);
      } else if (_quantities[id]! > max) {
        _quantities[id] = max;
      }
    }
  }

  void _done() {
    final picks = [
      for (final entry in _quantities.entries)
        if (entry.value > 0)
          BinderCardPick(cardId: entry.key, quantity: entry.value),
    ];
    Navigator.of(context).pop(picks);
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidateCards;
    final result = applyCardSort(
      cards: candidates,
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
    final total = _totalSelected;

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
                'Search your collection for cards to add to page '
                '${widget.pageIndex + 1} of "${widget.binderName}". '
                "They'll move here from where they're stored now.",
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
                    '${total > 0 ? ' · $total TO ADD' : ''}',
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
                    ? _EmptyResults(
                        message: candidates.isEmpty
                            ? 'Every card in your collection is already in '
                                'this binder.'
                            : 'No cards match your search.',
                      )
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
                              return _BinderCardPickerRow(
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
                label: total == 0
                    ? 'Select cards to add'
                    : 'Add $total card${total == 1 ? '' : 's'}',
                icon: Icons.check,
                enabled: total > 0,
                onTap: total > 0 ? _done : () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BinderCardPickerRow extends StatelessWidget {
  final PokemonCardData card;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onTapCard;

  const _BinderCardPickerRow({
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
      padding: const EdgeInsets.all(PokeBinderSpacing.sp3),
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
                            style: PokeBinderText.rowTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: PokeBinderSpacing.sp1),
                          Text(
                            '${card.setName} · #${card.cardNumber} · ${card.rarity}',
                            style: PokeBinderText.listRowSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: PokeBinderSpacing.sp0),
                          Text(
                            selected
                                ? 'Own ${card.quantityOwned} · Adding $quantity'
                                : 'Own ${card.quantityOwned}',
                            style: PokeBinderText.listRowSubtitle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: PokeBinderColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: PokeBinderSpacing.sp1),
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
    final metaStyle = PokeBinderText.listRowSubtitle;
    return Wrap(
      spacing: PokeBinderSpacing.sp2,
      runSpacing: PokeBinderSpacing.sp0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (card.condition.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(conditionIconFor(card.condition),
                  size: 11, color: PokeBinderColors.teal),
              const SizedBox(width: PokeBinderSpacing.sp1),
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
            const SizedBox(width: PokeBinderSpacing.sp1),
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
      padding: const EdgeInsets.symmetric(horizontal: PokeBinderSpacing.sp0),
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
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: PokeBinderText.quantityLabel(active: quantity > 0),
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
          padding: const EdgeInsets.all(PokeBinderSpacing.sp1),
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
  final String message;

  const _EmptyResults({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PokeBinderSpacing.sp4),
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
              message,
              textAlign: TextAlign.center,
              style: PokeBinderText.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}