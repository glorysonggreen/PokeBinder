import 'package:flutter/material.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_sort_controls.dart' show trainerSubtypeIcon;
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'deck_add_card_screen.dart';

const _kTagOkFg = Color(0xFF2F6B45);

extension _DeckFormatAccent on DeckFormat {
  Color get accentColor {
    switch (this) {
      case DeckFormat.standard:
        return PokeBinderColors.teal;
      case DeckFormat.expanded:
        return PokeBinderColors.goldDeep;
      case DeckFormat.casual:
        return PokeBinderColors.slate;
    }
  }
}

class _EntryEditResult {
  final bool remove;
  final int? quantity;

  const _EntryEditResult.remove()
      : remove = true,
        quantity = null;

  const _EntryEditResult.save(int quantity)
      : remove = false,
        quantity = quantity;
}

/// Full-screen view of a single deck: its stats and card list.
/// Reached by tapping a deck on the overview (DecksScreen).
///
/// Card edits are pushed back to the caller live via [onDeckChanged] as
/// they happen (rather than only on pop), so the overview list stays
/// correct no matter how this screen is dismissed (app-bar back button,
/// system back gesture, etc).
class DeckDetailScreen extends StatefulWidget {
  final DeckData deck;
  final PokemonCardData? Function(String cardId) cardOf;
  final ValueChanged<DeckData> onDeckChanged;

