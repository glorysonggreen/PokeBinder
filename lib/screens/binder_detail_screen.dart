import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/card_caption.dart';
import '../widgets/card_selection.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/pokebinder_controls.dart';
import 'binder_form_screen.dart';
import '../widgets/pokebinder_background.dart';
import '../widgets/pokebinder_toast.dart';

class BinderDetailScreen extends StatefulWidget {
  final String? binderId;
  final List<BinderData> binders;
  final List<PokemonCardData> Function() unassignedCards;
  final Future<void> Function(PokemonCardData card) onCardTap;
  final Future<void> Function({required String? binderId, required int pageIndex})
      onAddCard;

  final ValueChanged<List<PokemonCardData>> onCardsRemoved;
  final ValueChanged<List<PokemonCardData>> onCardsDeleted;
  final ValueChanged<BinderData> onBinderChanged;
  final ValueChanged<BinderData> onBinderDeleted;

  const BinderDetailScreen({
    super.key,
    required this.binderId,
    required this.binders,
    required this.unassignedCards,
    required this.onCardTap,
    required this.onAddCard,
    required this.onCardsRemoved,
    required this.onCardsDeleted,
    required this.onBinderChanged,
    required this.onBinderDeleted,
  });

  @override
  State<BinderDetailScreen> createState() => _BinderDetailScreenState();
}

class _BinderDetailScreenState extends State<BinderDetailScreen> {
  int _pageIndex = 0;

  bool _selecting = false;
  final Set<String> _selectedIds = {};

  bool get _isUnassigned => widget.binderId == null;

  BinderData? get _binder {
    if (_isUnassigned) return null;
    final matches = widget.binders.where((b) => b.id == widget.binderId);
    return matches.isEmpty ? null : matches.first;
  }

  List<PokemonCardData> get _currentPageCards {
    if (_isUnassigned) return widget.unassignedCards();
    final binder = _binder;
    if (binder == null || binder.pageCount < 1) return const [];
    final page = _pageIndex.clamp(0, binder.pageCount - 1) + 1;
    return PokemonCardData.library
        .where((c) => c.binderName == binder.name && c.page == page)
        .toList();
  }

  Future<void> _openCard(PokemonCardData card) async {
    await widget.onCardTap(card);
    if (mounted) setState(() {});
  }

  Future<void> _openAddCard() async {
    await widget.onAddCard(
      binderId: _isUnassigned ? null : widget.binderId,
      pageIndex: _isUnassigned ? 0 : _pageIndex,
    );
    if (mounted) setState(() {});
  }

  void _goToPage(int index) {
    setState(() {
      _pageIndex = index;
      _selectedIds.clear();
      if (_currentPageCards.isEmpty) _selecting = false;
    });
  }

  void _enterSelectMode() => setState(() => _selecting = true);

  void _cancelSelect() => setState(() {
        _selecting = false;
        _selectedIds.clear();
      });

  void _toggleSelect(PokemonCardData card) {
    setState(() {
      _selecting = true;
      if (!_selectedIds.remove(card.id)) _selectedIds.add(card.id);
    });
  }

  void _selectAll(List<PokemonCardData> cards) {
    setState(() => _selectedIds.addAll(cards.map((c) => c.id)));
  }

  List<PokemonCardData> _selectedCards() =>
      _currentPageCards.where((c) => _selectedIds.contains(c.id)).toList();

  void _finishSelection() {
    _selectedIds.clear();
    if (_currentPageCards.isEmpty) _selecting = false;
  }

  Future<void> _deleteSelected() async {
    final cards = _selectedCards();
    if (cards.isEmpty) return;
    final confirmed = await confirmCardDeletion(context, cards);
    if (!confirmed || !mounted) return;

    widget.onCardsDeleted(cards);
    setState(_finishSelection);
    showCardsDeletedToast(context, cards);
  }

  Future<void> _removeSelected() async {
    final binder = _binder;
    final cards = _selectedCards();
    if (binder == null || cards.isEmpty) return;

    final count = cards.length;
    final subject = count == 1 ? '"${cards.first.name}"' : '$count cards';
    final confirmed = await confirmDestructive(
      context,
      title: count == 1 ? 'Remove from binder?' : 'Remove $count cards?',
      message: '$subject will come out of "${binder.name}" and move to '
          'Unassigned Cards. ${count == 1 ? 'It stays' : 'They stay'} in '
          'your collection.',
      confirmLabel: 'Remove',
      icon: Icons.remove_circle_outline,
    );
    if (!confirmed || !mounted) return;

    widget.onCardsRemoved(cards);
    setState(_finishSelection);
    PokeBinderToast.show(
      context,
      count == 1
          ? 'Moved "${cards.first.name}" to Unassigned Cards.'
          : 'Moved $count cards to Unassigned Cards.',
      kind: ToastKind.success,
    );
  }

