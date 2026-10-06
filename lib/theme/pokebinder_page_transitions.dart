import 'package:flutter/material.dart';

import 'pokebinder_motion.dart';

class PokeBinderPageTransitionsBuilder extends PageTransitionsBuilder {
  const PokeBinderPageTransitionsBuilder();

  static final _slide = Tween<Offset>(
    begin: const Offset(0, 0.035),
    end: Offset.zero,
  );
  static final _scale = Tween<double>(begin: 0.97, end: 1);
  static final _fadeIn = CurveTween(
    curve: const Interval(0, 0.65, curve: Curves.easeOut),
  );
  static final _fadeOut = Tween<double>(begin: 1, end: 0.82);
  static final _ease = CurveTween(curve: PokeBinderMotion.emphasized);

  @override
  Duration get transitionDuration => PokeBinderMotion.page;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final eased = animation.drive(_ease);

    return FadeTransition(
      opacity: secondaryAnimation.drive(_ease).drive(_fadeOut),
      child: FadeTransition(
        opacity: animation.drive(_fadeIn),
        child: SlideTransition(
          position: eased.drive(_slide),
          child: ScaleTransition(
            scale: eased.drive(_scale),
            child: child,
          ),
        ),
      ),
    );
  }
}
