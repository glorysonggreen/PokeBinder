import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'theme/pokebinder_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const PokeBinderApp(),
    ),
  );
}

class PokeBinderApp extends StatelessWidget {
  const PokeBinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeBinder',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: PokeBinderTheme.light(),
      // Already signed in (e.g. app was killed and reopened) -> straight
      // to the collection instead of back through the login form.
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginScreen()
          : const AppShell(),
    );
  }
}