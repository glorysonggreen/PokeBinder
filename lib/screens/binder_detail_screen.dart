import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/pokebinder_controls.dart';
import 'binder_form_screen.dart';

/// Full-screen view of a single binder's pages, or of the "Unassigned
/// Cards" bucket when [binderId] is null. Reached by tapping a tile on
/// the Binders overview (BindersScreen).
///
/// This screen doesn't own the binder/card data — [binders] and
/// [unassignedCards] are the same live List objects the parent screen
/// holds, so any mutation the parent makes (e.g. after a card is moved
/// to a different binder via CardDetailsScreen) is visible here the
/// next time this screen rebuilds. Actions taken from this screen call
/// back into the parent via [onCardTap] / [onAddCard] / [onBinderChanged]
/// / [onBinderDeleted], and this screen refreshes itself right after
/// each of those completes.
class BinderDetailScreen extends StatefulWidget {
  final String? binderId;
  final List<BinderData> binders;
  final List<PokemonCardData> unassignedCards;
  final Future<void> Function(PokemonCardData card) onCardTap;
  final Future<void> Function({required String? binderId, required int pageIndex})
      onAddCard;
  final ValueChanged<BinderData> onBinderChanged;
  final ValueChanged<BinderData> onBinderDeleted;

  const BinderDetailScreen({
    super.key,
    required this.binderId,
    required this.binders,
    required this.unassignedCards,
    required this.onCardTap,
    required this.onAddCard,
    required this.onBinderChanged,
    required this.onBinderDeleted,
  });

  @override
  State<BinderDetailScreen> createState() => _BinderDetailScreenState();
}

class _BinderDetailScreenState extends State<BinderDetailScreen> {
  int _pageIndex = 0;

  bool get _isUnassigned => widget.binderId == null;

  BinderData? get _binder {
    if (_isUnassigned) return null;
    final matches = widget.binders.where((b) => b.id == widget.binderId);
    return matches.isEmpty ? null : matches.first;
  }

  List<PokemonCardData> get _currentPageCards {
    if (_isUnassigned) return widget.unassignedCards;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You need at least one binder.")),
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

    // Defensive: if the binder this screen was showing got deleted from
    // underneath it somehow, back out to the overview instead of crashing.
    if (!_isUnassigned && binder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final currentPageCards = _currentPageCards;
    final title = _isUnassigned ? 'Unassigned Cards' : binder!.name;
    final subtitle = _isUnassigned
        ? '${widget.unassignedCards.length} '
            '${widget.unassignedCards.length == 1 ? 'card' : 'cards'} · no binder'
        : 'Page ${_pageIndex + 1} of ${binder!.pageCount}';

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp3,
            PokeBinderSpacing.sp4,
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
                    child: Text(
                      _isUnassigned ? 'UNASSIGNED' : 'BINDER',
                      style: PokeBinderText.eyebrow,
                    ),
                  ),
                  if (!_isUnassigned)
                    InkWell(
                      onTap: _openEditBinder,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: PokeBinderText.backLink.color,
                          ),
                          const SizedBox(width: 4),
                          Text('Edit', style: PokeBinderText.backLink),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text(title, style: PokeBinderText.heading),
              const SizedBox(height: 4),
              Text(subtitle, style: PokeBinderText.subtitle),
              const SizedBox(height: PokeBinderSpacing.sp4),
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
                      for (final card in currentPageCards)
                        Column(
                          children: [
                            SizedBox(
                              height: cardHeight,
                              child: BinderCardTile(
                                card: card,
                                onTap: () => _openCard(card),
                              ),
                            ),
                            const SizedBox(height: PokeBinderSpacing.sp1),
                            Text(
                              card.name,
                              style: PokeBinderText.cardName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${card.setName} · #${card.cardNumber}',
                              style: PokeBinderText.cardMeta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      Column(
                        children: [
                          SizedBox(
                            height: cardHeight,
                            child: AddCardTile(onTap: _openAddCard),
                          ),
                          const SizedBox(height: PokeBinderSpacing.sp1),
                          Text(
                            'Add Card Manually',
                            style: PokeBinderText.cardName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                            ? () => setState(() => _pageIndex--)
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
                            ? () => setState(() => _pageIndex++)
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
