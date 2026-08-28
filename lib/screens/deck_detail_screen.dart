import 'package:flutter/material.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'deck_add_card_screen.dart';
import 'deck_form_screen.dart';

const _kTagOkBg = Color(0xFFE4EFE7);
const _kTagOkFg = Color(0xFF2F6B45);
const _kTagWarnBg = Color(0xFFFBE4E0);

extension _DeckFormatAccent on DeckFormat {
  Color get accentColor {
    switch (this) {
      case DeckFormat.standard:
        return PokeBinderColors.teal;
      case DeckFormat.expanded:
        return PokeBinderColors.goldDeep;
      case DeckFormat.casual:
        return PokeBinderColors.inkSoft;
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

/// Full-screen view of a single deck: its stats, card list, and edit
/// actions. Reached by tapping a deck on the overview (DecksScreen).
///
/// Edits are pushed back to the caller live via [onDeckChanged] /
/// [onDuplicate] / [onDeleted] as they happen (rather than only on pop),
/// so the overview list stays correct no matter how this screen is
/// dismissed (app-bar back button, system back gesture, etc).
class DeckDetailScreen extends StatefulWidget {
  final DeckData deck;
  final PokemonCardData? Function(String cardId) cardOf;
  final ValueChanged<DeckData> onDeckChanged;
  final ValueChanged<DeckData> onDuplicate;
  final VoidCallback onDeleted;

  const DeckDetailScreen({
    super.key,
    required this.deck,
    required this.cardOf,
    required this.onDeckChanged,
    required this.onDuplicate,
    required this.onDeleted,
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

  String _duplicateName(String name) {
    final match = RegExp(r'^(.*) \(Copy(?: (\d+))?\)$').firstMatch(name);
    if (match == null) return '$name (Copy)';
    final base = match.group(1)!;
    final n = int.tryParse(match.group(2) ?? '1') ?? 1;
    return '$base (Copy ${n + 1})';
  }

  void _updateDeck(DeckData updated) {
    setState(() => _deck = updated);
    widget.onDeckChanged(updated);
  }

  Future<void> _openEditDeck() async {
    final result = await Navigator.of(context).push<DeckFormResult>(
      MaterialPageRoute(builder: (_) => DeckFormScreen(existingDeck: _deck)),
    );
    if (result == null) return;
    if (result.deleted) {
      widget.onDeleted();
      if (mounted) Navigator.of(context).pop();
    } else {
      _updateDeck(result.deck!);
    }
  }

  void _duplicateDeck() {
    final copy = DeckData(
      id: 'deck-${DateTime.now().microsecondsSinceEpoch}',
      name: _duplicateName(_deck.name),
      format: _deck.format,
      targetSize: _deck.targetSize,
      description: _deck.description,
      cards: _deck.cards,
    );
    widget.onDuplicate(copy);
    Navigator.of(context).pop();
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
                onTap: () => setDialogState(() => qty++),
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
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 4, top: 2, bottom: 2),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 22, color: PokeBinderColors.ink),
                    ),
                  ),
                  Expanded(
                    child: Text('DECK', style: PokeBinderText.eyebrow),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      highlightColor: PokeBinderColors.red.withValues(alpha: 0.06),
                      splashColor: PokeBinderColors.red.withValues(alpha: 0.06),
                      hoverColor: PokeBinderColors.red.withValues(alpha: 0.05),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: PokeBinderColors.inkSoft,
                      ),
                      offset: const Offset(0, 32),
                      padding: EdgeInsets.zero,
                      color: PokeBinderColors.white,
                      elevation: 8,
                      shadowColor: PokeBinderColors.ink.withValues(alpha: 0.2),
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                            color: PokeBinderColors.ink.withValues(alpha: 0.08)),
                      ),
                      constraints: const BoxConstraints(minWidth: 175),
                      onSelected: (value) {
                        if (value == 'edit') _openEditDeck();
                        if (value == 'duplicate') _duplicateDeck();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          height: 38,
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: _DeckActionMenuRow(
                            icon: Icons.edit_outlined,
                            label: 'Edit Deck Details',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          height: 38,
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: _DeckActionMenuRow(
                            icon: Icons.copy_all_outlined,
                            label: 'Duplicate Deck',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text(_deck.name, style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp5),

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
              CollectionSearchBar(
                hint: 'Search your binders for a card to add…',
                enabled: false,
                onTap: _openAddCards,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              PillButton(
                label: '+ Add Card to Deck',
                ghost: true,
                onTap: _openAddCards,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckActionMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DeckActionMenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp2,
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: PokeBinderColors.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: PokeBinderText.chakraPetch(const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: PokeBinderColors.ink,
              )),
            ),
          ),
        ],
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
                    Text('EDITING', style: PokeBinderText.eyebrow),
                    const SizedBox(height: 2),
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
            icon: Icons.style_rounded,
            value: '${deck.cards.length}',
            label: 'unique',
          ),
        ),
        _StatDivider(),
        Expanded(
          child: _StatBlock(
            icon: Icons.copy_all_rounded,
            value: '${deck.cardCount}',
            label: 'copies',
          ),
        ),
        _StatDivider(),
        Expanded(
          child: _StatBlock(
            icon: complete
                ? Icons.check_circle_rounded
                : Icons.pending_actions_rounded,
            value: complete ? '$percent%' : '$missing',
            label: complete ? 'ready' : 'needed',
            color: complete ? _kTagOkFg : null,
            alignEnd: true,
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
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final bool alignEnd;

  const _StatBlock({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? PokeBinderColors.redDeep;
    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: tint),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: PokeBinderText.statNumber.copyWith(
                fontSize: 16,
                color: tint,
              ),
            ),
            Text(label.toUpperCase(), style: PokeBinderText.statLabel),
          ],
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
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _kTagOkFg.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: _kTagOkFg),
                const SizedBox(width: 6),
                Text(
                  'Deck is ready to play!',
                  style: PokeBinderText.listRowSubtitle.copyWith(
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
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: entry.key.gradientColors,
                        ),
                      ),
                    ),
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
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.key.gradientColors.last.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: entry.key.gradientColors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_typeLabel(entry.key)} ${entry.value} · '
                      '${((entry.value / total) * 100).round()}%',
                      style: PokeBinderText.cardMeta.copyWith(fontSize: 8.5),
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
    final owned = card?.quantityOwned ?? 0;
    final haveIt = owned >= entry.quantity;
    final missing = entry.quantity - owned;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PokeBinderSpacing.sp4,
            vertical: PokeBinderSpacing.sp3,
          ),
          child: Row(
            children: [
              CardThumbnail(card: card, width: 26, height: 36),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Text(
                  '${card?.name ?? 'Unknown card'} ×${entry.quantity}',
                  style: PokeBinderText.listRowTitle,
                ),
              ),
              _StatusTag(
                ok: haveIt,
                label: haveIt ? 'Have it' : 'Missing $missing',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final bool ok;
  final String label;

  const _StatusTag({required this.ok, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? _kTagOkBg : _kTagWarnBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: PokeBinderText.chakraPetch(TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          color: ok ? _kTagOkFg : PokeBinderColors.danger,
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
