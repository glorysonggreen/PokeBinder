import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final String trainerName;
  final VoidCallback onOpenAllCards;
  final VoidCallback onOpenBinders;
  final ValueChanged<BinderData> onOpenBinder;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenMore;

  const HomeScreen({
    super.key,
    this.trainerName = 'Ash',
    required this.onOpenAllCards,
    required this.onOpenBinders,
    required this.onOpenBinder,
    required this.onOpenScan,
    required this.onOpenMore,
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
    return sorted.take(3).toList();
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
                const SizedBox(height: 2),
                Text(
                  'Welcome back, ${widget.trainerName}',
                  style: PokeBinderText.heading,
                ),
                const SizedBox(height: 2),
                Text(
                  'Your collection at a glance',
                  style: PokeBinderText.subtitle,
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),

                _HomeSearchBar(
                  cardCount: _totalCardCount,
                  onTap: widget.onOpenAllCards,
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

                _ContinueBinderPanel(
                  binder: continueBinder,
                  onTap: () => widget.onOpenBinder(continueBinder),
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),

                Text('RECENTLY ADDED', style: PokeBinderText.sectionLabel),
                const SizedBox(height: PokeBinderSpacing.sp2),
                if (recentCards.isEmpty)
                  Text(
                    'Scan or add a card to see it here.',
                    style: PokeBinderText.subtitle,
                  )
                else
                  Row(
                    children: [
                      for (var i = 0; i < recentCards.length; i++) ...[
                        if (i != 0) const SizedBox(width: PokeBinderSpacing.sp2),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openCard(recentCards[i]),
                            child: AspectRatio(
                              aspectRatio: kPokemonCardImageAspectRatio,
                              child: PokemonCard(card: recentCards[i]),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: PokeBinderSpacing.sp4),

                PillButton(
                  label: 'Scan a new card',
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

class _HomeSearchBar extends StatelessWidget {
  final int cardCount;
  final VoidCallback onTap;

  const _HomeSearchBar({required this.cardCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PokeBinderColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.09)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 16, color: PokeBinderColors.inkSoft),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Search your whole collection…',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFA89C86)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: PokeBinderColors.cream2,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$cardCount cards',
                  style: PokeBinderText.chakraPetch(const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: PokeBinderColors.inkSoft,
                  )),
                ),
              ),
            ],
          ),
        ),
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
            boxShadow: [
              BoxShadow(
                color: PokeBinderColors.ink.withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: PokeBinderText.statNumber),
              const SizedBox(height: 2),
              Text(label, style: PokeBinderText.statLabel),
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
    PokemonCardData? firstCard;
    for (final page in binder.pages) {
      if (page.isNotEmpty) {
        firstCard = page.first;
        break;
      }
    }
    final gradientColors =
        firstCard?.type.gradientColors ?? PokeBinderColors.redGradient.colors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: PokeBinderColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: PokeBinderColors.ink.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CONTINUE A BINDER', style: PokeBinderText.sectionLabel),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
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
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${binder.pageCount} pages · ${binder.cardCount} cards',
                          style: PokeBinderText.listRowSubtitle,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBEBCB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Open',
                      style: PokeBinderText.chipLabel
                          .copyWith(color: PokeBinderColors.goldDeep),
                    ),
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
