import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/card_caption.dart';
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

  final ValueChanged<PokemonCardData> onCardRemoved;
  final ValueChanged<BinderData> onBinderChanged;
  final ValueChanged<BinderData> onBinderDeleted;

  const BinderDetailScreen({
    super.key,
    required this.binderId,
    required this.binders,
    required this.unassignedCards,
    required this.onCardTap,
    required this.onAddCard,
    required this.onCardRemoved,
    required this.onBinderChanged,
    required this.onBinderDeleted,
  });

  @override
  State<BinderDetailScreen> createState() => _BinderDetailScreenState();
}

class _BinderDetailScreenState extends State<BinderDetailScreen> {
  int _pageIndex = 0;

  bool _removeMode = false;

  bool get _isUnassigned => widget.binderId == null;

  BinderData? get _binder {
    if (_isUnassigned) return null;
    final matches = widget.binders.where((b) => b.id == widget.binderId);
    return matches.isEmpty ? null : matches.first;
  }

  List<PokemonCardData> get _currentPageCards {
    if (_isUnassigned) return widget.unassignedCards();
    final binder = _binder;
    if (binder == null || binder.pages.isEmpty) return const [];
    final index = _pageIndex.clamp(0, binder.pages.length - 1);
    return binder.pages[index];
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
      if (_currentPageCards.isEmpty) _removeMode = false;
    });
  }

  Future<void> _confirmRemove(PokemonCardData card) async {
    final binder = _binder;
    if (binder == null) return;

    final copies =
        card.quantityOwned > 1 ? ' (all ${card.quantityOwned} copies)' : '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from binder?'),
        content: Text(
          '"${card.name}"$copies will come out of "${binder.name}" and move '
          'to Unassigned Cards. It stays in your collection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(
              Icons.remove_circle_outline,
              size: 16,
              color: PokeBinderColors.danger,
            ),
            label: const Text(
              'Remove',
              style: TextStyle(color: PokeBinderColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    widget.onCardRemoved(card);
    setState(() {
      if (_currentPageCards.isEmpty) _removeMode = false;
    });
    PokeBinderToast.show(
      context,
      'Moved "${card.name}" to Unassigned Cards.',
      kind: ToastKind.success,
    );
  }

  Future<void> _openEditBinder() async {
    final binder = _binder;
    if (binder == null) return;

    final result = await Navigator.of(context).push<BinderFormResult>(
      MaterialPageRoute(
        builder: (_) => BinderFormScreen(existingBinder: binder),
      ),
    );
    if (result == null) return;

    if (result.deleted) {
      if (widget.binders.length <= 1) {
        PokeBinderToast.show(
          context,
          'You need at least one binder.',
          kind: ToastKind.warning,
        );
        return;
      }
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
    final removing =
        !_isUnassigned && _removeMode && currentPageCards.isNotEmpty;
    final title = _isUnassigned ? 'Unassigned Cards' : binder!.name;
    final unassignedCount = widget.unassignedCards().length;
    final subtitle = _isUnassigned
        ? '$unassignedCount '
            '${unassignedCount == 1 ? 'card' : 'cards'} · no binder'
        : 'Page ${_pageIndex + 1} of ${binder!.pageCount}';

    return PokeBinderScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: PokeBinderSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BackLink(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  if (!_isUnassigned)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (removing)
                          _HeaderAction(
                            icon: Icons.check,
                            label: 'Done',
                            onTap: () => setState(() => _removeMode = false),
                          )
                        else ...[
                          if (currentPageCards.isNotEmpty) ...[
                            _HeaderAction(
                              icon: Icons.remove_circle_outline,
                              label: 'Remove',
                              onTap: () => setState(() => _removeMode = true),
                            ),
                            const SizedBox(width: PokeBinderSpacing.sp3),
                          ],
                          _HeaderAction(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            onTap: _openEditBinder,
                          ),
                        ],
                      ],
                    ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text(title, style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                removing
                    ? 'Tap a card to remove it from this binder.'
                    : subtitle,
                style: PokeBinderText.subtitle,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              LayoutBuilder(
                builder: (context, constraints) {
                  const crossAxisCount = 3;
                  const crossAxisSpacing = PokeBinderSpacing.sp2;
                  final cardWidth = (constraints.maxWidth -
                          crossAxisSpacing * (crossAxisCount - 1)) /
                      crossAxisCount;
                  final cardHeight = cardWidth / kPokemonCardImageAspectRatio;

                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: PokeBinderSpacing.sp2,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisExtent: cardHeight + 4 + kCardCaptionHeight,
                    ),
                    children: [
                      for (final (i, card) in currentPageCards.indexed)
                        FadeSlideIn(
                          key: ValueKey('$_pageIndex-${card.id}'),
                          index: i,
                          child: Column(
                            children: [
                              SizedBox(
                                height: cardHeight,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: BinderCardTile(
                                        card: card,
                                        onTap: removing
                                            ? () => _confirmRemove(card)
                                            : () => _openCard(card),
                                      ),
                                    ),
                                    if (removing)
                                      const Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IgnorePointer(
                                          child: _RemoveBadge(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: PokeBinderSpacing.sp1),
                              CardCaption(card: card),
                            ],
                          ),
                        ),
                      if (!removing && !_isUnassigned)
                        FadeSlideIn(
                          key: ValueKey('add-$_pageIndex'),
                          index: currentPageCards.length,
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
                        ),
                    ],
                  );
                },
              ),
              if (!_isUnassigned) ...[
                const SizedBox(height: PokeBinderSpacing.sp3),
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: '‹ Prev',
                        ghost: true,
                        enabled: _pageIndex > 0,
                        onTap: _pageIndex > 0
                            ? () => _goToPage(_pageIndex - 1)
                            : () {},
                      ),
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp2),
                    Expanded(
                      child: PillButton(
                        label: 'Next ›',
                        ghost: true,
                        enabled: _pageIndex < binder!.pageCount - 1,
                        onTap: _pageIndex < binder.pageCount - 1
                            ? () => _goToPage(_pageIndex + 1)
                            : () {},
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: PokeBinderText.backLink.color),
          const SizedBox(width: PokeBinderSpacing.sp1),
          Text(label, style: PokeBinderText.backLink),
        ],
      ),
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: PokeBinderColors.danger,
        shape: BoxShape.circle,
        border: Border.all(color: PokeBinderColors.white, width: 1.5),
        boxShadow: kCardElevation,
      ),
      child: const Icon(Icons.remove, size: 14, color: Colors.white),
    );
  }
}
