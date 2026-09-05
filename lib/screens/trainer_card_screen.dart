import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../models/trainer_profile_data.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import 'card_details_screen.dart';
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
    final matches = DeckData.library.where((d) => d.id == id);
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

  Future<void> _openFavoriteCardDetails(PokemonCardData card) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardDetailsScreen(
          card: card,
          binders: BinderData.sampleBinders,
          onSave: (oldCard, result) {
            setState(() {
              final index =
                  PokemonCardData.library.indexWhere((c) => c.id == oldCard.id);
              if (index == -1) return;
              if (result.deleted) {
                PokemonCardData.library.removeAt(index);
                if (_profile.favoriteCardId == oldCard.id) {
                  _profile = _profile.copyWith(favoriteCardId: null);
                }
              } else {
                PokemonCardData.library[index] = result.card!;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainerName = _profile.name;
    final trainerTitle = _profile.title;
    final bio = _profile.bio;
    final binderCount = BinderData.sampleBinders.length;
    final deckCount = DeckData.library.length;
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
                  ? _FavoriteCardPanel(
                      card: favoriteCard,
                      onTap: () => _openFavoriteCardDetails(favoriteCard),
                    )
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

/// Displays the trainer's favorite card the same way a card entry reads on
/// the Deck Details list: thumbnail, name, set/number, an "Own N" line,
/// rarity + condition tags, and an italic notes line. Tapping the panel
/// opens the card's details, signposted by a trailing chevron.
class _FavoriteCardPanel extends StatelessWidget {
  final PokemonCardData card;
  final VoidCallback onTap;

  const _FavoriteCardPanel({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PokeBinderColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
        boxShadow: kCardElevation,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: PokeBinderColors.ink.withValues(alpha: 0.08),
                    ),
                    boxShadow: kCardElevation,
                  ),
                  child: CardThumbnail(
                    card: card,
                    width: 92,
                    height: 127,
                    borderRadius: 5,
                  ),
                ),
                const SizedBox(width: PokeBinderSpacing.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: PokeBinderText.chakraPetch(const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: PokeBinderColors.ink,
                        )),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${card.setName} · #${card.cardNumber}',
                        style: PokeBinderText.listRowSubtitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Own ${card.quantityOwned}',
                        style: PokeBinderText.listRowSubtitle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: PokeBinderColors.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _RarityTag(rarity: card.rarity),
                          _ConditionTag(code: card.condition),
                        ],
                      ),
                      if (card.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          card.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: PokeBinderText.listRowSubtitle.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: PokeBinderSpacing.sp1),
                SizedBox(
                  height: 127,
                  child: Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: PokeBinderColors.inkSoft,
                    ),
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

/// Small icon + label pairing for a card's rarity, reusing the app's
/// shared [rarityIconFor] lookup so it stays in sync with the dropdown
/// icons used elsewhere (card form, wishlist, trade entry).
class _RarityTag extends StatelessWidget {
  final String rarity;

  const _RarityTag({required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(rarityIconFor(rarity), size: 11, color: PokeBinderColors.goldDeep),
        const SizedBox(width: 4),
        Text(rarity, style: PokeBinderText.listRowSubtitle),
      ],
    );
  }
}

/// Small icon + label pairing for a card's condition, reusing the app's
/// shared [conditionIconFor] lookup and expanding the stored code (e.g.
/// 'NM') to its full label via [kConditionOptions] — same source of
/// truth as the condition dropdown in the card/wishlist/trade forms.
class _ConditionTag extends StatelessWidget {
  final String code;

  const _ConditionTag({required this.code});

  @override
  Widget build(BuildContext context) {
    final label = kConditionOptions
        .firstWhere((c) => c.$2 == code, orElse: () => (code, code))
        .$1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(conditionIconFor(code), size: 11, color: PokeBinderColors.teal),
        const SizedBox(width: 4),
        Text(label, style: PokeBinderText.listRowSubtitle),
      ],
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