  Future<void> _openEditBinder() async {
    final binder = _binder;
    if (binder == null) return;

    final result = await Navigator.of(context).push<BinderFormResult>(
      MaterialPageRoute(
        builder: (_) => BinderFormScreen(
          existingBinder: binder,
          canDelete: widget.binders.length > 1,
        ),
      ),
    );
    if (result == null) return;

    if (result.deleted) {
      widget.onBinderDeleted(binder);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    widget.onBinderChanged(result.binder!);
    setState(() {
      if (_pageIndex >= result.binder!.pageCount) {
        _pageIndex = (result.binder!.pageCount - 1).clamp(0, result.binder!.pageCount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final binder = _binder;

    if (!_isUnassigned && binder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final currentPageCards = _currentPageCards;
    final selecting = _selecting && currentPageCards.isNotEmpty;
    final selectedCards = selecting ? _selectedCards() : <PokemonCardData>[];
    final title = _isUnassigned ? 'Unassigned Cards' : binder!.name;
    final subtitle = _isUnassigned
        ? '${currentPageCards.length} '
            '${currentPageCards.length == 1 ? 'card' : 'cards'} · no binder'
        : 'Page ${_pageIndex + 1} of ${binder!.pageCount}';

    return PokeBinderScaffold(
      bottomNavigationBar: selecting
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PokeBinderSpacing.sp4,
                ),
                child: CardSelectionBar(
                  selectedCount: selectedCards.length,
                  onDelete: _deleteSelected,
                  onRemoveFromBinder: _isUnassigned ? null : _removeSelected,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                PokeBinderSpacing.sp4,
                PokeBinderSpacing.sp4,
                PokeBinderSpacing.sp4,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BackLink(onTap: () => Navigator.of(context).pop()),
                        const Spacer(),
                        if (!selecting && currentPageCards.isNotEmpty)
                          CardSelectAction(
                            icon: Icons.checklist_rounded,
                            label: 'Select',
                            onTap: _enterSelectMode,
                          ),
                        if (!selecting && !_isUnassigned)
                          CardSelectAction(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            onTap: _openEditBinder,
                          ),
                      ],
                    ),
                    Text(title, style: PokeBinderText.heading),
                    const SizedBox(height: PokeBinderSpacing.sp1),
                    SizedBox(
                      height: kMinTapTarget,
                      child: selecting
                          ? CardSelectionHeader(
                              selectedCount: selectedCards.length,
                              allSelected: selectedCards.length ==
                                  currentPageCards.length,
                              onSelectAll: () => _selectAll(currentPageCards),
                              onCancel: _cancelSelect,
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                subtitle,
                                style: PokeBinderText.subtitle,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isUnassigned && currentPageCards.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: PokeBinderSpacing.sp4,
                ),
                sliver: SliverToBoxAdapter(
                  child: EmptyFilterState(
                    icon: Icons.style_outlined,
                    title: 'No unassigned cards.',
                    subtitle: 'Cards you remove from a binder show up here.',
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: PokeBinderSpacing.sp4,
              ),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  const crossAxisCount = 3;
                  const crossAxisSpacing = PokeBinderSpacing.sp2;
                  final cardWidth = (constraints.crossAxisExtent -
                          crossAxisSpacing * (crossAxisCount - 1)) /
                      crossAxisCount;
                  final cardHeight = cardWidth / kPokemonCardImageAspectRatio;
                  final showAddTile = !selecting && !_isUnassigned;

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: PokeBinderSpacing.sp3,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisExtent:
                          cardHeight + PokeBinderSpacing.sp1 + kCardCaptionHeight,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: currentPageCards.length + (showAddTile ? 1 : 0),
                      (context, i) {
                        if (i == currentPageCards.length) {
                          return FadeSlideIn(
                            key: ValueKey('add-$_pageIndex'),
                            index: i,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: cardHeight,
                                  child: AddCardTile(onTap: _openAddCard),
                                ),
                                const SizedBox(height: PokeBinderSpacing.sp1),
                                Text(
                                  'Add Cards',
                                  style: PokeBinderText.cardName,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }

                        final card = currentPageCards[i];
                        final tile = Column(
                          children: [
                            SizedBox(
                              height: cardHeight,
                              child: GestureDetector(
                                onLongPress:
                                    selecting ? null : () => _toggleSelect(card),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: BinderCardTile(
                                        card: card,
                                        onTap: selecting
                                            ? () => _toggleSelect(card)
                                            : () => _openCard(card),
                                      ),
                                    ),
                                    if (selecting)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: CardSelectionMark(
                                            selected:
                                                _selectedIds.contains(card.id),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: PokeBinderSpacing.sp1),
                            CardCaption(card: card),
                          ],
                        );
                        final key = ValueKey('$_pageIndex-${card.id}');
                        return i < _kAnimatedTiles
                            ? FadeSlideIn(key: key, index: i, child: tile)
                            : KeyedSubtree(key: key, child: tile);
                      },
                    ),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp6),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PokeBinderSpacing.sp4,
                  ),
                  child: _isUnassigned
                      ? null
                      : Padding(
                          padding:
                              const EdgeInsets.only(top: PokeBinderSpacing.sp3),
                          child: Row(
                            children: [
                              Expanded(
                                child: PillButton(
                                  label: '‹ Prev',
                                  ghost: true,
                                  enabled: _pageIndex > 0,
                                  onTap: () => _goToPage(_pageIndex - 1),
                                ),
                              ),
                              const SizedBox(width: PokeBinderSpacing.sp2),
                              Expanded(
                                child: PillButton(
                                  label: 'Next ›',
                                  ghost: true,
                                  enabled: _pageIndex < binder!.pageCount - 1,
                                  onTap: () => _goToPage(_pageIndex + 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const int _kAnimatedTiles = 12;
