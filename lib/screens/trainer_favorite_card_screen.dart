import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_sort_controls.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

/// Lets the user pick a single card from their collection to feature as
/// their trainer card's favorite — the same search/filter/sort experience,
/// row layout, and tap-to-view-details behavior as [DeckAddCardScreen],
/// [TradeListAddCardScreen], and the wishlist's add screen, but a single
/// selection instead of per-card quantities.
class TrainerFavoriteCardScreen extends StatefulWidget {
  final String? initialCardId;

  const TrainerFavoriteCardScreen({super.key, this.initialCardId});

  @override
  State<TrainerFavoriteCardScreen> createState() =>
      _TrainerFavoriteCardScreenState();
}

class _TrainerFavoriteCardScreenState
    extends State<TrainerFavoriteCardScreen> {
  late String? _selectedCardId = widget.initialCardId;

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

  void _resetSubFilters() {
    _typeFilter = null;
    _subtypeFilter = null;
    _setFilter = null;
    _rarityFilter = null;
    _conditionFilter = null;
  }

  void _select(PokemonCardData card) {
    setState(() {
      _selectedCardId = _selectedCardId == card.id ? null : card.id;
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
        if (_selectedCardId == oldCard.id) _selectedCardId = null;
      } else {
        PokemonCardData.library[index] = result.card!;
        if (_selectedCardId == oldCard.id && result.card!.quantityOwned <= 0) {
          _selectedCardId = null;
        }
      }
    });
  }

  void _done() => Navigator.of(context).pop(_selectedCardId);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BackLink(onTap: () => Navigator.of(context).maybePop()),
                  if (_selectedCardId != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _selectedCardId = null),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text('Clear', style: PokeBinderText.backLink),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Choose Favorite Card', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Pick a card from your collection to feature on your '
                'trainer card.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              CollectionSearchBar(
                hint: 'Search your binders for a card…',
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
                    '${filtered.length} CARD${filtered.length == 1 ? '' : 'S'} FOUND',
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
                              return _FavoriteCardPickerRow(
                                card: card,
                                selected: card.id == _selectedCardId,
                                onSelect: () => _select(card),
                                onTapCard: () => _openCardDetails(card),
                              );
                            },
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              PillButton(
                label: 'Done',
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

class _FavoriteCardPickerRow extends StatelessWidget {
  final PokemonCardData card;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onTapCard;

  const _FavoriteCardPickerRow({
    required this.card,
    required this.selected,
    required this.onSelect,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
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
                            'Own ${card.quantityOwned}',
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
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSelect,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 22,
                  color: selected
                      ? PokeBinderColors.redDeep
                      : PokeBinderColors.inkSoft.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Second line of extra card info shown under the "Own …" line: condition,
/// binder location, and estimated value, matching the icon+label tags used
/// on the Deck Details, Wishlist, and Trade List card rows so the same
/// fields read the same way everywhere in the app.
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