import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';

class TrainerCardScreen extends StatelessWidget {
  final String trainerName;
  final String trainerTitle;
  final String favoritePokemon;
  final VoidCallback onBack;
  final ValueChanged<BinderData>? onOpenBinder;

  const TrainerCardScreen({
    super.key,
    this.trainerName = 'Ash',
    this.trainerTitle = 'Gym Leader',
    this.favoritePokemon = 'Pikachu',
    required this.onBack,
    this.onOpenBinder,
  });

  int get _totalCardCount =>
      PokemonCardData.library.fold(0, (sum, c) => sum + c.quantityOwned);

  PokemonCardData? get _favoriteCard {
    final library = PokemonCardData.library;
    if (library.isEmpty) return null;
    final byName = library.where(
      (c) => c.name.toLowerCase() == favoritePokemon.toLowerCase(),
    );
    return byName.isNotEmpty ? byName.first : library.first;
  }

  BinderData? get _favoriteBinder {
    final binders = BinderData.sampleBinders;
    if (binders.isEmpty) return null;
    final pinned = binders.where((b) => b.isPinned).toList()
      ..sort((a, b) => b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch));
    if (pinned.isNotEmpty) return pinned.first;
    final byRecency = [...binders]
      ..sort((a, b) => b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch));
    return byRecency.first;
  }

  void _editComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trainer card editing is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final binderCount = BinderData.sampleBinders.length;
    final favoriteBinder = _favoriteBinder;

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
                  BackLink(label: '‹ More', onTap: onBack),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _editComingSoon(context),
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
                favoriteCard: _favoriteCard,
              ),
              const SizedBox(height: PokeBinderSpacing.sp3),

              Row(
                children: [
                  Expanded(
                    child: _TrainerStatBox(
                      value: '$_totalCardCount',
                      label: 'Total cards',
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: _TrainerStatBox(
                      value: '$binderCount',
                      label: 'Binders',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              Text('FAVORITE BINDER', style: PokeBinderText.sectionLabel),
              const SizedBox(height: PokeBinderSpacing.sp2),
              favoriteBinder != null
                  ? _FavoriteBinderPanel(
                      binder: favoriteBinder,
                      onTap: onOpenBinder == null
                          ? null
                          : () => onOpenBinder!(favoriteBinder),
                    )
                  : const _DashedInfoPanel(
                      icon: Icons.push_pin_outlined,
                      message: 'Pin a binder to feature it here.',
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
                  Text(
                    'Coming soon',
                    style: PokeBinderText.chakraPetch(const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: PokeBinderColors.goldDeep,
                    )),
                  ),
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

class _TrainerHeaderPanel extends StatelessWidget {
  final String trainerName;
  final String trainerTitle;
  final PokemonCardData? favoriteCard;

  const _TrainerHeaderPanel({
    required this.trainerName,
    required this.trainerTitle,
    required this.favoriteCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: PokeBinderSpacing.sp5,
        horizontal: PokeBinderSpacing.sp4,
      ),
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
      child: Column(
        children: [
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
          const SizedBox(height: PokeBinderSpacing.sp3),
          Text(
            trainerName,
            style: PokeBinderText.chakraPetch(const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
              color: PokeBinderColors.ink,
            )),
          ),
          const SizedBox(height: 3),
          Text(trainerTitle, style: PokeBinderText.subtitle),
          const SizedBox(height: PokeBinderSpacing.sp3),
          Container(
            height: 1,
            width: 40,
            color: PokeBinderColors.ink.withValues(alpha: 0.08),
          ),
          const SizedBox(height: PokeBinderSpacing.sp3),
          favoriteCard != null
              ? _FavoriteCardTag(card: favoriteCard!)
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _FavoriteCardTag extends StatelessWidget {
  final PokemonCardData card;

  const _FavoriteCardTag({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PokeBinderSpacing.sp4,
        vertical: PokeBinderSpacing.sp2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: PokeBinderColors.redGradient,
        boxShadow: [
          BoxShadow(
            color: PokeBinderColors.redDeep.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 12,
                color: PokeBinderColors.white,
              ),
              const SizedBox(width: 5),
              Text('Favorite Card', style: PokeBinderText.chipLabelActive),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            card.name,
            style: PokeBinderText.chakraPetch(const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: PokeBinderColors.white,
            )),
          ),
          Text(
            '${card.setName} • #${card.cardNumber}',
            style: PokeBinderText.chakraPetch(TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: PokeBinderColors.white.withValues(alpha: 0.85),
            )),
          ),
        ],
      ),
    );
  }
}

class _TrainerStatBox extends StatelessWidget {
  final String value;
  final String label;

  const _TrainerStatBox({required this.value, required this.label});

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
              Container(
                width: 44,
                height: 44,
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
          child: Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: PokeBinderColors.inkSoft.withValues(alpha: 0.5),
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