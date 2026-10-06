import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../services/deck_repository.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/interactive_3d_card.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'card_form_screen.dart';
import 'deck_form_screen.dart';
import '../services/audio_service.dart';
import '../widgets/pokebinder_background.dart';
import '../widgets/pokebinder_toast.dart';

class CardDetailsScreen extends StatefulWidget {
  final PokemonCardData card;
  final List<BinderData> binders;
  final void Function(PokemonCardData oldCard, CardFormResult result) onSave;

  const CardDetailsScreen({
    super.key,
    required this.card,
    required this.binders,
    required this.onSave,
  });

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  late PokemonCardData _card = widget.card;

  @override
  void initState() {
    super.initState();

    PokeBinderAudio.play(
      Sfx.cardDeal,
      delay: const Duration(milliseconds: 160),
    );
    if (isChaseRarity(widget.card.rarity)) {
      PokeBinderAudio.play(
        Sfx.rare,
        delay: const Duration(milliseconds: 650),
      );
    }
  }

  Future<void> _editCard() async {
    final currentBinder = widget.binders.firstWhere(
      (b) => b.name == _card.binderName,
      orElse: () => widget.binders.isEmpty
          ? const BinderData(
              id: kUnassignedBinderId,
              name: kUnassignedBinderName,
              pageCount: 0,
            )
          : widget.binders.first,
    );

    final result = await Navigator.of(context).push<CardFormResult>(
      MaterialPageRoute(
        builder: (_) => CardFormScreen(
          existingCard: _card,
          binders: widget.binders,
          defaultBinderId: currentBinder.id,
          defaultPageNumber: _card.page,
        ),
      ),
    );
    if (result == null) return;

    widget.onSave(_card, result);

    if (result.deleted) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _card = result.card!);
    PokeBinderAudio.play(Sfx.save);

