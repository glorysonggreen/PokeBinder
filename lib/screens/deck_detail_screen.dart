import 'package:flutter/material.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
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
  late DeckData _deck = widget.deck;

  int _readyCount(DeckData deck) {
    var ready = 0;
    for (final entry in deck.cards) {
      final owned = widget.cardOf(entry.cardId)?.quantityOwned ?? 0;
      ready += owned < entry.quantity ? owned : entry.quantity;
    }
    return ready > deck.targetSize ? deck.targetSize : ready;
  }

  void _updateDeck(DeckData updated) {
    setState(() => _deck = updated);
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
              else
                _DeckCardListPanel(
                  deck: _deck,
                  cardOf: widget.cardOf,
                  onTapEntry: _editCardEntry,
                ),

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

class _DeckTypeBalanceBar extends StatelessWidget {
  final DeckData deck;
  final PokemonCardData? Function(String cardId) cardOf;

  const _DeckTypeBalanceBar({required this.deck, required this.cardOf});

  Map<PokemonCardType, int> get _typeCounts {
    final counts = <PokemonCardType, int>{};
    for (final entry in deck.cards) {
      final card = cardOf(entry.cardId);
      if (card == null) continue;
      counts[card.type] = (counts[card.type] ?? 0) + entry.quantity;
    }
    return counts;
  }

  String _typeLabel(PokemonCardType type) {
    final name = type.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final counts = _typeCounts;
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                for (final entry in entries)
                  Expanded(
                    flex: entry.value,
                    child: Container(color: entry.key.gradientColors.last),
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
            for (final entry in entries)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: entry.key.gradientColors.last.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.key.typeIcon,
                      size: 13,
                      color: entry.key.gradientColors.last,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_typeLabel(entry.key)} ${entry.value} · '
                      '${((entry.value / total) * 100).round()}%',
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
  final DeckData deck;
  final PokemonCardData? Function(String cardId) cardOf;
  final ValueChanged<DeckCardEntry> onTapEntry;

  const _DeckCardListPanel({
    required this.deck,
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
            for (var i = 0; i < deck.cards.length; i++) ...[
              if (i != 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 62,
                  color: PokeBinderColors.ink.withValues(alpha: 0.06),
                ),
              _DeckCardEntryRow(
                entry: deck.cards[i],
                card: cardOf(deck.cards[i].cardId),
                onTap: () => onTapEntry(deck.cards[i]),
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
            children: [
              CardThumbnail(
                card: card,
                width: 40,
                height: 56,
                borderRadius: 8,
              ),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card?.name ?? 'Unknown card',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: PokeBinderColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card == null
                          ? '—'
                          : '${card!.setName} · #${card!.cardNumber} · '
                              '${card!.rarity}',
                      style: PokeBinderText.listRowSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              Text(
                '×${entry.quantity}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: PokeBinderColors.redDeep,
                ),
              ),
            ],
          ),
        ),
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