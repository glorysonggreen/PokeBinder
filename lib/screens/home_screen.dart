import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../models/trainer_profile_data.dart';
import '../services/binder_repository.dart';
import '../services/card_repository.dart';
import '../services/deck_repository.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/binder_card_tile.dart';
import '../widgets/card_caption.dart';
import '../widgets/min_tap_target.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/trainer_avatar.dart';
import 'binder_form_screen.dart';
import 'card_details_screen.dart';
import 'card_form_screen.dart';
import 'deck_form_screen.dart';
import 'stats_screen.dart';
import 'trainer_card_screen.dart';
import '../services/audio_service.dart';
import '../widgets/pokebinder_background.dart';

class HomeScreen extends StatefulWidget {
  final TrainerProfileData profile;
  final ValueChanged<TrainerProfileData>? onProfileChanged;
  final VoidCallback onOpenAllCards;
  final VoidCallback onOpenBinders;
  final ValueChanged<BinderData> onOpenBinder;
  final VoidCallback onOpenAdd;
  final ValueChanged<DeckData> onOpenDeck;

  const HomeScreen({
    super.key,
    required this.profile,
    this.onProfileChanged,
    required this.onOpenAllCards,
    required this.onOpenBinders,
    required this.onOpenBinder,
    required this.onOpenAdd,
    required this.onOpenDeck,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<BinderData> _binders = BinderData.library;
  final List<PokemonCardData> _cards = PokemonCardData.library;

  BinderData? get _continueBinder {
    if (_binders.isEmpty) return null;
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

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StatsScreen()),
    );
  }

  void _openTrainerCard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainerCardScreen(
          profile: widget.profile,
          onProfileChanged: widget.onProfileChanged,
          onBack: () => Navigator.of(context).maybePop(),
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
        CardRepository.delete(oldCard.id);
      } else {
        _cards[index] = result.card!;
        CardRepository.upsert(result.card!);
      }
    });
  }

  Future<void> _openNewBinder() async {
    final result = await Navigator.of(context).push<BinderFormResult>(
      MaterialPageRoute(builder: (_) => const BinderFormScreen()),
    );
    final created = result?.binder;
    if (created == null) return;
    PokeBinderAudio.play(Sfx.success);
    setState(() => _binders.add(created));
    BinderRepository.upsert(created);
  }

  Future<void> _openNewDeck() async {
    final created = await Navigator.of(context).push<DeckData>(
      MaterialPageRoute(builder: (_) => const DeckFormScreen()),
    );
    if (created == null) return;
    PokeBinderAudio.play(Sfx.success);
    DeckData.library.add(created);
    DeckRepository.upsert(created);
    widget.onOpenDeck(created);
  }

  @override
  Widget build(BuildContext context) {
    final continueBinder = _continueBinder;
    final recentCards = _recentlyAdded;

    return PokeBinderScaffold(
      backdrop: PokeBinderBackdrop.pokeball,
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
                FadeSlideIn(
                  index: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _TrainerAvatarButton(
                        imageUrl: widget.profile.avatarUrl,
                        onTap: _openTrainerCard,
                      ),
                      const SizedBox(width: PokeBinderSpacing.sp3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${widget.profile.name}',
                              style: PokeBinderText.heading,
                            ),
                            const SizedBox(height: PokeBinderSpacing.sp1),
                            Text(
                              'Your collection at a glance.',
                              style: PokeBinderText.subtitle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),
                FadeSlideIn(
                  index: 1,
                  child: CollectionSearchBar(
                    hint: 'Search your whole collection…',
                    enabled: false,
                    onTap: widget.onOpenAllCards,
                  ),
                ),
                const SizedBox(height: PokeBinderSpacing.sp3),
                FadeSlideIn(
                  index: 2,
                  child: Row(
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
                          onTap: _openStats,
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
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),
                Text('QUICK ACTIONS', style: PokeBinderText.sectionLabel),
                const SizedBox(height: PokeBinderSpacing.sp2),
                FadeSlideIn(
                  index: 3,
                  child: Row(
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
                          onTap: _openNewDeck,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),
                if (continueBinder != null) ...[
                  FadeSlideIn(
                    index: 4,
                    child: _ContinueBinderPanel(
                      binder: continueBinder,
                      onTap: () => widget.onOpenBinder(continueBinder),
                    ),
                  ),
                  const SizedBox(height: PokeBinderSpacing.sp4),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'RECENTLY ADDED',
                        style: PokeBinderText.sectionLabel,
                      ),
                    ),
                    if (_cards.isNotEmpty)
                      MinTapTarget(
                        onTap: widget.onOpenAllCards,
                        child: Text(
                          'View All',
                          style: PokeBinderText.chipLabel.copyWith(
                            color: PokeBinderColors.redDeep,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp2),
                FadeSlideIn(
                  index: 5,
                  child: Row(
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
                      for (var i = recentCards.length; i < 3; i++) ...[
                        if (i != 0) const SizedBox(width: PokeBinderSpacing.sp2),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: PokeBinderSpacing.sp4),
                FadeSlideIn(
                  index: 6,
                  child: PillButton(
                    label: 'Add a New Card',
                    icon: Icons.add_rounded,
                    onTap: widget.onOpenAdd,
                  ),
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

class _TrainerAvatarButton extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;

  const _TrainerAvatarButton({required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: TrainerAvatar(
          imageUrl: imageUrl,
          size: 50,
          iconSize: 24,
          shadow: [
            BoxShadow(
              color: PokeBinderColors.redDeep.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
              spreadRadius: -2,
            ),
          ],
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
          padding: const EdgeInsets.symmetric(
            vertical: PokeBinderSpacing.sp3,
            horizontal: PokeBinderSpacing.sp1,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PokeBinderColors.white, Color(0xFFFBF7EC)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
            boxShadow: kCardElevation,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CountUpText(value, style: PokeBinderText.statNumber),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                label.toUpperCase(),
                style: PokeBinderText.statLabel.copyWith(letterSpacing: 1.4),
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
          padding: const EdgeInsets.all(PokeBinderSpacing.sp3),
          decoration: BoxDecoration(
            color: PokeBinderColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
            boxShadow: kCardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('CONTINUE A BINDER', style: PokeBinderText.sectionLabel),
                  if (binder.isPinned) ...[
                    const SizedBox(width: PokeBinderSpacing.sp1),
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
                          style: PokeBinderText.rowTitle,
                        ),
                        const SizedBox(height: PokeBinderSpacing.sp0),
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
        CardCaption(card: card),
      ],
    );
  }
}