    if (mounted) {
      PokeBinderToast.show(
        context,
        'Saved changes to ${result.card!.name}',
        kind: ToastKind.success,
      );
    }
  }

  Future<void> _addToDeck() async {
    if (_card.quantityOwned <= 0) {
      PokeBinderAudio.play(Sfx.error);
      PokeBinderToast.show(
        context,
        "You don't own any copies of ${_card.name} to add.",
        kind: ToastKind.warning,
      );
      return;
    }

    final result = await showModalBottomSheet<_AddToDeckSheetResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddToDeckSheet(card: _card),
    );
    if (result == null || !mounted) return;

    if (result.createNew) {
      final newDeck = await Navigator.of(context).push<DeckData>(
        MaterialPageRoute(builder: (_) => const DeckFormScreen()),
      );
      if (newDeck == null || !mounted) return;
      DeckData.library.add(newDeck);
      _applyCardToDeck(newDeck, 1);
      return;
    }

    if (result.deck != null) {
      _applyCardToDeck(result.deck!, result.quantity);
    }
  }

  void _applyCardToDeck(DeckData deck, int quantity) {
    final index = DeckData.library.indexWhere((d) => d.id == deck.id);
    if (index == -1) return;

    final cards = [...DeckData.library[index].cards];
    final entryIndex = cards.indexWhere((c) => c.cardId == _card.id);
    if (entryIndex == -1) {
      cards.add(DeckCardEntry(cardId: _card.id, quantity: quantity));
    } else {
      cards[entryIndex] = cards[entryIndex].copyWith(quantity: quantity);
    }
    DeckData.library[index] = DeckData.library[index].copyWith(cards: cards);
    DeckRepository.upsert(DeckData.library[index]);
    PokeBinderAudio.play(Sfx.cardMove);

    if (!mounted) return;
    PokeBinderToast.show(
      context,
      '${_card.name} · $quantity in "${deck.name}"',
      kind: ToastKind.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;

    return PokeBinderScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: PokeBinderSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('CARD DETAILS', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp4),
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = math.min(
                      constraints.maxWidth * kPokemonCardWidthFraction,
                      kPokemonCardMaxWidth,
                    );
                    final cardHeight = cardWidth / kPokemonCardImageAspectRatio;
                    final bufferWidth =
                        cardWidth * kCardInteractionHeightBuffer;
                    final bufferHeight =
                        cardHeight * kCardInteractionHeightBuffer;

                    return ClipRect(
                      child: SizedBox(
                        width: bufferWidth,
                        height: bufferHeight,
                        child: Center(
                          child: SizedBox(
                            width: cardWidth,
                            height: cardHeight,
                            child: CardDealIn(
                              child: Interactive3DCard(
                                back: const PokemonCardBack(),
                                child: PokemonCard(card: card),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),
              FadeSlideIn(
                index: 1,
                child: Text(card.name, style: PokeBinderText.heading),
              ),
              const SizedBox(height: PokeBinderSpacing.sp1),
              FadeSlideIn(
                index: 2,
                child: Text(
                  '${card.setName} · #${card.cardNumber} · ${card.rarity}',
                  style: PokeBinderText.subtitle,
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),
              FadeSlideIn(
                index: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: _FieldTile(
                        label: 'Qty owned',
                        value: '${card.quantityOwned}',
                      ),
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp2),
                    Expanded(
                      child: _FieldTile(
                        label: 'Condition',
                        value: card.condition,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              FadeSlideIn(
                index: 4,
                child: Row(
                  children: [
                    Expanded(
                      child: _FieldTile(
                        label: 'Binder',
                        value: card.binderName,
                      ),
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp2),
                    Expanded(
                      child: _FieldTile(label: 'Page', value: '${card.page}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              FadeSlideIn(
                index: 5,
                child: _StatBox(
                  label: 'EST. MARKET VALUE',
                  value: '₱${card.estimatedValue.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              if (card.notes.isNotEmpty)
                _FieldTile(
                  label: 'Notes',
                  value: card.notes,
                  minHeight: 42,
                  stacked: true,
                ),
              const SizedBox(height: PokeBinderSpacing.sp4),
              FadeSlideIn(
                index: 6,
                child: Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        ghost: true,
                        onTap: _editCard,
                      ),
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp2),
                    Expanded(
                      child: PillButton(
                        label: 'Add to Deck',
                        icon: Icons.add,
                        onTap: _addToDeck,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final double? minHeight;
  final bool stacked;

  const _FieldTile({
    required this.label,
    required this.value,
    this.minHeight,
    this.stacked = false,
  });

  IconData? get _icon {
    switch (label.toLowerCase()) {
      case 'qty owned':
        return Icons.style_outlined;
      case 'condition':
        return Icons.verified_outlined;
      case 'binder':
        return Icons.menu_book_outlined;
      case 'page':
        return Icons.bookmark_outline_rounded;
      case 'notes':
        return Icons.sticky_note_2_outlined;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _icon;

    return Container(
      constraints: minHeight != null
          ? BoxConstraints(minHeight: minHeight!)
          : null,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp3,
        vertical: PokeBinderSpacing.sp3,
      ),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: PokeBinderColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 13, color: PokeBinderColors.redDeep),
                      const SizedBox(width: PokeBinderSpacing.sp1),
                    ],
                    Text(
                      label.toUpperCase(),
                      style: PokeBinderText.fieldLabel.copyWith(
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp1),
                Text(
                  value,
                  style: PokeBinderText.fieldValue.copyWith(height: 1.35),
                ),
              ],
            )
          : Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: PokeBinderColors.redDeep.withValues(alpha: 0.7)),
                  const SizedBox(width: PokeBinderSpacing.sp1),
                ],
                Text(
                  label,
                  style: PokeBinderText.fieldLabel.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(value, style: PokeBinderText.fieldValue),
              ],
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PokeBinderColors.white, Color(0xFFFCE9E4)],
        ),
        boxShadow: [
          BoxShadow(
            color: PokeBinderColors.redDeep.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: PokeBinderColors.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 62,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [PokeBinderColors.red, PokeBinderColors.redDeep],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PokeBinderSpacing.sp3,
                vertical: PokeBinderSpacing.sp3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: PokeBinderText.statLabel),
                        const SizedBox(height: PokeBinderSpacing.sp1),
                        CountUpText(value, style: PokeBinderText.statNumber),
                      ],
                    ),
                  ),
                  PopIn(
                    delay: const Duration(milliseconds: 350),
                    child: Container(
                      padding: const EdgeInsets.all(PokeBinderSpacing.sp2),
                      decoration: BoxDecoration(
                        color: PokeBinderColors.red.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        size: 18,
                        color: PokeBinderColors.redDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToDeckSheetResult {
  final DeckData? deck;
  final int quantity;
  final bool createNew;

  const _AddToDeckSheetResult.pick(this.deck, this.quantity)
      : createNew = false;

  const _AddToDeckSheetResult.createNew()
      : deck = null,
        quantity = 0,
        createNew = true;
}

class _AddToDeckSheet extends StatefulWidget {
  final PokemonCardData card;

  const _AddToDeckSheet({required this.card});

  @override
  State<_AddToDeckSheet> createState() => _AddToDeckSheetState();
}

class _AddToDeckSheetState extends State<_AddToDeckSheet> {
  DeckData? _selectedDeck;
  late int _quantity = math.min(1, widget.card.quantityOwned);

  int _currentQuantityIn(DeckData deck) {
    final match = deck.cards.where((c) => c.cardId == widget.card.id);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  void _selectDeck(DeckData deck) {
    setState(() {
      _selectedDeck = deck;
      final existing = _currentQuantityIn(deck);
      _quantity = existing > 0
          ? existing
          : math.min(1, widget.card.quantityOwned);
    });
  }

  @override
  Widget build(BuildContext context) {
    final decks = DeckData.library;
    final maxQuantity = widget.card.quantityOwned;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(PokeBinderSpacing.sp3),
        padding: const EdgeInsets.fromLTRB(
          PokeBinderSpacing.sp4,
          PokeBinderSpacing.sp3,
          PokeBinderSpacing.sp4,
          PokeBinderSpacing.sp4,
        ),
        decoration: BoxDecoration(
          color: PokeBinderColors.cream,
          borderRadius: BorderRadius.circular(20),
          boxShadow: kCardElevation,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: PokeBinderColors.ink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: PokeBinderSpacing.sp3),
            Text('Add to Deck', style: PokeBinderText.heading),
            const SizedBox(height: PokeBinderSpacing.sp1),
            Text(
              'Choose which deck should feature ${widget.card.name}.',
              style: PokeBinderText.subtitle,
            ),
            const SizedBox(height: PokeBinderSpacing.sp3),
            if (decks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: PokeBinderSpacing.sp3),
                child: Text(
                  "You don't have any decks yet.",
                  style: PokeBinderText.subtitle,
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: Container(
                  decoration: BoxDecoration(
                    color: PokeBinderColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: PokeBinderColors.ink.withValues(alpha: 0.08)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: decks.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: PokeBinderColors.ink.withValues(alpha: 0.06),
                      ),
                      itemBuilder: (context, index) {
                        final deck = decks[index];
                        final inDeck = _currentQuantityIn(deck);
                        final selected = _selectedDeck?.id == deck.id;
                        return Material(
                          color: selected
                              ? PokeBinderColors.red.withValues(alpha: 0.045)
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectDeck(deck),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: PokeBinderSpacing.sp3, vertical: PokeBinderSpacing.sp3),
                              child: Row(
                                children: [
                                  Icon(deck.format.icon,
                                      size: 16,
                                      color: PokeBinderColors.inkSoft),
                                  const SizedBox(width: PokeBinderSpacing.sp2),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deck.name,
                                          style: PokeBinderText.rowTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                          height: PokeBinderSpacing.sp0,
                                        ),
                                        Text(
                                          inDeck > 0
                                              ? '${deck.format.label} · $inDeck in deck'
                                              : deck.format.label,
                                          style:
                                              PokeBinderText.listRowSubtitle,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 20,
                                    color: selected
                                        ? PokeBinderColors.redDeep
                                        : PokeBinderColors.inkSoft
                                            .withValues(alpha: 0.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: PokeBinderSpacing.sp2),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context)
                    .pop(const _AddToDeckSheetResult.createNew()),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                        vertical: PokeBinderSpacing.sp2,
                        horizontal: PokeBinderSpacing.sp0,
                      ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 16, color: PokeBinderColors.redDeep),
                      const SizedBox(width: PokeBinderSpacing.sp1),
                      Text(
                        'Create a new deck',
                        style: PokeBinderText.backLink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedDeck != null) ...[
              const SizedBox(height: PokeBinderSpacing.sp2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Copies in "${_selectedDeck!.name}"',
                    style: PokeBinderText.fieldLabel
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StepperButton(
                        icon: Icons.remove_rounded,
                        onTap: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: PokeBinderText.statNumberSm,
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add_rounded,
                        onTap: _quantity < maxQuantity
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: PokeBinderSpacing.sp3),
            PillButton(
              label: 'Add',
              icon: Icons.check,
              enabled: _selectedDeck != null && maxQuantity > 0,
              onTap: () => Navigator.of(context).pop(
                _AddToDeckSheetResult.pick(_selectedDeck, _quantity),
              ),
            ),
          ],
        ),
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
      color: PokeBinderColors.cream2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(PokeBinderSpacing.sp2),
          child: Icon(
            icon,
            size: 16,
            color: onTap != null
                ? PokeBinderColors.redDeep
                : PokeBinderColors.inkSoft.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
