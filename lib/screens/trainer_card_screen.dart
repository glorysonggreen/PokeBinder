import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../models/trainer_profile_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'trainer_card_edit_screen.dart';

class TrainerCardScreen extends StatefulWidget {
  final TrainerProfileData profile;
  final VoidCallback onBack;
  final ValueChanged<BinderData>? onOpenBinder;
  final ValueChanged<TrainerProfileData>? onProfileChanged;

  const TrainerCardScreen({
    super.key,
    required this.profile,
    required this.onBack,
    this.onOpenBinder,
    this.onProfileChanged,
  });

  @override
  State<TrainerCardScreen> createState() => _TrainerCardScreenState();
}

class _TrainerCardScreenState extends State<TrainerCardScreen> {
  late TrainerProfileData _profile = widget.profile;

  int get _totalCardCount =>
      PokemonCardData.library.fold(0, (sum, c) => sum + c.quantityOwned);

  PokemonCardData? get _favoriteCard {
    final id = _profile.favoriteCardId;
    if (id == null) return null;
    final matches = PokemonCardData.library.where((c) => c.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  BinderData? get _favoriteBinder {
    final id = _profile.favoriteBinderId;
    if (id == null) return null;
    final matches = BinderData.sampleBinders.where((b) => b.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  DeckData? get _favoriteDeck {
    final id = _profile.favoriteDeckId;
    if (id == null) return null;
    final matches = DeckData.sampleDecks.where((d) => d.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<void> _openEdit(BuildContext context) async {
    final result = await Navigator.of(context).push<TrainerProfileData>(
      MaterialPageRoute(
        builder: (_) => TrainerCardEditScreen(profile: _profile),
      ),
    );
    if (result == null) return;
    setState(() => _profile = result);
    widget.onProfileChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final trainerName = _profile.name;
    final trainerTitle = _profile.title;
    final bio = _profile.bio;
    final binderCount = BinderData.sampleBinders.length;
    final deckCount = DeckData.sampleDecks.length;
    final favoriteCard = _favoriteCard;
    final favoriteBinder = _favoriteBinder;
    final favoriteDeck = _favoriteDeck;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BackLink(onTap: widget.onBack),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _openEdit(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              size: 12,
                              color: PokeBinderColors.redDeep,
                            ),
                            const SizedBox(width: 4),
                            Text('Edit', style: PokeBinderText.backLink),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text('TRAINER CARD', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp3),

              _TrainerHeaderPanel(
                trainerName: trainerName,
                trainerTitle: trainerTitle,
                bio: bio,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              Row(
                children: [
                  Expanded(
                    child: _TrainerStatBox(
                      value: '$_totalCardCount',
                      label: 'TOTAL CARDS',
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: _TrainerStatBox(
                      value: '$binderCount',
                      label: 'BINDERS',
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: _TrainerStatBox(
                      value: '$deckCount',
                      label: 'DECKS',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              Text('FAVORITE CARD', style: PokeBinderText.sectionLabel),
              const SizedBox(height: PokeBinderSpacing.sp2),
              favoriteCard != null
                  ? _FavoriteCardPanel(card: favoriteCard)
                  : const _DashedInfoPanel(
                      icon: Icons.star_outline_rounded,
                      message: 'Set a favorite card to feature it here.',
                    ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              Text('FAVORITE BINDER', style: PokeBinderText.sectionLabel),
              const SizedBox(height: PokeBinderSpacing.sp2),
              favoriteBinder != null
                  ? _FavoriteBinderPanel(
                      binder: favoriteBinder,
                      onTap: widget.onOpenBinder == null
                          ? null
                          : () => widget.onOpenBinder!(favoriteBinder),
                    )
                  : const _DashedInfoPanel(
                      icon: Icons.push_pin_outlined,
                      message: 'Set a favorite binder to feature it here.',
                    ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              Text('FAVORITE DECK', style: PokeBinderText.sectionLabel),
              const SizedBox(height: PokeBinderSpacing.sp2),
              favoriteDeck != null
                  ? _FavoriteDeckPanel(deck: favoriteDeck)
                  : const _DashedInfoPanel(
                      icon: Icons.push_pin_outlined,
                      message: 'Set a favorite deck to feature it here.',
                    ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'ACHIEVEMENT BADGES',
                      style: PokeBinderText.sectionLabel,
                    ),
                  ),
                  const _SoftPill(label: 'COMING SOON'),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              const Row(
                children: [
                  Expanded(child: _LockedBadgeSlot()),
                  SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(child: _LockedBadgeSlot()),
                  SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(child: _LockedBadgeSlot()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String label;

  const _SoftPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PokeBinderColors.cream2.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PokeBinderColors.gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: PokeBinderText.chakraPetch(const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: PokeBinderColors.goldDeep,
        )),
      ),
    );
  }
}

class _TrainerHeaderPanel extends StatelessWidget {
  final String trainerName;
  final String trainerTitle;
  final String? bio;

  const _TrainerHeaderPanel({
    required this.trainerName,
    required this.trainerTitle,
    required this.bio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PokeBinderColors.white, Color(0xFFF7EFE0)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -22,
            top: -22,
            child: Transform.rotate(
              angle: -0.35,
              child: Icon(
                Icons.catching_pokemon,
                size: 132,
                color: PokeBinderColors.redDeep.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: PokeBinderSpacing.sp5,
              horizontal: PokeBinderSpacing.sp4,
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PokeBinderColors.gold.withValues(alpha: 0.32),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 82,
                      height: 82,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: PokeBinderColors.redGradient,
                        border: Border.all(color: PokeBinderColors.gold, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: PokeBinderColors.redDeep.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.catching_pokemon,
                        size: 36,
                        color: PokeBinderColors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp3),
                Text(
                  trainerName,
                  style: PokeBinderText.chakraPetch(const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                    color: PokeBinderColors.ink,
                  )),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: PokeBinderColors.cream2.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: PokeBinderColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    trainerTitle.toUpperCase(),
                    style: PokeBinderText.chakraPetch(const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: PokeBinderColors.goldDeep,
                    )),
                  ),
                ),
                if (bio != null && bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: PokeBinderSpacing.sp4),
                  Container(
                    height: 1,
                    width: 40,
                    color: PokeBinderColors.ink.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: PokeBinderSpacing.sp4),
                  Text(
                    bio!,
                    textAlign: TextAlign.center,
                    style: PokeBinderText.listRowSubtitle.copyWith(
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCardPanel extends StatelessWidget {
  final PokemonCardData card;

  const _FavoriteCardPanel({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: AspectRatio(
              aspectRatio: kPokemonCardAspectRatio,
              child: PokemonCard(card: card),
            ),
          ),
          const SizedBox(width: PokeBinderSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: PokeBinderColors.goldDeep,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Favorite Card',
                      style: PokeBinderText.chipLabel.copyWith(
                        color: PokeBinderColors.goldDeep,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  card.name,
                  overflow: TextOverflow.ellipsis,
                  style: PokeBinderText.listRowTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${card.setName} · #${card.cardNumber}',
                  overflow: TextOverflow.ellipsis,
                  style: PokeBinderText.listRowSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerStatBox extends StatelessWidget {
  final String value;
  final String label;

  const _TrainerStatBox({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
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
          Text(value, style: PokeBinderText.statNumber),
          const SizedBox(height: 3),
          Text(
            label,
            style: PokeBinderText.statLabel.copyWith(letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}

class _FavoriteBinderPanel extends StatelessWidget {
  final BinderData binder;
  final VoidCallback? onTap;

  const _FavoriteBinderPanel({required this.binder, this.onTap});

  @override
  Widget build(BuildContext context) {
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
            boxShadow: kCardElevation,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: PokeBinderColors.redGradient,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: PokeBinderColors.white,
                  ),
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            binder.name,
                            overflow: TextOverflow.ellipsis,
                            style: PokeBinderText.listRowTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
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
                    const SizedBox(height: 2),
                    Text(
                      '${binder.pageCount} pages · ${binder.cardCount} cards',
                      style: PokeBinderText.listRowSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PokeBinderSpacing.sp2),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: PokeBinderColors.inkSoft,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteDeckPanel extends StatelessWidget {
  final DeckData deck;

  const _FavoriteDeckPanel({required this.deck});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: PokeBinderColors.redGradient,
              ),
              child: const Icon(
                Icons.style_rounded,
                size: 18,
                color: PokeBinderColors.white,
              ),
            ),
          ),
          const SizedBox(width: PokeBinderSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        deck.name,
                        overflow: TextOverflow.ellipsis,
                        style: PokeBinderText.listRowTitle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (deck.isPinned) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.push_pin_rounded,
                        size: 11,
                        color: PokeBinderColors.redDeep,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${deck.cardCount}/${deck.targetSize} cards · ${deck.format.label}',
                  style: PokeBinderText.listRowSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedInfoPanel extends StatelessWidget {
  final IconData icon;
  final String message;

  const _DashedInfoPanel({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(radius: 14),
      child: Container(
        padding: const EdgeInsets.all(PokeBinderSpacing.sp3),
        decoration: BoxDecoration(
          color: PokeBinderColors.cream2.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: PokeBinderColors.inkSoft.withValues(alpha: 0.7)),
            const SizedBox(width: PokeBinderSpacing.sp2),
            Expanded(
              child: Text(message, style: PokeBinderText.listRowSubtitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedBadgeSlot extends StatelessWidget {
  const _LockedBadgeSlot();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(radius: 12),
        child: Container(
          decoration: BoxDecoration(
            color: PokeBinderColors.cream2.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: PokeBinderColors.inkSoft.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'LOCKED',
                  style: PokeBinderText.chakraPetch(TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: PokeBinderColors.inkSoft.withValues(alpha: 0.45),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double radius;

  const _DashedBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = PokeBinderColors.ink.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const dashWidth = 5.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}