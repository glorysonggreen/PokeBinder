import 'package:flutter/material.dart';
import '../models/binder_data.dart';
import '../models/deck_data.dart';
import '../models/pokemon_card_data.dart';
import '../models/trainer_profile_data.dart';
import '../services/audio_navigator_observer.dart';
import '../services/card_repository.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/card_tags.dart';
import '../widgets/pokebinder_controls.dart';
import '../widgets/pokemon_card_widget.dart';
import '../widgets/trainer_avatar.dart';
import 'binders_screen.dart';
import 'card_details_screen.dart';
import 'decks_screen.dart';
import 'trainer_card_edit_screen.dart';
import '../widgets/pokebinder_background.dart';

class TrainerCardScreen extends StatefulWidget {
  final TrainerProfileData profile;
  final VoidCallback onBack;
  final ValueChanged<TrainerProfileData>? onProfileChanged;

  const TrainerCardScreen({
    super.key,
    required this.profile,
    required this.onBack,
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
    final matches = BinderData.library.where((b) => b.id == id);
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

  /// Opens the binder on top of the Trainer Card. Back from the binder
  /// returns here, because the binder is pushed onto this screen's navigator
  /// rather than switching the app to the Binders tab.
  Future<void> _openFavoriteBinder(BinderData binder) async {
    await Navigator.of(context).push(
      SilentPageRoute<void>(
        builder: (_) => BindersScreen(
          initialBinderId: binder.id,
          popOnDetailClose: true,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// Opens the deck on top of the Trainer Card; Back returns here.
  Future<void> _openFavoriteDeck(DeckData deck) async {
    await Navigator.of(context).push(
      SilentPageRoute<void>(
        builder: (_) => DecksScreen(
          initialDeckId: deck.id,
          popOnDetailClose: true,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openFavoriteCardDetails(PokemonCardData card) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardDetailsScreen(
          card: card,
          binders: BinderData.library,
          onSave: (oldCard, result) {
            setState(() {
              final index =
                  PokemonCardData.library.indexWhere((c) => c.id == oldCard.id);
              if (index == -1) return;
              if (result.deleted) {
                PokemonCardData.library.removeAt(index);
                CardRepository.delete(oldCard.id);
                if (_profile.favoriteCardId == oldCard.id) {
                  _profile = _profile.copyWith(favoriteCardId: null);
                  widget.onProfileChanged?.call(_profile);
                }
              } else {
                PokemonCardData.library[index] = result.card!;
                CardRepository.upsert(result.card!);
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
    final binderCount = BinderData.library.length;
    final deckCount = DeckData.library.length;
    final favoriteCard = _favoriteCard;
    final favoriteBinder = _favoriteBinder;
    final favoriteDeck = _favoriteDeck;

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
                  BackLink(onTap: widget.onBack),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _openEdit(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PokeBinderSpacing.sp1,
                          vertical: PokeBinderSpacing.sp1,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              size: 12,
                              color: PokeBinderColors.redDeep,
                            ),
                            const SizedBox(width: PokeBinderSpacing.sp1),
                            Text('Edit', style: PokeBinderText.backLink),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('TRAINER CARD', style: PokeBinderText.eyebrow),
              const SizedBox(height: PokeBinderSpacing.sp4),

              _TrainerHeaderPanel(
                trainerName: trainerName,
                trainerTitle: trainerTitle,
                bio: bio,
                avatarUrl: _profile.avatarUrl,
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
                      onTap: () => _openFavoriteBinder(favoriteBinder),
                    )
                  : const _DashedInfoPanel(
                      icon: Icons.push_pin_outlined,
                      message: 'Set a favorite binder to feature it here.',
                    ),
              const SizedBox(height: PokeBinderSpacing.sp5),

              Text('FAVORITE DECK', style: PokeBinderText.sectionLabel),
              const SizedBox(height: PokeBinderSpacing.sp2),
              favoriteDeck != null
                  ? _FavoriteDeckPanel(
                      deck: favoriteDeck,
                      onTap: () => _openFavoriteDeck(favoriteDeck),
                    )
                  : const _DashedInfoPanel(
                      icon: Icons.push_pin_outlined,
                      message: 'Set a favorite deck to feature it here.',
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
  final String? bio;
  final String? avatarUrl;

  const _TrainerHeaderPanel({
    required this.trainerName,
    required this.trainerTitle,
    required this.bio,
    required this.avatarUrl,
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
                    TrainerAvatar(
                      imageUrl: avatarUrl,
                      size: 82,
                      iconSize: 36,
                      borderWidth: 3,
                      shadow: [
                        BoxShadow(
                          color: PokeBinderColors.redDeep.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: PokeBinderSpacing.sp3),
                Text(
                  trainerName,
                  style: PokeBinderText.headingSm,
                ),
                const SizedBox(height: PokeBinderSpacing.sp2),
                Container(
                  padding: PokeBinderSpacing.chip,
                  decoration: BoxDecoration(
                    color: PokeBinderColors.cream2.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: PokeBinderColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    trainerTitle.toUpperCase(),
                    style: PokeBinderText.eyebrow.copyWith(
                      color: PokeBinderColors.goldDeep,
                    ),
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
            padding: const EdgeInsets.fromLTRB(
              PokeBinderSpacing.sp2,
              PokeBinderSpacing.sp3,
              PokeBinderSpacing.sp2,
              PokeBinderSpacing.sp3,
            ),
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
                        style: PokeBinderText.rowTitle,
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp1),
                      Text(
                        '${card.setName} · #${card.cardNumber}',
                        style: PokeBinderText.listRowSubtitle,
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp0),
                      Text(
                        'Own ${card.quantityOwned}',
                        style: PokeBinderText.listRowSubtitle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: PokeBinderColors.ink,
                        ),
                      ),
                      const SizedBox(height: PokeBinderSpacing.sp2),
                      Wrap(
                        spacing: PokeBinderSpacing.sp2,
                        runSpacing: PokeBinderSpacing.sp1,
                        children: [
                          RarityTag(rarity: card.rarity),
                          ConditionTag(code: card.condition),
                        ],
                      ),
                      if (card.notes.isNotEmpty) ...[
                        const SizedBox(height: PokeBinderSpacing.sp1),
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
      padding: const EdgeInsets.symmetric(
        vertical: PokeBinderSpacing.sp4,
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
          Text(value, style: PokeBinderText.statNumber),
          const SizedBox(height: PokeBinderSpacing.sp1),
          Text(
            label,
            style: PokeBinderText.statLabel.copyWith(letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}

class _FavoriteBinderPanel extends StatelessWidget {
  final BinderData binder;
  final VoidCallback onTap;

  const _FavoriteBinderPanel({required this.binder, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                            style: PokeBinderText.rowTitle,
                          ),
                        ),
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
        ),
      ),
    );
  }
}

class _FavoriteDeckPanel extends StatelessWidget {
  final DeckData deck;
  final VoidCallback onTap;

  const _FavoriteDeckPanel({required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
            border:
                Border.all(color: PokeBinderColors.ink.withValues(alpha: 0.08)),
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
                            style: PokeBinderText.rowTitle,
                          ),
                        ),
                        if (deck.isPinned) ...[
                          const SizedBox(width: PokeBinderSpacing.sp1),
                          const Icon(
                            Icons.push_pin_rounded,
                            size: 11,
                            color: PokeBinderColors.redDeep,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: PokeBinderSpacing.sp0),
                    Text(
                      '${deck.cardCount}/${deck.targetSize} cards · ${deck.format.label}',
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
