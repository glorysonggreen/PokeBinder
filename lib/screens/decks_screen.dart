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

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  final List<DeckData> _decks = DeckData.sampleDecks;
  String? _selectedDeckId;
  DeckFormat? _formatFilter;
  bool _incompleteOnly = false;

  @override
  void initState() {
    super.initState();
    if (_decks.isNotEmpty) _selectedDeckId = _decks.first.id;
  }

  DeckData? get _selectedDeck {
    if (_selectedDeckId == null) return null;
    final matches = _decks.where((d) => d.id == _selectedDeckId);
    return matches.isEmpty ? null : matches.first;
  }

  List<DeckData> get _visibleDecks {
    return _decks.where((deck) {
      if (_formatFilter != null && deck.format != _formatFilter) return false;
      if (_incompleteOnly && _isComplete(deck)) return false;
      return true;
    }).toList();
  }

  PokemonCardData? _cardById(String id) {
    final matches = PokemonCardData.library.where((c) => c.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  int _readyCount(DeckData deck) {
    var ready = 0;
    for (final entry in deck.cards) {
      final owned = _cardById(entry.cardId)?.quantityOwned ?? 0;
      ready += owned < entry.quantity ? owned : entry.quantity;
    }
    return ready > deck.targetSize ? deck.targetSize : ready;
  }

  int _missingCount(DeckData deck) =>
      (deck.targetSize - _readyCount(deck)).clamp(0, deck.targetSize).toInt();

  bool _isComplete(DeckData deck) => _missingCount(deck) <= 0;

  Future<void> _openNewDeck() async {
    final result = await Navigator.of(context).push<DeckFormResult>(
      MaterialPageRoute(builder: (_) => const DeckFormScreen()),
    );
    if (result == null || result.deck == null) return;
    setState(() {
      _decks.add(result.deck!);
      _selectedDeckId = result.deck!.id;
    });
  }

  Future<void> _openEditDeck(DeckData deck) async {
    final result = await Navigator.of(context).push<DeckFormResult>(
      MaterialPageRoute(builder: (_) => DeckFormScreen(existingDeck: deck)),
    );
    if (result == null) return;

    setState(() {
      final index = _decks.indexWhere((d) => d.id == deck.id);
      if (index == -1) return;
      if (result.deleted) {
        _decks.removeAt(index);
        if (_selectedDeckId == deck.id) {
          _selectedDeckId = _decks.isEmpty ? null : _decks.first.id;
        }
      } else {
        _decks[index] = result.deck!;
      }
    });
  }

  Future<void> _openAddCards(DeckData deck) async {
    final result = await Navigator.of(context).push<List<DeckCardEntry>>(
      MaterialPageRoute(
        builder: (_) => DeckAddCardScreen(
          deckName: deck.name,
          initialEntries: deck.cards,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      final index = _decks.indexWhere((d) => d.id == deck.id);
      if (index == -1) return;
      _decks[index] = _decks[index].copyWith(cards: result);
    });
  }

  String _duplicateName(String name) {
    final match = RegExp(r'^(.*) \(Copy(?: (\d+))?\)$').firstMatch(name);
    if (match == null) return '$name (Copy)';
    final base = match.group(1)!;
    final n = int.tryParse(match.group(2) ?? '1') ?? 1;
    return '$base (Copy ${n + 1})';
  }

  void _duplicateDeck(DeckData deck) {
    final copy = DeckData(
      id: 'deck-${DateTime.now().microsecondsSinceEpoch}',
      name: _duplicateName(deck.name),
      format: deck.format,
      targetSize: deck.targetSize,
      description: deck.description,
      cards: deck.cards,
    );
    setState(() {
      final index = _decks.indexWhere((d) => d.id == deck.id);
      _decks.insert(index == -1 ? _decks.length : index + 1, copy);
      _selectedDeckId = copy.id;
    });
  }

  Future<void> _editCardEntry(DeckData deck, DeckCardEntry entry) async {
    final card = _cardById(entry.cardId);
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
    setState(() {
      final index = _decks.indexWhere((d) => d.id == deck.id);
      if (index == -1) return;
      final cards = [..._decks[index].cards];
      if (result.remove) {
        cards.removeWhere((c) => c.cardId == entry.cardId);
      } else {
        final ci = cards.indexWhere((c) => c.cardId == entry.cardId);
        if (ci != -1) {
          cards[ci] = cards[ci].copyWith(quantity: result.quantity);
        }
      }
      _decks[index] = _decks[index].copyWith(cards: cards);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDeck = _selectedDeck;
    final visibleDecks = _visibleDecks;

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DECK PLANNER', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Your Decks', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Plan decklists and track what you still need to pull.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              PillButton(
                label: '+ New Deck',
                icon: Icons.add,
                onTap: _openNewDeck,
              ),

              if (_decks.isNotEmpty) ...[
                const SizedBox(height: PokeBinderSpacing.sp3),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChipPill(
                        label: 'All',
                        selected: _formatFilter == null,
                        onTap: () => setState(() => _formatFilter = null),
                      ),
                      const SizedBox(width: PokeBinderSpacing.sp2),
                      for (final format in DeckFormat.values) ...[
                        ChoiceChipPill(
                          label: format.shortLabel,
                          selected: _formatFilter == format,
                          onTap: () => setState(() {
                            _formatFilter = _formatFilter == format ? null : format;
                          }),
                        ),
                        const SizedBox(width: PokeBinderSpacing.sp2),
                      ],
                      ChoiceChipPill(
                        label: 'Needs cards',
                        selected: _incompleteOnly,
                        onTap: () =>
                            setState(() => _incompleteOnly = !_incompleteOnly),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: PokeBinderSpacing.sp3),

              if (_decks.isEmpty)
                const _EmptyPanel(
                  message: 'No decks yet — create one to get started.',
                )
              else if (visibleDecks.isEmpty)
                const _EmptyPanel(
                  message: 'No decks match these filters.',
                )
              else
                _DeckListPanel(
                  decks: visibleDecks,
                  selectedDeckId: _selectedDeckId,
                  readyCountOf: _readyCount,
                  isCompleteOf: _isComplete,
                  onSelect: (deck) =>
                      setState(() => _selectedDeckId = deck.id),
                  onEdit: _openEditDeck,
                  onDuplicate: _duplicateDeck,
                ),

              if (selectedDeck != null) ...[
                const SizedBox(height: PokeBinderSpacing.sp4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'EDITING · ${selectedDeck.name.toUpperCase()}',
                        style: PokeBinderText.sectionLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp2),
                    _FormatTag(format: selectedDeck.format),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp3),
                _DeckStatsRow(
                  deck: selectedDeck,
                  ready: _readyCount(selectedDeck),
                ),
                const SizedBox(height: PokeBinderSpacing.sp3),
                _DeckProgressBar(
                  ready: _readyCount(selectedDeck),
                  target: selectedDeck.targetSize,
                ),
                if (selectedDeck.cards.isNotEmpty) ...[
                  const SizedBox(height: PokeBinderSpacing.sp3),
                  _DeckTypeBalanceBar(
                    deck: selectedDeck,
                    cardOf: _cardById,
                  ),
                ],
                const SizedBox(height: PokeBinderSpacing.sp3),

                if (selectedDeck.cards.isEmpty)
                  const _EmptyPanel(
                    message: 'No cards in this deck yet — add some below.',
                  )
                else
                  _DeckCardListPanel(
                    deck: selectedDeck,
                    cardOf: _cardById,
                    onTapEntry: (entry) =>
                        _editCardEntry(selectedDeck, entry),
                  ),

                const SizedBox(height: PokeBinderSpacing.sp3),
                CollectionSearchBar(
                  hint: 'Search your binders for a card to add…',
                  enabled: false,
                  onTap: () => _openAddCards(selectedDeck),
                ),
                const SizedBox(height: PokeBinderSpacing.sp2),
                PillButton(
                  label: '+ Add card to deck',
                  ghost: true,
                  onTap: () => _openAddCards(selectedDeck),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        format.shortLabel,
        style: PokeBinderText.chakraPetch(TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          color: color,
        )),
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

    return Row(
      children: [
        _StatBlock(value: '${deck.cards.length}', label: 'unique cards'),
        const SizedBox(width: PokeBinderSpacing.sp5),
        _StatBlock(value: '${deck.cardCount}', label: 'total copies'),
        const SizedBox(width: PokeBinderSpacing.sp5),
        _StatBlock(
          value: missing == 0 ? '$percent%' : '$missing',
          label: missing == 0 ? 'ready' : 'still needed',
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;

  const _StatBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: PokeBinderText.statNumber.copyWith(fontSize: 16)),
        const SizedBox(height: 1),
        Text(label, style: PokeBinderText.statLabel),
      ],
    );
  }
}

class _DeckListPanel extends StatelessWidget {
  final List<DeckData> decks;
  final String? selectedDeckId;
  final int Function(DeckData) readyCountOf;
  final bool Function(DeckData) isCompleteOf;
  final ValueChanged<DeckData> onSelect;
  final ValueChanged<DeckData> onEdit;
  final ValueChanged<DeckData> onDuplicate;

  const _DeckListPanel({
    required this.decks,
    required this.selectedDeckId,
    required this.readyCountOf,
    required this.isCompleteOf,
    required this.onSelect,
    required this.onEdit,
    required this.onDuplicate,
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
            for (var i = 0; i < decks.length; i++) ...[
              if (i != 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: PokeBinderColors.ink.withValues(alpha: 0.06),
                ),
              _DeckRow(
                deck: decks[i],
                selected: decks[i].id == selectedDeckId,
                ready: readyCountOf(decks[i]),
                complete: isCompleteOf(decks[i]),
                onTap: () => onSelect(decks[i]),
                onEdit: () => onEdit(decks[i]),
                onDuplicate: () => onDuplicate(decks[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  final DeckData deck;
  final bool selected;
  final int ready;
  final bool complete;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;

  const _DeckRow({
    required this.deck,
    required this.selected,
    required this.ready,
    required this.complete,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final missing = deck.targetSize - ready;

    return Material(
      color: selected ? PokeBinderColors.red.withValues(alpha: 0.05) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PokeBinderSpacing.sp3,
            vertical: PokeBinderSpacing.sp3,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 30,
                margin: const EdgeInsets.only(right: PokeBinderSpacing.sp3),
                decoration: BoxDecoration(
                  color: complete ? _kTagOkFg : deck.format.accentColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: PokeBinderText.listRowTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _FormatTag(format: deck.format),
                        const SizedBox(width: PokeBinderSpacing.sp2),
                        Expanded(
                          child: Text(
                            '$ready / ${deck.targetSize} cards ready',
                            style: PokeBinderText.listRowSubtitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              _StatusTag(
                ok: complete,
                label: complete ? '✓ Complete' : 'Missing $missing',
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: PokeBinderColors.inkSoft,
                ),
                padding: EdgeInsets.zero,
                color: PokeBinderColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'duplicate') onDuplicate();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    height: 36,
                    child: Text('Edit deck details'),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    height: 36,
                    child: Text('Duplicate deck'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            minHeight: 8,
            backgroundColor: PokeBinderColors.cream2,
            valueColor: AlwaysStoppedAnimation<Color>(
              complete ? _kTagOkFg : PokeBinderColors.gold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          complete
              ? '✓ Deck is ready to play!'
              : '$ready of $target cards ready',
          style: PokeBinderText.listRowSubtitle.copyWith(
            color: complete ? _kTagOkFg : PokeBinderColors.inkSoft,
            fontWeight: complete ? FontWeight.bold : FontWeight.normal,
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
        Text('CARD TYPE MIX', style: PokeBinderText.sectionLabel),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 8,
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
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final entry in entries)
              Row(
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
                  const SizedBox(width: 4),
                  Text(
                    '${_typeLabel(entry.key)} ${entry.value}',
                    style: PokeBinderText.cardMeta,
                  ),
                ],
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
            horizontal: PokeBinderSpacing.sp3,
            vertical: PokeBinderSpacing.sp2 + 2,
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
      padding: const EdgeInsets.all(PokeBinderSpacing.sp4),
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