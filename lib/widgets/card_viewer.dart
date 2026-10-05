import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/pokebinder_motion.dart';
import '../theme/pokebinder_theme.dart';
import 'interactive_3d_card.dart';
import 'pokemon_card_widget.dart';

const double _kViewerWidthFraction = 0.78;
const double _kViewerHeightFraction = 0.7;

Future<void> showCardViewer(
  BuildContext context, {
  required String imagePath,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close card',
    barrierColor: PokeBinderColors.ink.withValues(alpha: 0.85),
    transitionDuration: PokeBinderMotion.adapt(context, PokeBinderMotion.viewer),
    transitionBuilder: (context, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return FadeTransition(opacity: animation, child: child);
      }
      // The card rises out of the binder: the backdrop blurs, and the card
      // zooms up from 80% with a little overshoot.
      final zoom = animation.drive(CurveTween(curve: Curves.easeOutBack));
      return Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final sigma = 5 * Curves.easeOut.transform(animation.value);
              return ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1).animate(zoom),
              child: child,
            ),
          ),
        ],
      );
    },
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
                  const SizedBox(height: PokeBinderSpacing.sp4),
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
