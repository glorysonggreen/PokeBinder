import 'package:flutter/widgets.dart';

import 'audio_service.dart';

class SilentPageRoute<T> extends PageRouteBuilder<T> {
  SilentPageRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, _, __) => builder(context),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}

class PokeBinderAudioObserver extends NavigatorObserver {
  static const String _cardViewerBarrierLabel = 'Close card';

  static bool _isCardViewer(Route<dynamic> route) =>
      route is PopupRoute && route.barrierLabel == _cardViewerBarrierLabel;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
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
