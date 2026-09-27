import 'package:flutter/material.dart';

/// The animation "vocabulary" for PokeBinder.
///
/// Every animation in the app pulls its duration and curve from here, the
/// same way spacing comes from [PokeBinderSpacing]. Change a number here and
/// the whole app's motion changes with it.
///
/// The personality in one sentence: things *pop* into place with a tiny
/// overshoot (like a card being dealt), press down under your finger, and
/// spring back when you let go.
///
/// Durations
///   press    100ms  finger goes down on a tile or button
///   release  320ms  ...and the springy rebound when it lifts
///   fast     150ms  small state changes (chips, tab underline, labels)
///   enter    380ms  content arriving (cards dealt onto the page)
///   pop      420ms  icons / badges popping in with a bounce
///   count    900ms  numbers ticking up
///
/// Curves
///   smooth   gentle deceleration. Safe for anything, including sizes.
///   bounce   overshoots the target slightly, then settles.
///   spring   overshoots and wobbles like a spring.
///
/// IMPORTANT: only use [bounce] and [spring] on things that can safely go
/// past their end value, such as scale, rotation and offset. Never use them
/// on a width, height or opacity, because the overshoot can make those
/// negative or above 1, which Flutter treats as an error.
class PokeBinderMotion {
  PokeBinderMotion._();

  static const press = Duration(milliseconds: 100);
  static const release = Duration(milliseconds: 320);
  static const fast = Duration(milliseconds: 150);
  static const enter = Duration(milliseconds: 380);
  static const pop = Duration(milliseconds: 420);
  static const count = Duration(milliseconds: 900);

  /// Delay between one item and the next when a list is "dealt" in.
  static const stagger = Duration(milliseconds: 45);

  /// Items after this position all arrive together, so a long list never
  /// keeps the user waiting.
  static const maxStaggered = 8;

  static const smooth = Curves.easeOutCubic;
  static const bounce = Curves.easeOutBack;
  static const spring = Curves.elasticOut;

  /// Kept for the small state-change animations that already use it.
  static const curve = Curves.easeOut;

  /// How far a tile shrinks while it is pressed (1.0 = normal size).
  static const pressedScale = 0.95;

  /// Returns [Duration.zero] when the phone's "reduce motion" /
  /// "remove animations" accessibility setting is on, otherwise [duration].
  /// The reusable widgets in `motion_widgets.dart` call this for you.
  static Duration adapt(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
