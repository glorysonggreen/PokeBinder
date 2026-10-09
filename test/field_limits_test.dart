import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokebinder/config/field_limits.dart';
import 'package:pokebinder/theme/pokebinder_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

TextEditingValue _type(
  TextInputFormatter formatter,
  String before,
  String after,
) =>
    formatter.formatEditUpdate(
      TextEditingValue(
        text: before,
        selection: TextSelection.collapsed(offset: before.length),
      ),
      TextEditingValue(
        text: after,
        selection: TextSelection.collapsed(offset: after.length),
      ),
    );

void main() {
  group('placeholder contrast', () {
    test('hint text is at least 4.5:1 on the white input fill', () {
      expect(
        _contrast(PokeBinderColors.hint, PokeBinderColors.white),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('hint text is at least 4.5:1 on the cream page background', () {
      expect(
        _contrast(PokeBinderColors.hint, PokeBinderColors.cream),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('hint text stays visibly lighter than typed text', () {
      expect(
        _contrast(PokeBinderColors.hint, PokeBinderColors.white),
        lessThan(_contrast(PokeBinderColors.ink, PokeBinderColors.white)),
      );
    });
  });

  group('FieldLimits', () {
    test('password limit matches the Supabase Auth maximum', () {
      expect(FieldLimits.password, 72);
    });

    test('every limit is a positive number', () {
      for (final limit in [
        FieldLimits.email,
        FieldLimits.password,
        FieldLimits.trainerName,
        FieldLimits.bio,
        FieldLimits.binderName,
        FieldLimits.binderCategory,
        FieldLimits.deckName,
        FieldLimits.description,
        FieldLimits.cardName,
        FieldLimits.setName,
        FieldLimits.cardNumber,
        FieldLimits.notes,
        FieldLimits.askingFor,
        FieldLimits.search,
        FieldLimits.quantityDigits,
        FieldLimits.pageDigits,
        FieldLimits.valueWholeDigits,
      ]) {
        expect(limit, greaterThan(0));
      }
    });
  });

  group('digitsUpTo', () {
    TextEditingValue run(String text) {
      var value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      for (final formatter in digitsUpTo(3)) {
        value = formatter.formatEditUpdate(const TextEditingValue(), value);
      }
      return value;
    }

    test('removes anything that is not a digit', () {
      expect(run('1a2').text, '12');
    });

    test('cuts the number off at the limit', () {
      expect(run('12345').text, '123');
    });
  });

  group('PesoAmountFormatter', () {
    const formatter = PesoAmountFormatter();

    test('accepts whole pesos and up to two decimals', () {
      expect(_type(formatter, '', '28564').text, '28564');
      expect(_type(formatter, '12', '12.5').text, '12.5');
      expect(_type(formatter, '12.5', '12.50').text, '12.50');
    });

    test('rejects a third decimal and keeps the old text', () {
      expect(_type(formatter, '12.50', '12.501').text, '12.50');
    });

    test('rejects more than nine whole digits', () {
      expect(_type(formatter, '999999999', '9999999999').text, '999999999');
    });

    test('rejects letters, signs and a second decimal point', () {
      expect(_type(formatter, '1', '1a').text, '1');
      expect(_type(formatter, '1', '-1').text, '1');
      expect(_type(formatter, '1.5', '1.5.').text, '1.5');
    });
  });

  group('every TextField in lib/ has a limit', () {
    test('maxLength or inputFormatters is set before the decoration', () {
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      final offenders = <String>[];
      var found = 0;
      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        for (final match in RegExp(r'\bTextField\(').allMatches(source)) {
          found++;
          final end = source.indexOf('decoration:', match.end);
          final window = source.substring(
            match.end,
            end == -1 ? source.length : end,
          );
          if (!window.contains('maxLength:') &&
              !window.contains('inputFormatters:')) {
            final line = '\n'.allMatches(source.substring(0, match.start))
                    .length +
                1;
            offenders.add('${file.path}:$line');
          }
        }
      }
      expect(found, greaterThan(0), reason: 'No TextField widgets were found.');
      expect(offenders, isEmpty,
          reason: 'These TextFields have no length limit: $offenders');
    });
  });
}
