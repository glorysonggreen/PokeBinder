// This is your app. It runs as it is: press run and you get the Card
// Details screen below.
//
// Everything in this file follows the same DevicePreview convention as the
// final-project-template it was built from.

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'screens/binders_screen.dart';
import 'theme/pokebinder_theme.dart';

void main() {
  runApp(
    // DevicePreview draws a phone frame around your app, so it is judged at
    // the size it was designed for instead of stretched across a laptop
    // window.
    //
    // It is left ON in the deployed build on purpose: your live link is
    // opened on a desktop browser, and a phone layout at full desktop width
    // looks broken when it is not framed. The toolbar also lets a visitor
    // switch device and orientation.
    //
    // Want the clean app with no frame instead? Add
    //   import 'package:flutter/foundation.dart' show kReleaseMode;
    // and set `enabled: !kReleaseMode`, which drops the frame in release
    // builds.
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
      home: const BindersScreen(),
    );
  }
}
