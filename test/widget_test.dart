import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokebinder/main.dart';
import 'package:pokebinder/models/binder_data.dart';

void main() {
  testWidgets('Binders screen shows the sample binders', (tester) async {
    await tester.pumpWidget(const PokeBinderApp());
    expect(find.text('COLLECTION'), findsOneWidget);
    for (final binder in BinderData.sampleBinders) {
      expect(find.text(binder.name), findsOneWidget);
    }
  });
}