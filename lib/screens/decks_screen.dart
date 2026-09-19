import 'package:flutter/material.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/min_tap_target.dart';
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

enum DeckSortOption { name, newest, oldest, cardCount }

extension DeckSortOptionLabel on DeckSortOption {
  String get label {
    switch (this) {
      case DeckSortOption.name:
        return 'Alphabetical';
      case DeckSortOption.newest:
        return 'Newest';
      case DeckSortOption.oldest:
        return 'Oldest';
      case DeckSortOption.cardCount:
        return 'Most Cards';
    }
  }

  IconData get icon {
    switch (this) {
      case DeckSortOption.name:
        return Icons.sort_by_alpha_rounded;
      case DeckSortOption.newest:
        return Icons.schedule_rounded;
      case DeckSortOption.oldest:
        return Icons.history_rounded;
      case DeckSortOption.cardCount:
        return Icons.style_rounded;
    }
  }
}

class DecksScreen extends StatefulWidget {
  /// When set, the deck with this id is opened right after the screen is
  /// built (e.g. after creating a deck from the Home quick actions).
  final String? initialDeckId;

  const DecksScreen({super.key, this.initialDeckId});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  final List<DeckData> _decks = DeckData.library;
  String _deckSearch = '';
  DeckFormat? _formatFilter;
  bool _incompleteOnly = false;
  bool _viewingAllDecks = false;
  DeckSortOption _deckSort = DeckSortOption.name;

  @override
  void initState() {
    super.initState();
    final initialId = widget.initialDeckId;
    if (initialId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final matches = _decks.where((d) => d.id == initialId);
      if (matches.isNotEmpty) _openDeckDetail(matches.first);
    });
  }

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

  void _clearFilters() {
    setState(() {
      _deckSearch = '';
      _formatFilter = null;
      _incompleteOnly = false;
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
          padding: PokeBinderSpacing.page,
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
                  height: kFilterChipRowHeight,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: PokeBinderSpacing.sp0,
                        ),
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
                EmptyFilterState(
                  title: 'No decks match your filters.',
                  subtitle: 'Try a different search or filter.',
                  onClearFilters: _clearFilters,
                )
              else ...[
                if (visibleDecks.length > 1) ...[
                  _DeckToolbar(
                    sortOption: _deckSort,
                    onSortChanged: (option) =>
                        setState(() => _deckSort = option),
                  ),
                  const SizedBox(height: PokeBinderSpacing.sp3),
                ],
                _DeckListPanel(
                  decks: visibleDecks,
                  sortOption: _deckSort,
                  readyCountOf: _readyCount,
                  isCompleteOf: _isComplete,
                  viewingAllDecks: _viewingAllDecks,
                  onToggleViewAllDecks: _toggleViewAllDecks,
                  onSelect: _openDeckDetail,
                  onTogglePin: _toggleDeckPin,
                ),
              ],
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

    // The pill itself stays compact (matches its old visual size); wrapping
    // it in Center lets the row around it grow to kFilterChipRowHeight
    // (44, a real tap target) without stretching the pill's background,
    // border or shadow to fill that height.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: PokeBinderSpacing.sp3,
            vertical: PokeBinderSpacing.sp2,
          ),
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
              const SizedBox(width: PokeBinderSpacing.sp1),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: labelStyle,
                child: Text(label),
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
      padding: PokeBinderSpacing.chip,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        format.shortLabel.toUpperCase(),
        style: PokeBinderText.tagLabel(color),
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
  final DeckSortOption sortOption;
  final int Function(DeckData) readyCountOf;
  final bool Function(DeckData) isCompleteOf;
  final bool viewingAllDecks;
  final VoidCallback onToggleViewAllDecks;
  final ValueChanged<DeckData> onSelect;
  final ValueChanged<DeckData> onTogglePin;

  const _DeckListPanel({
    required this.decks,
    required this.sortOption,
    required this.readyCountOf,
    required this.isCompleteOf,
    required this.viewingAllDecks,
    required this.onToggleViewAllDecks,
    required this.onSelect,
    required this.onTogglePin,
  });

  int _compare(DeckData a, DeckData b) {
    switch (sortOption) {
      case DeckSortOption.name:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case DeckSortOption.newest:
        return b.createdAt.compareTo(a.createdAt);
      case DeckSortOption.oldest:
        return a.createdAt.compareTo(b.createdAt);
      case DeckSortOption.cardCount:
        return b.cardCount.compareTo(a.cardCount);
    }
  }

  List<_DeckSection> _buildSections() {
    final pinned = decks.where((d) => d.isPinned).toList()..sort(_compare);
    final rest = decks.where((d) => !d.isPinned).toList()..sort(_compare);

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
              padding: const EdgeInsets.only(left: PokeBinderSpacing.sp0),
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
          MinTapTarget(
            onTap: onToggleViewAllDecks,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewingAllDecks
                      ? 'Show Less'
                      : 'View All Decks (+$hiddenCount)',
                  style: PokeBinderText.backLink,
                ),
                const SizedBox(width: PokeBinderSpacing.sp1),
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
      ],
    );
  }
}

