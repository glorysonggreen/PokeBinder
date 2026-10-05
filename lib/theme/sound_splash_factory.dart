import 'package:flutter/material.dart';

import '../services/audio_service.dart';

/// Wraps the theme's normal ink splash so that every Material tap target in
/// the app (buttons, list rows, chips, icon buttons, dialog actions...) plays
/// a small menu "tick" as it is pressed.
///
/// The splash itself is drawn exactly as before by the wrapped [inner]
/// factory; this only adds the sound. Disabled controls never create a splash,
/// so they stay silent.
class SoundSplashFactory extends InteractiveInkFeatureFactory {
  const SoundSplashFactory(this.inner);

  final InteractiveInkFeatureFactory inner;

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    PokeBinderAudio.play(Sfx.tap);
    return inner.create(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}
