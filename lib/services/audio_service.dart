import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Sfx {
  tap('tap', gain: 0.7, minGapMs: 35),
  addPress('add_press', minGapMs: 120),
  pageIn('page_in', gain: 0.8, minGapMs: 120),
  pageOut('page_out', gain: 0.8, minGapMs: 120),
  dialog('dialog', gain: 0.8, minGapMs: 120),
  cardSelect('card_select', gain: 0.8, minGapMs: 60),
  cardDeal('card_deal', minGapMs: 200),
  cardAdd('card_add', minGapMs: 250, long: true),
  cardMove('card_move', minGapMs: 120),
  cardZoom('card_zoom', minGapMs: 200),
  cardClose('card_close', minGapMs: 200),
  foil('foil', gain: 0.7, minGapMs: 700),
  rare('rare', minGapMs: 800, long: true),
  scan('scan', gain: 0.8, minGapMs: 900),
  scanFound('scan_found', minGapMs: 250),
  scanNone('scan_none', minGapMs: 250),
  success('success', minGapMs: 400, long: true),
  error('error', minGapMs: 350),
  remove('remove', minGapMs: 200),
  save('save', minGapMs: 250),
  toggleOn('toggle_on', minGapMs: 80),
  toggleOff('toggle_off', minGapMs: 80),
  star('star', minGapMs: 250),
  signOut('sign_out', minGapMs: 400),
  intro('intro', minGapMs: 1000, long: true);

  const Sfx(
    this.file, {
    this.gain = 1.0,
    this.minGapMs = 60,
    this.long = false,
  });

  final String file;
  final double gain;
  final int minGapMs;
  final bool long;

  String get asset => 'audio/sfx/$file.wav';
}

bool isChaseRarity(String rarity) => const {
      'Double Rare',
      'Illustration Rare',
      'Special Illustration Rare',
      'Hyper Rare',
    }.contains(rarity);

enum MusicTrack {
  none(null),
  title('audio/music/bgm_title.mp3'),
  main('audio/music/bgm_main.mp3');

  const MusicTrack(this.asset);
  final String? asset;
}

class PokeBinderAudio extends ChangeNotifier with WidgetsBindingObserver {
  PokeBinderAudio._();

  static final PokeBinderAudio instance = PokeBinderAudio._();

  static void play(Sfx sfx, {Duration delay = Duration.zero}) =>
      instance._play(sfx, delay);

  static void stop(Sfx sfx) => instance._stopSfx(sfx);

  static void music(MusicTrack track) => instance._setTrack(track);

  static const _kMusicEnabled = 'audio.musicEnabled';
  static const _kMusicVolume = 'audio.musicVolume';
  static const _kSfxEnabled = 'audio.sfxEnabled';
  static const _kSfxVolume = 'audio.sfxVolume';

  static const double _musicHeadroom = 0.6;

  static const int _shortPoolSize = 6;
  static const int _longPoolSize = 2;

  bool _ready = false;
  bool _appActive = true;

  bool _userGestured = false;

  bool _musicEnabled = true;
  double _musicVolume = 0.5;
  bool _sfxEnabled = true;
  double _sfxVolume = 0.8;

  SharedPreferences? _prefs;

  final List<AudioPlayer> _shortPool = [];
  final List<AudioPlayer> _longPool = [];
  int _nextShort = 0;
  int _nextLong = 0;
  final Map<Sfx, AudioPlayer> _active = {};
  final Map<Sfx, int> _lastPlayed = {};

  AudioPlayer? _musicPlayer;
  MusicTrack _wanted = MusicTrack.none;
  MusicTrack _loaded = MusicTrack.none;
  bool _musicPaused = false;
  double _musicLevel = 0;
  int _musicGen = 0;
  Timer? _fadeTimer;
  Future<void> _musicChain = Future<void>.value();

  bool get musicEnabled => _musicEnabled;
  double get musicVolume => _musicVolume;
  bool get sfxEnabled => _sfxEnabled;
  double get sfxVolume => _sfxVolume;

