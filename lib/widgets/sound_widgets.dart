import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/pokebinder_theme.dart';

class AudioGestureUnlocker extends StatelessWidget {
  final Widget child;

  const AudioGestureUnlocker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => PokeBinderAudio.instance.notifyUserGesture(),
      child: child,
    );
  }
}

class SoundToggleButton extends StatelessWidget {
  const SoundToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = PokeBinderAudio.instance;

    return AnimatedBuilder(
      animation: audio,
      builder: (context, _) {
        final on = audio.anySoundOn;
        return Tooltip(
          message: on ? 'Mute sound' : 'Unmute sound',
          child: Material(
            color: PokeBinderColors.white,
            shape: CircleBorder(
              side: BorderSide(
                color: PokeBinderColors.ink.withValues(alpha: 0.09),
              ),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: audio.toggleAll,
              child: Padding(
                padding: const EdgeInsets.all(PokeBinderSpacing.sp2),
                child: Icon(
                  on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  size: 20,
                  color: on ? PokeBinderColors.redDeep : PokeBinderColors.inkSoft,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
