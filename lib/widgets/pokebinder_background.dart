import 'package:flutter/material.dart';

import '../theme/pokebinder_theme.dart';

/// The artwork behind a screen.
///
/// Drop the image files in `assets/backgrounds/` (the folder is already
/// declared in pubspec.yaml). Recommended size is 1290 x 2796 px, saved as
/// JPG (or WebP) to keep the app light.
enum PokeBinderBackdrop {
  /// Large, calm arcs. The default: quiet enough for text-heavy screens.
  arcs('assets/backgrounds/BG1.jpg'),

  /// Busier Poke Ball / dot-grid art, used on the welcome-style screens
  /// (Home and the log in / sign up flow).
  pokeball('assets/backgrounds/BG2.jpg');

  const PokeBinderBackdrop(this.assetPath);
  final String assetPath;
}

/// Paints [backdrop] edge to edge behind [child].
///
/// The cream colour sits underneath, so if an image is missing or still
/// decoding the screen simply looks the way it did before.
class PokeBinderBackground extends StatelessWidget {
  final PokeBinderBackdrop backdrop;
  final Widget child;

  const PokeBinderBackground({
    super.key,
    this.backdrop = PokeBinderBackdrop.arcs,
    required this.child,
  });

  /// Loads every backdrop into the image cache so screens never flash cream
  /// while a background decodes. Safe to call more than once.
  static void precacheAll(BuildContext context) {
    for (final backdrop in PokeBinderBackdrop.values) {
      precacheImage(
        AssetImage(backdrop.assetPath),
        context,
        onError: (_, __) {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: PokeBinderColors.cream),
        // Its own layer, so scrolling content above never repaints the image.
        RepaintBoundary(
          child: Image.asset(
            backdrop.assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        child,
      ],
    );
  }
}

/// A [Scaffold] that shows a [PokeBinderBackground].
///
/// The image lives *outside* the Scaffold, so it stays put (and is not
/// squashed or re-cropped) when the keyboard opens. Each screen draws its own
/// background, which keeps page transitions clean: the artwork slides with
/// the page instead of staying fixed underneath it.
class PokeBinderScaffold extends StatelessWidget {
  final PokeBinderBackdrop backdrop;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const PokeBinderScaffold({
    super.key,
    this.backdrop = PokeBinderBackdrop.arcs,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return PokeBinderBackground(
      backdrop: backdrop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
