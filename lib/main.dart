import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'services/auth_service.dart';
import 'widgets/sound_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialization = Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  AuthService.watchForPasswordRecovery();
  await initialization;
  AuthService.watchForPasswordRecovery();

  runApp(
    DevicePreview(
      enabled: kIsWeb,
      builder: (context) => const PokeBinderApp(),
    ),
  );
  unawaited(PokeBinderAudio.instance.init());
}

class PokeBinderApp extends StatefulWidget {
  const PokeBinderApp({super.key});

  @override
  State<PokeBinderApp> createState() => _PokeBinderAppState();
}

class _PokeBinderAppState extends State<PokeBinderApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _audioObserver = PokeBinderAudioObserver();
  bool _resetScreenOpen = false;

  @override
  void initState() {
    super.initState();
    AuthService.recoveryRequested.addListener(_onRecoveryRequested);
    if (AuthService.recoveryRequested.value) _openResetPassword();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _navigatorKey.currentContext;
      if (context != null) PokeBinderBackground.precacheAll(context);
    });
  }

  @override
  void dispose() {
    AuthService.recoveryRequested.removeListener(_onRecoveryRequested);
    super.dispose();
  }

  void _onRecoveryRequested() {
    if (AuthService.recoveryRequested.value) _openResetPassword();
  }

  Future<void> _openResetPassword() async {
    if (_resetScreenOpen) return;
    _resetScreenOpen = true;
    try {
      for (var attempt = 0; attempt < 50; attempt++) {
        if (!mounted) return;
        final navigator = _navigatorKey.currentState;
        if (navigator != null) {
          await navigator.push(
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          );
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _resetScreenOpen = false;
      AuthService.recoveryRequested.value = false;
    }
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
