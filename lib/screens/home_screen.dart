import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/pokebinder_controls.dart';
import 'binder_form_screen.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

final List<BoxShadow> _kCardElevation = [
  BoxShadow(
    color: PokeBinderColors.ink.withValues(alpha: 0.06),
    blurRadius: 10,
    offset: const Offset(0, 3),
  ),
];

class HomeScreen extends StatefulWidget {
  final String trainerName;
  final VoidCallback onOpenAllCards;
  final VoidCallback onOpenBinders;
  final ValueChanged<BinderData> onOpenBinder;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenMore;
  final VoidCallback onOpenDecks;

  const HomeScreen({
    super.key,
    this.trainerName = 'Ash',
    required this.onOpenAllCards,
    required this.onOpenBinders,
    required this.onOpenBinder,
    required this.onOpenScan,
    required this.onOpenMore,
    required this.onOpenDecks,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<BinderData> _binders = BinderData.sampleBinders;
  final List<PokemonCardData> _cards = PokemonCardData.library;

  BinderData get _continueBinder {
    final pinned = _binders.where((b) => b.isPinned).toList()
      ..sort((a, b) => b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch));
    if (pinned.isNotEmpty) return pinned.first;

    final byRecency = [..._binders]
      ..sort((a, b) => b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch));
    return byRecency.first;
  }

  List<PokemonCardData> get _recentlyAdded {
    final sorted = [..._cards]
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return sorted.take(2).toList();
  }

  int get _totalCardCount =>
      _cards.fold(0, (sum, c) => sum + c.quantityOwned);

  double get _totalValue =>
      _cards.fold(0.0, (sum, c) => sum + c.estimatedValue * c.quantityOwned);

  void _openCard(PokemonCardData card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardDetailsScreen(
          card: card,
          binders: _binders,
          onSave: _handleCardSaved,
        ),
      ),
    );
  }

  void _handleCardSaved(PokemonCardData oldCard, CardFormResult result) {
    setState(() {
      final index = _cards.indexWhere((c) => c.id == oldCard.id);
      if (index == -1) return;
      if (result.deleted) {
        _cards.removeAt(index);
      } else {
        _cards[index] = result.card!;
      }
    });
  }

  Future<void> _openNewBinder() async {
    final result = await Navigator.of(context).push<BinderFormResult>(
      MaterialPageRoute(builder: (_) => const BinderFormScreen()),
    );
    final created = result?.binder;
    if (created == null) return;
    setState(() => _binders.add(created));
  }

  Future<void> _openAddCardManually() async {
    final result = await Navigator.of(context).push<CardFormResult>(
      MaterialPageRoute(
        builder: (_) => CardFormScreen(
          binders: _binders,
          defaultBinderId: kUnassignedBinderId,
        ),
      ),
    );
    if (result == null || result.card == null) return;
    setState(() => _cards.add(result.card!));
  }

  @override
  Widget build(BuildContext context) {
    final continueBinder = _continueBinder;
    final recentCards = _recentlyAdded;

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp4,
            PokeBinderSpacing.sp4,
            0,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: PokeBinderSpacing.sp6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOME DASHBOARD', style: PokeBinderText.eyebrow),
                const SizedBox(height: PokeBinderSpacing.sp2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _TrainerAvatar(onTap: widget.onOpenMore),
                    const SizedBox(width: PokeBinderSpacing.sp3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${widget.trainerName}',
                            style: PokeBinderText.heading,
                          ),
                          const SizedBox(height: PokeBinderSpacing.sp1),
                          Text(
                            'Your collection at a glance',
                            style: PokeBinderText.subtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),

                CollectionSearchBar(
                  hint: 'Search your whole collection…',
                  enabled: false,
                  onTap: widget.onOpenAllCards,
                  trailing: _CardCountBadge(count: _totalCardCount),
                ),
                const SizedBox(height: PokeBinderSpacing.sp3),

                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        value: '$_totalCardCount',
                        label: 'Cards',
                        onTap: widget.onOpenAllCards,
                      ),
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp2),
                    Expanded(
                      child: _StatBox(
                        value: _formatCompactCurrency(_totalValue),
                        label: 'Value',
                        onTap: widget.onOpenMore,
                      ),
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp2),
                    Expanded(
                      child: _StatBox(
                        value: '${_binders.length}',
                        label: 'Binders',
                        onTap: widget.onOpenBinders,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),

                Text('QUICK ACTIONS', style: PokeBinderText.sectionLabel),
                const SizedBox(height: PokeBinderSpacing.sp2),
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: 'New Binder',
                        icon: Icons.add,
                        ghost: true,
                        onTap: _openNewBinder,
                      ),
                    ),
                    const SizedBox(width: PokeBinderSpacing.sp2),
                    Expanded(
                      child: PillButton(
                        label: 'New Deck',
                        icon: Icons.add,
                        ghost: true,
                        onTap: widget.onOpenDecks,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),

                _ContinueBinderPanel(
                  binder: continueBinder,
                  onTap: () => widget.onOpenBinder(continueBinder),
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'RECENTLY ADDED',
                        style: PokeBinderText.sectionLabel,
                      ),
                    ),
                    if (_cards.isNotEmpty)
                      GestureDetector(
                        onTap: widget.onOpenAllCards,
                        child: Text(
                          'View All',
                          style: PokeBinderText.chakraPetch(const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                            color: PokeBinderColors.redDeep,
                          )),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < recentCards.length; i++) ...[
                      if (i != 0) const SizedBox(width: PokeBinderSpacing.sp2),
                      Expanded(
                        child: _RecentCardTile(
                          card: recentCards[i],
                          onTap: () => _openCard(recentCards[i]),
                        ),
                      ),
                    ],
                    if (recentCards.isNotEmpty)
                      const SizedBox(width: PokeBinderSpacing.sp2),
                    Expanded(
                      child: _AddCardManuallyTile(onTap: _openAddCardManually),
                    ),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),

                PillButton(
                  label: 'Scan a New Card',
                  icon: Icons.center_focus_strong_rounded,
                  onTap: widget.onOpenScan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatCompactCurrency(double value) {
  if (value >= 1000) {
    return '\u20b1${(value / 1000).toStringAsFixed(1)}k';
  }
  return '\u20b1${value.toStringAsFixed(0)}';
}

class _TrainerAvatar extends StatelessWidget {
  final VoidCallback onTap;

  const _TrainerAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: PokeBinderColors.redGradient,
            border: Border.all(color: PokeBinderColors.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: PokeBinderColors.redDeep.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 5),
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(
            Icons.catching_pokemon,
            size: 24,
            color: PokeBinderColors.white,
          ),
        ),
      ),
    );
  }
}

