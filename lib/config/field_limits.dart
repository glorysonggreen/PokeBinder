import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

abstract final class FieldLimits {
  static const int email = 254;
  static const int password = 72;
  static const int trainerName = 30;
  static const int bio = 160;
  static const int binderName = 40;
  static const int binderCategory = 30;
  static const int deckName = 40;
  static const int description = 300;
  static const int cardName = 80;
  static const int setName = 80;
  static const int cardNumber = 20;
  static const int notes = 500;
  static const int askingFor = 200;
  static const int search = 80;
  static const int quantityDigits = 4;
  static const int pageDigits = 3;
  static const int valueWholeDigits = 9;
}

Widget? hideCharacterCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) =>
    null;

List<TextInputFormatter> digitsUpTo(int digits) => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(digits),
    ];

class PesoAmountFormatter extends TextInputFormatter {
  const PesoAmountFormatter();

  static final RegExp _allowed =
      RegExp('^\\d{0,${FieldLimits.valueWholeDigits}}(\\.\\d{0,2})?\$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      _allowed.hasMatch(newValue.text) ? newValue : oldValue;
}
