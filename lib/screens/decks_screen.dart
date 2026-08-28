import 'package:flutter/material.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import 'deck_detail_screen.dart';
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
        return PokeBinderColors.slate;
    }
  }
}

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  final List<DeckData> _decks = DeckData.sampleDecks;
  String _deckSearch = '';
  DeckFormat? _formatFilter;
  bool _incompleteOnly = false;
  bool _viewingAllDecks = false;

  List<DeckData> get _visibleDecks {
    return _decks.where((deck) {
      if (_deckSearch.isNotEmpty &&
          !deck.name.toLowerCase().contains(_deckSearch.toLowerCase())) {
        return false;
      }
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

  void _toggleViewAllDecks() {
    setState(() => _viewingAllDecks = !_viewingAllDecks);
  }

  void _toggleDeckPin(DeckData deck) {
    setState(() {
      final index = _decks.indexWhere((d) => d.id == deck.id);
      if (index == -1) return;
      _decks[index] = _decks[index].copyWith(isPinned: !_decks[index].isPinned);
    });
  }

  Future<void> _openNewDeck() async {
    final result = await Navigator.of(context).push<DeckFormResult>(
      MaterialPageRoute(builder: (_) => const DeckFormScreen()),
    );
    if (result == null || result.deck == null) return;
    setState(() {
      _decks.add(result.deck!);
      _viewingAllDecks = false;
    });
    if (!mounted) return;
    await _openDeckDetail(result.deck!);
  }

  /// Opens the full-screen detail view for [deck]. Edits made there are
  /// streamed back live via the callbacks below, so `_decks` stays in
  /// sync no matter how the detail screen gets dismissed.
  Future<void> _openDeckDetail(DeckData deck) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeckDetailScreen(
          deck: deck,
          cardOf: _cardById,
          onDeckChanged: (updated) => setState(() {
            final index = _decks.indexWhere((d) => d.id == updated.id);
            if (index != -1) _decks[index] = updated;
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleDecks = _visibleDecks;

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            PokeBinderSpacing.sp5,
            PokeBinderSpacing.sp5,
            PokeBinderSpacing.sp5,
            PokeBinderSpacing.sp6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DECK PLANNER', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Your Decks', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text(
                'Plan decklists and track what you still need to pull.',
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp4),

              CollectionSearchBar(
                hint: 'Search decks...',
                onChanged: (v) => setState(() => _deckSearch = v),
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              PillButton(
                label: 'New Deck',
                icon: Icons.add,
                onTap: _openNewDeck,
              ),

              if (_decks.isNotEmpty) ...[
                const SizedBox(height: PokeBinderSpacing.sp4),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _DeckFilterChip(
                        label: 'All',
                        icon: Icons.apps_rounded,
                        active: _formatFilter == null,
                        onTap: () => setState(() => _formatFilter = null),
                      ),
                      const SizedBox(width: PokeBinderSpacing.sp2),
                      for (final format in DeckFormat.values) ...[
                        _DeckFilterChip(
                          label: format.shortLabel,
                          icon: format.icon,
                          active: _formatFilter == format,
                          onTap: () => setState(() {
                            _formatFilter = _formatFilter == format ? null : format;
                          }),
                        ),
                        const SizedBox(width: PokeBinderSpacing.sp2),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 1,
                          height: 18,
                          color: PokeBinderColors.ink.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: PokeBinderSpacing.sp2),
                      _DeckFilterChip(
                        label: 'Needs Cards',
                        icon: Icons.assignment_late_rounded,
                        active: _incompleteOnly,
                        isToggle: true,
                        onTap: () =>
                            setState(() => _incompleteOnly = !_incompleteOnly),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: PokeBinderSpacing.sp4),

              if (_decks.isEmpty)
                const _EmptyPanel(
                  message: 'No decks yet — create one to get started.',
                )
              else if (visibleDecks.isEmpty)
                const _EmptyPanel(
                  message: 'No decks match your search or filters.',
                )
              else
                _DeckListPanel(
                  decks: visibleDecks,
                  readyCountOf: _readyCount,
                  isCompleteOf: _isComplete,
                  viewingAllDecks: _viewingAllDecks,
                  onToggleViewAllDecks: _toggleViewAllDecks,
                  onSelect: _openDeckDetail,
                  onTogglePin: _toggleDeckPin,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool isToggle;

  const _DeckFilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.isToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = active
        ? (isToggle ? PokeBinderColors.ink : PokeBinderColors.white)
        : PokeBinderColors.inkSoft;
    final labelStyle = active
        ? (isToggle
            ? PokeBinderText.chipLabelActive.copyWith(color: PokeBinderColors.ink)
            : PokeBinderText.chipLabelActive)
        : PokeBinderText.chipLabel;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? null : PokeBinderColors.cream2,
          gradient: active
              ? (isToggle
                  ? PokeBinderColors.goldGradient
                  : PokeBinderColors.redGradient)
              : null,
          border: active
              ? null
              : Border.all(
                  color: isToggle
                      ? PokeBinderColors.goldDeep.withValues(alpha: 0.35)
                      : PokeBinderColors.ink.withValues(alpha: 0.06),
                ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: (isToggle
                            ? PokeBinderColors.goldDeep
                            : PokeBinderColors.redDeep)
                        .withValues(alpha: 0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: labelStyle,
              child: Text(label),
            ),
          ],
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

const int kMaxPinnedDecks = 2;
const int kMaxDecksShown = 3;

class _DeckSection {
  final String title;
  final List<DeckData> decks;
  final int totalCount;

  const _DeckSection({
    required this.title,
    required this.decks,
    required this.totalCount,
  });

  int get hiddenCount => totalCount - decks.length;
}

class _DeckListPanel extends StatelessWidget {
  final List<DeckData> decks;
  final int Function(DeckData) readyCountOf;
  final bool Function(DeckData) isCompleteOf;
  final bool viewingAllDecks;
  final VoidCallback onToggleViewAllDecks;
  final ValueChanged<DeckData> onSelect;
  final ValueChanged<DeckData> onTogglePin;

  const _DeckListPanel({
    required this.decks,
    required this.readyCountOf,
    required this.isCompleteOf,
    required this.viewingAllDecks,
    required this.onToggleViewAllDecks,
    required this.onSelect,
    required this.onTogglePin,
  });

  List<_DeckSection> _buildSections() {
    final pinned = decks.where((d) => d.isPinned).toList();
    final rest = decks.where((d) => !d.isPinned).toList();

    final sections = <_DeckSection>[];

    if (pinned.isNotEmpty) {
      sections.add(_DeckSection(
        title: 'Pinned Decks',
        decks: viewingAllDecks ? pinned : pinned.take(kMaxPinnedDecks).toList(),
        totalCount: pinned.length,
      ));
    }

    if (rest.isNotEmpty) {
      sections.add(_DeckSection(
        title: 'All Decks',
        decks: viewingAllDecks ? rest : rest.take(kMaxDecksShown).toList(),
        totalCount: rest.length,
      ));
    }

    return sections;
  }

  Widget _sectionPanel(List<DeckData> sectionDecks) {
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
            for (var i = 0; i < sectionDecks.length; i++) ...[
              if (i != 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: PokeBinderColors.ink.withValues(alpha: 0.06),
                ),
              _DeckRow(
                deck: sectionDecks[i],
                ready: readyCountOf(sectionDecks[i]),
                complete: isCompleteOf(sectionDecks[i]),
                onTap: () => onSelect(sectionDecks[i]),
                onTogglePin: () => onTogglePin(sectionDecks[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final hiddenCount =
        sections.fold<int>(0, (sum, section) => sum + section.hiddenCount);
    final showMultipleSections = sections.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          if (showMultipleSections) ...[
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                '${section.title.toUpperCase()} · ${section.totalCount}',
                style: PokeBinderText.sectionLabel,
              ),
            ),
            const SizedBox(height: PokeBinderSpacing.sp2),
          ],
          _sectionPanel(section.decks),
          if (section != sections.last)
            const SizedBox(height: PokeBinderSpacing.sp3),
        ],
        if (hiddenCount > 0 || viewingAllDecks)
          Padding(
            padding: const EdgeInsets.only(top: PokeBinderSpacing.sp2),
            child: GestureDetector(
              onTap: onToggleViewAllDecks,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    viewingAllDecks
                        ? 'Show Less'
                        : 'View All Decks (+$hiddenCount)',
                    style: PokeBinderText.backLink,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    viewingAllDecks
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 14,
                    color: PokeBinderText.backLink.color,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DeckRow extends StatelessWidget {
  final DeckData deck;
  final int ready;
  final bool complete;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  const _DeckRow({
    required this.deck,
    required this.ready,
    required this.complete,
    required this.onTap,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final missing = deck.targetSize - ready;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PokeBinderSpacing.sp4,
            vertical: PokeBinderSpacing.sp4,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 30,
                margin: const EdgeInsets.only(right: PokeBinderSpacing.sp3),
                decoration: BoxDecoration(
                  color: deck.format.accentColor,
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
              GestureDetector(
                onTap: onTogglePin,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    deck.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 15,
                    color: deck.isPinned
                        ? PokeBinderColors.red
                        : PokeBinderColors.inkSoft.withValues(alpha: 0.4),
                  ),
                ),
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