class _CardCountBadge extends StatelessWidget {
  final int count;

  const _CardCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: PokeBinderColors.cream2,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$count cards',
        style: PokeBinderText.chakraPetch(const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: PokeBinderColors.inkSoft,
        )),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatBox({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PokeBinderColors.white, Color(0xFFFBF7EC)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
            boxShadow: _kCardElevation,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: PokeBinderText.statNumber),
              const SizedBox(height: 3),
              Text(
                label,
                style: PokeBinderText.statLabel.copyWith(letterSpacing: 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueBinderPanel extends StatelessWidget {
  final BinderData binder;
  final VoidCallback onTap;

  const _ContinueBinderPanel({required this.binder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradientColors = PokeBinderColors.redGradient.colors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PokeBinderColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
            boxShadow: _kCardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('CONTINUE A BINDER', style: PokeBinderText.sectionLabel),
                  if (binder.isPinned) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.push_pin_rounded,
                      size: 11,
                      color: PokeBinderColors.redDeep,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: PokeBinderColors.white,
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          binder.name,
                          style: PokeBinderText.listRowTitle
                              .copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${binder.pageCount} pages · ${binder.cardCount} cards',
                          style: PokeBinderText.listRowSubtitle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: PokeBinderColors.inkSoft,
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

class _RecentCardTile extends StatelessWidget {
  final PokemonCardData card;
  final VoidCallback onTap;

  const _RecentCardTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BinderCardTile(card: card, onTap: onTap),
        const SizedBox(height: PokeBinderSpacing.sp1),
        Text(
          card.name,
          textAlign: TextAlign.center,
          style: PokeBinderText.cardName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${card.setName} · #${card.cardNumber}',
          textAlign: TextAlign.center,
          style: PokeBinderText.cardMeta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AddCardManuallyTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCardManuallyTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AddCardTile(onTap: onTap),
        const SizedBox(height: PokeBinderSpacing.sp1),
        Text(
          'Add Card Manually',
          style: PokeBinderText.cardName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}