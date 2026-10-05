import 'package:flutter/material.dart';

class PokeBinderMotion {
  PokeBinderMotion._();

  static const press = Duration(milliseconds: 100);
  static const release = Duration(milliseconds: 320);
  static const fast = Duration(milliseconds: 150);
  static const enter = Duration(milliseconds: 380);
  static const pop = Duration(milliseconds: 420);
  static const count = Duration(milliseconds: 900);

  static const stagger = Duration(milliseconds: 45);

  static const maxStaggered = 8;

  static const smooth = Curves.easeOutCubic;
  static const bounce = Curves.easeOutBack;
  static const spring = Curves.elasticOut;

  static const curve = Curves.easeOut;

  static const pressedScale = 0.95;

  static Duration adapt(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