  bool get anySoundOn => _musicEnabled || _sfxEnabled;

  Future<void> init() async {
    if (_ready) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _musicEnabled = prefs.getBool(_kMusicEnabled) ?? _musicEnabled;
      _musicVolume = (prefs.getDouble(_kMusicVolume) ?? _musicVolume)
          .clamp(0.0, 1.0)
          .toDouble();
      _sfxEnabled = prefs.getBool(_kSfxEnabled) ?? _sfxEnabled;
      _sfxVolume = (prefs.getDouble(_kSfxVolume) ?? _sfxVolume)
          .clamp(0.0, 1.0)
          .toDouble();
    } catch (e) {
      debugPrint('Audio: could not read saved settings ($e)');
    }

    try {
      final dynamic global = AudioPlayer.global;
      await global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
    } catch (e) {
      debugPrint('Audio: could not set the mixing mode ($e)');
    }

    try {
      for (var i = 0; i < _shortPoolSize; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        _shortPool.add(player);
      }
      for (var i = 0; i < _longPoolSize; i++) {
        _longPool.add(AudioPlayer());
      }
      final music = AudioPlayer();
      await music.setReleaseMode(ReleaseMode.loop);
      _musicPlayer = music;

      _ready = true;
      WidgetsBinding.instance.addObserver(this);
      unawaited(_preload());
      if (_wanted != MusicTrack.none) _syncMusic();
    } catch (e) {
      debugPrint('Audio: disabled, could not start the audio engine ($e)');
    }
  }

  Future<void> _preload() async {
    try {
      await AudioCache.instance.loadAll([
        for (final sfx in Sfx.values) sfx.asset,
      ]);
    } catch (e) {
      debugPrint('Audio: preload skipped ($e)');
    }
  }

  void _play(Sfx sfx, Duration delay) {
    if (!_ready || !_sfxEnabled || _sfxVolume <= 0) return;

    if (delay > Duration.zero) {
      Timer(delay, () => _play(sfx, Duration.zero));
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayed[sfx];
    if (last != null && now - last < sfx.minGapMs) return;
    _lastPlayed[sfx] = now;

    final AudioPlayer player;
    if (sfx.long) {
      player = _longPool[_nextLong];
      _nextLong = (_nextLong + 1) % _longPool.length;
    } else {
      player = _shortPool[_nextShort];
      _nextShort = (_nextShort + 1) % _shortPool.length;
    }
    _active[sfx] = player;
    unawaited(_start(player, sfx));
  }

  Future<void> _start(AudioPlayer player, Sfx sfx) async {
    try {
      await player.play(
        AssetSource(sfx.asset),
        volume: (_sfxVolume * sfx.gain).clamp(0.0, 1.0).toDouble(),
      );
    } catch (e) {
      debugPrint('Audio: could not play ${sfx.file} ($e)');
    }
  }

  void _stopSfx(Sfx sfx) {
    final player = _active.remove(sfx);
    if (player == null) return;
    unawaited(player.stop().catchError((Object _) {}));
  }

  void _setTrack(MusicTrack track) {
    _wanted = track;
    _syncMusic();
  }

  void _syncMusic({int fadeMs = 450}) {
    final gen = ++_musicGen;
    _musicChain = _musicChain
        .then((_) => _doSyncMusic(gen, fadeMs))
        .catchError((Object e) {
      debugPrint('Audio: music error ($e)');
    });
  }

  bool get _shouldPlayMusic =>
      _ready &&
      _musicEnabled &&
      _musicVolume > 0 &&
      _appActive &&
      _wanted != MusicTrack.none &&
      (!kIsWeb || _userGestured);

  Future<void> _doSyncMusic(int gen, int fadeMs) async {
    final player = _musicPlayer;
    if (gen != _musicGen || player == null) return;

    if (!_shouldPlayMusic) {
      if (_loaded != MusicTrack.none && !_musicPaused) {
        await _fadeMusic(player, 0, 250, gen);
        if (gen != _musicGen) return;
        await player.pause();
        _musicPaused = true;
      }
      return;
    }

    final target = (_musicVolume * _musicHeadroom).clamp(0.0, 1.0).toDouble();

    if (_loaded == _wanted) {
      if (_musicPaused) {
        await player.setVolume(0);
        _musicLevel = 0;
        await player.resume();
        _musicPaused = false;
      }
      await _fadeMusic(player, target, fadeMs, gen);
      return;
    }

    if (_loaded != MusicTrack.none && !_musicPaused) {
      await _fadeMusic(player, 0, 300, gen);
      if (gen != _musicGen) return;
    }
    await player.stop();
    await player.setVolume(0);
    _musicLevel = 0;
    await player.play(AssetSource(_wanted.asset!));
    _loaded = _wanted;
    _musicPaused = false;
    await _fadeMusic(player, target, 900, gen);
  }

  Future<void> _fadeMusic(
    AudioPlayer player,
    double to,
    int ms,
    int gen,
  ) async {
    _fadeTimer?.cancel();
    final from = _musicLevel;
    if (ms <= 0 || (from - to).abs() < 0.005) {
      _musicLevel = to;
      await player.setVolume(to);
      return;
    }

    const stepMs = 40;
    final steps = ms ~/ stepMs < 1 ? 1 : ms ~/ stepMs;
    final done = Completer<void>();
    var i = 0;
    _fadeTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      if (gen != _musicGen) {
        timer.cancel();
        if (!done.isCompleted) done.complete();
        return;
      }
      i++;
      final level =
          (from + (to - from) * (i / steps)).clamp(0.0, 1.0).toDouble();
      _musicLevel = level;
      unawaited(player.setVolume(level).catchError((Object _) {}));
      if (i >= steps) {
        timer.cancel();
        if (!done.isCompleted) done.complete();
      }
    });
    await done.future;
  }

  void notifyUserGesture() {
    if (_userGestured) return;
    _userGestured = true;
    if (_ready && _wanted != MusicTrack.none) _syncMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state != AppLifecycleState.paused &&
        state != AppLifecycleState.hidden &&
        state != AppLifecycleState.detached;
    if (active == _appActive) return;
    _appActive = active;
    _syncMusic(fadeMs: active ? 600 : 150);
  }

  Future<void> setMusicEnabled(bool value) async {
    if (value == _musicEnabled) return;
    _musicEnabled = value;
    notifyListeners();
    _syncMusic();
    await _save();
  }

  Future<void> setMusicVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    if (clamped == _musicVolume) return;
    _musicVolume = clamped;
    notifyListeners();
    _syncMusic(fadeMs: 60);
    await _save();
  }

  Future<void> setSfxEnabled(bool value) async {
    if (value == _sfxEnabled) return;
    if (!value) play(Sfx.toggleOff);
    _sfxEnabled = value;
    notifyListeners();
    if (value) play(Sfx.toggleOn);
    await _save();
  }

  Future<void> setSfxVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    if (clamped == _sfxVolume) return;
    _sfxVolume = clamped;
    notifyListeners();
    await _save();
  }

  Future<void> toggleAll() async {
    final turnOn = !anySoundOn;
    if (!turnOn) play(Sfx.toggleOff);
    _musicEnabled = turnOn;
    _sfxEnabled = turnOn;
    notifyListeners();
    _syncMusic();
    if (turnOn) play(Sfx.toggleOn);
    await _save();
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setBool(_kMusicEnabled, _musicEnabled);
      await prefs.setDouble(_kMusicVolume, _musicVolume);
      await prefs.setBool(_kSfxEnabled, _sfxEnabled);
      await prefs.setDouble(_kSfxVolume, _sfxVolume);
    } catch (e) {
      debugPrint('Audio: could not save settings ($e)');
    }
  }
}