  const DeckDetailScreen({
    super.key,
    required this.deck,
    required this.cardOf,
    required this.onDeckChanged,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  static const _kCardsPerPage = 5;

  late DeckData _deck = widget.deck;
  int _pageIndex = 0;

  int get _pageCount =>
      _deck.cards.isEmpty ? 1 : (_deck.cards.length / _kCardsPerPage).ceil();

  List<DeckCardEntry> get _currentPageCards {
    if (_deck.cards.isEmpty) return const [];
    final start = _pageIndex * _kCardsPerPage;
    final end = (start + _kCardsPerPage).clamp(0, _deck.cards.length);
    return _deck.cards.sublist(start, end);
  }

  int _readyCount(DeckData deck) {
    var ready = 0;
    for (final entry in deck.cards) {
      final owned = widget.cardOf(entry.cardId)?.quantityOwned ?? 0;
      ready += owned < entry.quantity ? owned : entry.quantity;
    }
    return ready > deck.targetSize ? deck.targetSize : ready;
  }

  void _updateDeck(DeckData updated) {
    setState(() {
      _deck = updated;
      final maxPageIndex =
          updated.cards.isEmpty ? 0 : (updated.cards.length / _kCardsPerPage).ceil() - 1;
      if (_pageIndex > maxPageIndex) _pageIndex = maxPageIndex;
    });
    widget.onDeckChanged(updated);
  }

  Future<void> _openAddCards() async {
    final result = await Navigator.of(context).push<List<DeckCardEntry>>(
      MaterialPageRoute(
        builder: (_) => DeckAddCardScreen(
          deckName: _deck.name,
          initialEntries: _deck.cards,
        ),
      ),
    );
    if (result == null) return;
    _updateDeck(_deck.copyWith(cards: result));
  }

  Future<void> _editCardEntry(DeckCardEntry entry) async {
    final card = widget.cardOf(entry.cardId);
    var qty = entry.quantity;

    final result = await showDialog<_EntryEditResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: PokeBinderColors.cream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            card?.name ?? 'Card',
            style: PokeBinderText.heading.copyWith(fontSize: 15),
          ),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniStepperButton(
                icon: Icons.remove_rounded,
                onTap: qty > 1 ? () => setDialogState(() => qty--) : null,
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: PokeBinderText.statNumber,
                ),
              ),
              _MiniStepperButton(
                icon: Icons.add_rounded,
                onTap: card == null || qty < card.quantityOwned
                    ? () => setDialogState(() => qty++)
                    : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(const _EntryEditResult.remove()),
              child: const Text(
                'Remove',
                style: TextStyle(color: PokeBinderColors.danger),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_EntryEditResult.save(qty)),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: PokeBinderColors.redDeep,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final cards = [..._deck.cards];
    if (result.remove) {
      cards.removeWhere((c) => c.cardId == entry.cardId);
    } else {
      final ci = cards.indexWhere((c) => c.cardId == entry.cardId);
      if (ci != -1) {
        cards[ci] = cards[ci].copyWith(quantity: result.quantity);
      }
    }
    _updateDeck(_deck.copyWith(cards: cards));
  }

  @override
  Widget build(BuildContext context) {
    final ready = _readyCount(_deck);

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            PokeBinderSpacing.sp5,
            PokeBinderSpacing.sp3,
            PokeBinderSpacing.sp5,
            PokeBinderSpacing.sp6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('DECK DETAILS', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp4),
              _DeckOverviewCard(deck: _deck, ready: ready, cardOf: widget.cardOf),
              const SizedBox(height: PokeBinderSpacing.sp4),

              if (_deck.cards.isEmpty)
                const _EmptyPanel(
                  message: 'No cards in this deck yet — add some below.',
                )
              else ...[
                _DeckCardListPanel(
                  cards: _currentPageCards,
                  cardOf: widget.cardOf,
                  onTapEntry: _editCardEntry,
                ),
                if (_deck.cards.length > _kCardsPerPage) ...[
                  const SizedBox(height: PokeBinderSpacing.sp3),
                  Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          label: '‹ Prev',
                          ghost: true,
                          enabled: _pageIndex > 0,
                          onTap: _pageIndex > 0
                              ? () => setState(() => _pageIndex--)
                              : () {},
                        ),
                      ),
                      const SizedBox(width: PokeBinderSpacing.sp2),
                      Expanded(
                        child: PillButton(
                          label: 'Next ›',
                          ghost: true,
                          enabled: _pageIndex < _pageCount - 1,
                          onTap: _pageIndex < _pageCount - 1
                              ? () => setState(() => _pageIndex++)
                              : () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: PokeBinderSpacing.sp4),
              PillButton(
                label: 'Add Card',
                icon: Icons.add,
                onTap: _openAddCards,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatTag extends StatelessWidget {
  final DeckFormat format;

  const _FormatTag({required this.format});

  @override
  Widget build(BuildContext context) {
    final color = format.accentColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        format.shortLabel.toUpperCase(),
        style: PokeBinderText.chakraPetch(TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
          color: color,
        )),
      ),
    );
  }
}

/// Groups deck identity, at-a-glance stats, completion progress, and
/// type mix into a single card so the "how's this deck doing?" info
/// reads as one unit instead of loose rows floating on the page.
class _DeckOverviewCard extends StatelessWidget {
  final DeckData deck;
  final int ready;
  final PokemonCardData? Function(String cardId) cardOf;

  const _DeckOverviewCard({
    required this.deck,
    required this.ready,
    required this.cardOf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: PokeBinderText.heading.copyWith(fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              _FormatTag(format: deck.format),
            ],
          ),
          const SizedBox(height: PokeBinderSpacing.sp4),
          _DeckStatsRow(deck: deck, ready: ready),
          const SizedBox(height: PokeBinderSpacing.sp4),
          _DeckProgressBar(ready: ready, target: deck.targetSize),
          if (deck.cards.isNotEmpty) ...[
            const SizedBox(height: PokeBinderSpacing.sp4),
            _DeckTypeBalanceBar(deck: deck, cardOf: cardOf),
          ],
        ],
      ),
    );
  }
}

class _DeckStatsRow extends StatelessWidget {
  final DeckData deck;
  final int ready;

  const _DeckStatsRow({required this.deck, required this.ready});

