import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/pokebinder_theme.dart';

enum PokeBinderBackdrop {
  arcs('assets/backgrounds/BG1.jpg'),
  pokeball('assets/backgrounds/BG2.jpg');

  const PokeBinderBackdrop(this.assetPath);
  final String assetPath;
}

class PokeBinderBackground extends StatelessWidget {
  final PokeBinderBackdrop backdrop;
  final Widget child;

  const PokeBinderBackground({
    super.key,
    this.backdrop = PokeBinderBackdrop.arcs,
    required this.child,
  });

  static const int _maxDecodeWidth = 1080;

  static ImageProvider _provider(BuildContext context, String assetPath) {
    final width = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .round();
    return ResizeImage(
      AssetImage(assetPath),
      width: math.min(math.max(width, 1), _maxDecodeWidth),
    );
  }

  static void precacheAll(BuildContext context) {
    for (final backdrop in PokeBinderBackdrop.values) {
      precacheImage(
        _provider(context, backdrop.assetPath),
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
        RepaintBoundary(
          child: Image(
            image: _provider(context, backdrop.assetPath),
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
