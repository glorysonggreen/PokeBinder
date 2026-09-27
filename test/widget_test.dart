import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokebinder/main.dart';

void main() {
  testWidgets('Shows the login screen when signed out', (tester) async {
    // Supabase.initialize() (called from main(), not from this test) is
    // what main.dart's session check depends on, so this test only
    // exercises the widget tree, not the real backend. Once Supabase is
    // initialized in a test setUp with a test project, this can be
    // expanded to sign in and assert on the loaded collection instead.
    await tester.pumpWidget(const PokeBinderApp());
    expect(find.text('Log In'), findsWidgets);
  });
}