  @override
  Widget build(BuildContext context) {
    final missing =
        (deck.targetSize - ready).clamp(0, deck.targetSize).toInt();
    final percent =
        deck.targetSize <= 0 ? 0 : ((ready / deck.targetSize) * 100).round();
    final complete = missing == 0;

    return Row(
      children: [
        Expanded(
          child: _StatBlock(
            value: '${deck.cards.length}',
            label: 'unique',
          ),
        ),
        _StatDivider(),
        Expanded(
          child: _StatBlock(
            value: '${deck.cardCount}',
            label: 'copies',
          ),
        ),
        _StatDivider(),
        Expanded(
          child: _StatBlock(
            value: complete ? '$percent%' : '$missing',
            label: complete ? 'ready' : 'needed',
            color: complete ? _kTagOkFg : null,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: PokeBinderColors.ink.withValues(alpha: 0.08),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const _StatBlock({
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? PokeBinderColors.redDeep;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: PokeBinderText.statNumber.copyWith(
            fontSize: 16,
            color: tint,
          ),
        ),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: PokeBinderText.statLabel,
        ),
      ],
    );
  }
}

class _DeckProgressBar extends StatelessWidget {
  final int ready;
  final int target;

  const _DeckProgressBar({required this.ready, required this.target});

  @override
  Widget build(BuildContext context) {
    final fraction =
        target <= 0 ? 0.0 : (ready / target).clamp(0.0, 1.0).toDouble();
    final complete = ready >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 9,
            backgroundColor: PokeBinderColors.cream2,
            valueColor: AlwaysStoppedAnimation<Color>(
              complete ? _kTagOkFg : PokeBinderColors.gold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (complete)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _kTagOkFg.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 13, color: _kTagOkFg),
                const SizedBox(width: 8),
                Text(
                  'Deck is ready to play!',
                  style: PokeBinderText.listRowSubtitle.copyWith(
                    fontSize: 11,
                    color: _kTagOkFg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            '$ready of $target cards ready',
            style: PokeBinderText.listRowSubtitle.copyWith(
              color: PokeBinderColors.inkSoft,
            ),
          ),
      ],
    );
  }
}

class _TypeMixSlice {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _TypeMixSlice({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
}

class _DeckTypeBalanceBar extends StatelessWidget {
  final DeckData deck;
  final PokemonCardData? Function(String cardId) cardOf;

  const _DeckTypeBalanceBar({required this.deck, required this.cardOf});

  static const _trainerColors = <String, Color>{
    'Item': Color(0xFF3F72A6),
    'Supporter': Color(0xFF244D77),
    'Stadium': Color(0xFF7FAAC9),
  };

  String _typeLabel(PokemonCardType type) {
    final name = type.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  List<_TypeMixSlice> get _slices {
    final energyCounts = <PokemonCardType, int>{};
    final trainerCounts = <String, int>{};

    for (final entry in deck.cards) {
      final card = cardOf(entry.cardId);
      if (card == null) continue;
      if (card.supertype == CardSupertype.trainer) {
        final key = card.subtype ?? 'Trainer';
        trainerCounts[key] = (trainerCounts[key] ?? 0) + entry.quantity;
      } else {
        energyCounts[card.type] = (energyCounts[card.type] ?? 0) + entry.quantity;
      }
    }

    final slices = <_TypeMixSlice>[
      for (final entry in energyCounts.entries)
        _TypeMixSlice(
          label: _typeLabel(entry.key),
          count: entry.value,
          icon: entry.key.typeIcon,
          color: entry.key.gradientColors.last,
        ),
      for (final entry in trainerCounts.entries)
        _TypeMixSlice(
          label: entry.key,
          count: entry.value,
          icon: trainerSubtypeIcon(entry.key == 'Trainer' ? null : entry.key),
          color: _trainerColors[entry.key] ?? const Color(0xFF5C88AD),
        ),
    ];
    slices.sort((a, b) => b.count.compareTo(a.count));
    return slices;
  }

  @override
  Widget build(BuildContext context) {
    final slices = _slices;
    final total = slices.fold(0, (sum, s) => sum + s.count);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('CARD TYPE MIX', style: PokeBinderText.sectionLabel),
            Text(
              '$total ${total == 1 ? 'card' : 'cards'}',
              style: PokeBinderText.sectionLabel,
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 9,
            child: Row(
              children: [
                for (final slice in slices)
                  Expanded(
                    flex: slice.count,
                    child: Container(color: slice.color),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final slice in slices)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: slice.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      slice.icon,
                      size: 13,
                      color: slice.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${slice.label} ${slice.count} · '
                      '${((slice.count / total) * 100).round()}%',
                      style: PokeBinderText.cardMeta.copyWith(
                        fontSize: 11,
                        color: PokeBinderColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DeckCardListPanel extends StatelessWidget {
  final List<DeckCardEntry> cards;
  final PokemonCardData? Function(String cardId) cardOf;
  final ValueChanged<DeckCardEntry> onTapEntry;

  const _DeckCardListPanel({
    required this.cards,
    required this.cardOf,
    required this.onTapEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i != 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 114,
                  color: PokeBinderColors.ink.withValues(alpha: 0.06),
                ),
              _DeckCardEntryRow(
                entry: cards[i],
                card: cardOf(cards[i].cardId),
                onTap: () => onTapEntry(cards[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeckCardEntryRow extends StatelessWidget {
  final DeckCardEntry entry;
  final PokemonCardData? card;
  final VoidCallback onTap;

  const _DeckCardEntryRow({
    required this.entry,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: PokeBinderColors.ink.withValues(alpha: 0.08),
                  ),
                  boxShadow: kCardElevation,
                ),
                child: CardThumbnail(
                  card: card,
                  width: 92,
                  height: 127,
                  borderRadius: 5,
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card?.name ?? 'Unknown card',
                      style: PokeBinderText.chakraPetch(const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: PokeBinderColors.ink,
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card == null ? '—' : '${card!.setName} · #${card!.cardNumber}',
                      style: PokeBinderText.listRowSubtitle,
                    ),
                    if (card != null) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _RarityTag(rarity: card!.rarity),
                          _ConditionTag(code: card!.condition),
                        ],
                      ),
                      if (card!.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          card!.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: PokeBinderText.listRowSubtitle.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              _QuantityBadge(quantity: entry.quantity),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon + label pairing for a card's rarity, reusing the app's
/// shared [rarityIconFor] lookup so it stays in sync with the dropdown
/// icons used elsewhere (card form, wishlist, trade entry).
class _RarityTag extends StatelessWidget {
  final String rarity;

  const _RarityTag({required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(rarityIconFor(rarity), size: 11, color: PokeBinderColors.goldDeep),
        const SizedBox(width: 4),
        Text(rarity, style: PokeBinderText.listRowSubtitle),
      ],
    );
  }
}

/// Small icon + label pairing for a card's condition, reusing the app's
/// shared [conditionIconFor] lookup and expanding the stored code (e.g.
/// 'NM') to its full label via [kConditionOptions] — same source of
/// truth as the condition dropdown in the card/wishlist/trade forms.
class _ConditionTag extends StatelessWidget {
  final String code;

  const _ConditionTag({required this.code});

  @override
  Widget build(BuildContext context) {
    final label = kConditionOptions
        .firstWhere((c) => c.$2 == code, orElse: () => (code, code))
        .$1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(conditionIconFor(code), size: 11, color: PokeBinderColors.teal),
        const SizedBox(width: 4),
        Text(label, style: PokeBinderText.listRowSubtitle),
      ],
    );
  }
}

/// Pill-shaped quantity badge, styled the same way as [_FormatTag] above
/// (tinted background + bold colored label) instead of bare red text.
class _QuantityBadge extends StatelessWidget {
  final int quantity;

  const _QuantityBadge({required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PokeBinderColors.redDeep.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '×$quantity',
        style: PokeBinderText.chakraPetch(const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: PokeBinderColors.redDeep,
        )),
      ),
    );
  }
}

class _MiniStepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniStepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PokeBinderColors.cream2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
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

class _EmptyPanel extends StatelessWidget {
  final String message;

  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PokeBinderSpacing.sp5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: PokeBinderText.subtitle,
      ),
    );
  }
}