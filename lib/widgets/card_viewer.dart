import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';
import 'interactive_3d_card.dart';
import 'pokemon_card_widget.dart';

/// Share of the screen the full-size card may take up.
const double _kViewerWidthFraction = 0.78;
const double _kViewerHeightFraction = 0.7;

/// Opens [imagePath] full size as the same draggable 3D card used on the card
/// details screen. Tap outside the card, or the close button, to dismiss.
Future<void> showCardViewer(
  BuildContext context, {
  required String imagePath,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close card',
    barrierColor: PokeBinderColors.ink.withValues(alpha: 0.85),
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (_, __, ___) => _CardViewer(imagePath: imagePath),
  );
}

class _CardViewer extends StatelessWidget {
  final String imagePath;

  const _CardViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(
              constraints.maxWidth * _kViewerWidthFraction,
              constraints.maxHeight *
                  _kViewerHeightFraction *
                  kPokemonCardImageAspectRatio,
            );
            // The close button sits just above the card's top-right corner,
            // in line with its edge, rather than out at the screen's corner.
            return SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerRight,
                    icon: const Icon(Icons.close_rounded,
                        color: PokeBinderColors.white),
                  ),
                  AspectRatio(
                    aspectRatio: kPokemonCardImageAspectRatio,
                    child: Interactive3DCard(
                      back: const PokemonCardBack(),
                      child: PokemonCardArt(imagePath: imagePath),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
