import 'package:flutter/widgets.dart';

import 'audio_service.dart';

/// A full-screen route with no transition and no navigation sound.
///
/// Used as an invisible host when a screen needs to open a detail page on top
/// of the current screen (so Back returns there) but the detail page lives
/// inside another screen's state. The detail page's own route supplies the
/// visible transition and sound.
class SilentPageRoute<T> extends PageRouteBuilder<T> {
  SilentPageRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, _, __) => builder(context),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}

/// Plays a soft page-turn when a screen opens or closes, and a pop when a
/// dialog or sheet appears, so navigation always has a sound without every
/// screen having to ask for one.
///
/// Add it to `MaterialApp.navigatorObservers`.
class PokeBinderAudioObserver extends NavigatorObserver {
  /// The barrier label that `showCardViewer` uses. The zoomed-in card viewer
  /// is a dialog route, but it gets its own "lift the card" sound instead of
  /// the generic dialog pop.
  static const String _cardViewerBarrierLabel = 'Close card';

  static bool _isCardViewer(Route<dynamic> route) =>
      route is PopupRoute && route.barrierLabel == _cardViewerBarrierLabel;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // The very first route is the app launching, not the person navigating.
    if (previousRoute == null) return;
    if (route is SilentPageRoute) return;

    if (route is PageRoute) {
      PokeBinderAudio.play(Sfx.pageIn);
    } else if (_isCardViewer(route)) {
      PokeBinderAudio.play(Sfx.cardZoom);
    } else if (route is PopupRoute) {
      PokeBinderAudio.play(Sfx.dialog);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is SilentPageRoute) return;
    if (route is PageRoute) {
      PokeBinderAudio.play(Sfx.pageOut);
    } else if (_isCardViewer(route)) {
      PokeBinderAudio.play(Sfx.cardClose);
    }
  }
}
