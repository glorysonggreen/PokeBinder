import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokebinder/services/audio_service.dart';

void main() {
  test('every sound effect and music track has its audio file', () {
    for (final sfx in Sfx.values) {
      expect(
        File('assets/${sfx.asset}').existsSync(),
        isTrue,
        reason: 'Missing assets/${sfx.asset}',
      );
    }
    for (final track in MusicTrack.values) {
      final asset = track.asset;
      if (asset == null) continue;
      expect(
        File('assets/$asset').existsSync(),
        isTrue,
        reason: 'Missing assets/$asset',
      );
    }
  });

  test('audio calls are harmless before the engine has started', () {
    // Widget tests never call PokeBinderAudio.init(), so none of these may
    // throw or touch a platform channel.
    PokeBinderAudio.play(Sfx.tap);
    PokeBinderAudio.play(Sfx.cardAdd, delay: const Duration(milliseconds: 10));
    PokeBinderAudio.stop(Sfx.intro);
    PokeBinderAudio.music(MusicTrack.main);
    PokeBinderAudio.music(MusicTrack.none);
  });

  test('only the high rarities earn the sparkle', () {
    expect(isChaseRarity('Hyper Rare'), isTrue);
    expect(isChaseRarity('Special Illustration Rare'), isTrue);
    expect(isChaseRarity('Common'), isFalse);
    expect(isChaseRarity(''), isFalse);
  });
}
