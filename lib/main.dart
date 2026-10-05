import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart';
import 'theme/pokebinder_theme.dart';
import 'widgets/pokeball_intro.dart';
import 'widgets/pokebinder_background.dart';
import 'services/audio_navigator_observer.dart';
import 'services/audio_service.dart';
import 'widgets/sound_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  // Loads the saved sound settings and starts the audio engine. This never
  // throws: if audio can't start, the app simply runs silently.
  await PokeBinderAudio.instance.init();

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const PokeBinderApp(),
    ),
  );
}

class PokeBinderApp extends StatefulWidget {
  const PokeBinderApp({super.key});

  @override
  State<PokeBinderApp> createState() => _PokeBinderAppState();
}

class _PokeBinderAppState extends State<PokeBinderApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _audioObserver = PokeBinderAudioObserver();
  StreamSubscription<AuthState>? _authSubscription;
  bool _resetScreenOpen = false;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _openResetPassword();
      }
    });
    // Warm the image cache with the screen backgrounds once the first frame
    // is up, so no screen flashes plain cream while its background decodes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _navigatorKey.currentContext;
      if (context != null) PokeBinderBackground.precacheAll(context);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _openResetPassword() {
    if (_resetScreenOpen) return;
    _resetScreenOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        _resetScreenOpen = false;
        return;
      }
      await navigator.push(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
      _resetScreenOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      navigatorObservers: [_audioObserver],
      title: 'PokeBinder',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: (context, child) => AudioGestureUnlocker(
        child: DevicePreview.appBuilder(context, child),
      ),
      theme: PokeBinderTheme.light(),
      home: PokeBinderIntro(
        child: Supabase.instance.client.auth.currentSession == null
            ? const LoginScreen()
            : const AppShell(),
      ),
    );
  }
}
