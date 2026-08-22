import 'package:flutter/material.dart';

import '../models/pokemon_card_data.dart';
import '../theme/pokebinder_theme.dart';
import 'pokemon_card_widget.dart';

class BinderCardTile extends StatelessWidget {
  final PokemonCardData card;
  final VoidCallback? onTap;

  const BinderCardTile({super.key, required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = card.imageAssetPath != null;

    return AspectRatio(
      aspectRatio: kPokemonCardAspectRatio,
      child: GestureDetector(
        onTap: onTap,
        child: hasImage
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: PokeBinderColors.ink.withValues(alpha: 0.16),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(card.imageAssetPath!, fit: BoxFit.cover),
                ),
              )
            : const PokemonCardBack(),
      ),
    );
  }
}

class AddCardTile extends StatelessWidget {
  final VoidCallback? onTap;

  const AddCardTile({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kPokemonCardAspectRatio,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedRRectPainter(),
          child: const Center(
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: PokeBinderColors.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = PokeBinderColors.ink.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}