import 'package:flutter/material.dart';

class PokeBinderMotion {
  PokeBinderMotion._();

  static const press = Duration(milliseconds: 100);
  static const release = Duration(milliseconds: 320);
  static const fast = Duration(milliseconds: 150);
  static const enter = Duration(milliseconds: 380);
  static const pop = Duration(milliseconds: 420);
  static const count = Duration(milliseconds: 900);

  /// Route push / pop.
  static const page = Duration(milliseconds: 380);

  /// A card being "dealt" onto the table (card details hero).
  static const deal = Duration(milliseconds: 650);

  /// Card viewer zoom-in.
  static const viewer = Duration(milliseconds: 360);

  /// Cold-launch Poké Ball intro (see `PokeBinderIntro`).
  static const intro = Duration(milliseconds: 2600);

  static const stagger = Duration(milliseconds: 45);

  static const maxStaggered = 8;

  static const smooth = Curves.easeOutCubic;
  static const bounce = Curves.easeOutBack;
  static const spring = Curves.elasticOut;

  /// Quick start, long soft landing — used for page and viewer motion.
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  static const curve = Curves.easeOut;

  static const pressedScale = 0.95;

  static Duration adapt(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
