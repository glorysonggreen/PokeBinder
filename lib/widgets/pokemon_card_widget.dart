import 'package:flutter/material.dart';
import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';

class PokemonCard extends StatelessWidget {
  final PokemonCardData card;

  const PokemonCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final hasImage = card.imageAssetPath != null;

    return _CardFrame(
      background: hasImage
          ? null
          : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: card.type.gradientColors,
              ),
            ),
      showInsetBorder: !hasImage,
      child: hasImage
          ? _CardImage(assetPath: card.imageAssetPath!)
          : const _CardSilhouette(),
    );
  }
}

/// A small rectangular thumbnail used in compact list rows (deck lists,
/// card pickers, etc.). Shows the card's artwork when available, otherwise
/// falls back to a type-colored gradient swatch.
class CardThumbnail extends StatelessWidget {
  final PokemonCardData? card;
  final double width;
  final double height;
  final double borderRadius;

  const CardThumbnail({
    super.key,
    required this.card,
    this.width = 26,
    this.height = 36,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final path = card?.imageAssetPath;
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: path == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: card?.type.gradientColors ??
                    const [Color(0xFFE6E6E6), Color(0xFFBDBDBD)],
              )
            : null,
      ),
      child: path != null ? Image.asset(path, fit: BoxFit.contain) : null,
    );
  }
}

class PokemonCardBack extends StatelessWidget {
  const PokemonCardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CardFrame(
      background: BoxDecoration(color: PokeBinderColors.redDeep),
      showInsetBorder: false,
      child: _CardImage(assetPath: kPokemonCardBackAssetPath),
    );
  }
}

class _CardFrame extends StatelessWidget {
  final Widget child;
  final BoxDecoration? background;
  final bool showInsetBorder;

  const _CardFrame({
    required this.child,
    required this.showInsetBorder,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: (background ?? const BoxDecoration()).copyWith(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: PokeBinderColors.ink.withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,

            if (showInsetBorder)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: PokeBinderColors.white.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                ),
              ),

            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1, -1),
                      end: Alignment(0.2, 0.4),
                      colors: [
                        Color(0x59FFFFFF),
                        Color(0x00FFFFFF),
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

class _CardImage extends StatelessWidget {
  final String assetPath;

  const _CardImage({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetPath, fit: BoxFit.contain);
  }
}

class _CardSilhouette extends StatelessWidget {
  const _CardSilhouette();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SilhouettePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    final cx = size.width / 2;
    final cy = size.height * 0.6;
    final r = size.width * 0.27;

    canvas.drawCircle(Offset(cx, cy), r, paint);

    final earPath = Path()
      ..moveTo(cx - r * 1.4, cy - r * 1.2)
      ..lineTo(cx - r * 0.6, cy - r * 2.4)
      ..lineTo(cx - r * 0.2, cy - r * 1.4)
      ..close();
    canvas.drawPath(earPath, paint);

    final earPath2 = Path()
      ..moveTo(cx + r * 1.4, cy - r * 1.2)
      ..lineTo(cx + r * 0.6, cy - r * 2.4)
      ..lineTo(cx + r * 0.2, cy - r * 1.4)
      ..close();
    canvas.drawPath(earPath2, paint);

    final eyePaint = Paint()..color = PokeBinderColors.ink;
    canvas.drawCircle(Offset(cx - r * 0.4, cy - r * 0.05), r * 0.09, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.4, cy - r * 0.05), r * 0.09, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}