class _DeckToolbar extends StatelessWidget {
  final DeckSortOption sortOption;
  final ValueChanged<DeckSortOption> onSortChanged;

  const _DeckToolbar({
    required this.sortOption,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DeckSortSelector(selected: sortOption, onChanged: onSortChanged),
      ],
    );
  }
}

class _DeckSortSelector extends StatelessWidget {
  final DeckSortOption selected;
  final ValueChanged<DeckSortOption> onChanged;

  const _DeckSortSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: PokeBinderColors.red.withValues(alpha: 0.06),
        splashColor: PokeBinderColors.red.withValues(alpha: 0.06),
        hoverColor: PokeBinderColors.red.withValues(alpha: 0.05),
      ),
      child: PopupMenuButton<DeckSortOption>(
        initialValue: selected,
        onSelected: onChanged,
        offset: const Offset(0, 32),
        color: PokeBinderColors.white,
        elevation: 8,
        shadowColor: PokeBinderColors.ink.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        ),
        constraints: const BoxConstraints(minWidth: 175),
        padding: const EdgeInsets.symmetric(vertical: PokeBinderSpacing.sp2),
        itemBuilder: (context) => [
          for (final option in DeckSortOption.values)
            PopupMenuItem(
              value: option,
              height: 38,
              padding: const EdgeInsets.symmetric(
                horizontal: PokeBinderSpacing.sp1,
              ),
              child: _DeckSortMenuRow(option: option, selected: option == selected),
            ),
        ],
        // ConstrainedBox+Center grows the tappable area PopupMenuButton
        // hit-tests against to kMinTapTarget (44) without growing the pill
        // itself, which stays sized by PokeBinderSpacing.chip as before.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Center(
            child: Container(
              padding: PokeBinderSpacing.chip,
              decoration: BoxDecoration(
                color: PokeBinderColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SORT: ${selected.label.toUpperCase()}',
                      style: PokeBinderText.resultCount),
                  const SizedBox(width: PokeBinderSpacing.sp0),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 15,
                    color: PokeBinderColors.inkSoft,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckSortMenuRow extends StatelessWidget {
  final DeckSortOption option;
  final bool selected;

  const _DeckSortMenuRow({required this.option, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp2,
        vertical: PokeBinderSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: selected ? PokeBinderColors.red.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(
            option.icon,
            size: 16,
            color: selected ? PokeBinderColors.red : PokeBinderColors.inkSoft,
          ),
          const SizedBox(width: PokeBinderSpacing.sp2),
          Expanded(
            child: Text(
              option.label,
              style: PokeBinderText.pillLabel(selected: selected),
            ),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: PokeBinderSpacing.sp1),
              child: Icon(
                Icons.check_rounded,
                size: 15,
                color: PokeBinderColors.red,
              ),
            ),
        ],
      ),
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
                height: 42,
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
                      style: PokeBinderText.rowTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: PokeBinderSpacing.sp1),
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
              MinTapTarget(
                onTap: onTogglePin,
                semanticLabel: deck.isPinned ? 'Unpin deck' : 'Pin deck',
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
      padding: PokeBinderSpacing.chip,
      decoration: BoxDecoration(
        color: ok ? _kTagOkBg : _kTagWarnBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: PokeBinderText.tagLabel(
          ok ? _kTagOkFg : PokeBinderColors.danger,
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