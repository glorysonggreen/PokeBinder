import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'theme/pokebinder_theme.dart';

void main() {
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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: PokeBinderColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PokeBinderColors.red,
          primary: PokeBinderColors.red,
        ),
      ),
      home: const AppShell(),
    );
  }
}
