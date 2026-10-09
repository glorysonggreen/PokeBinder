import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Maximum number of characters a person can type into each field.
///
/// Every text field in the app takes its limit from here, and the same numbers
/// are enforced by the database in the "Length limits" section at the end of
/// `supabase/schema.sql`, so a limit is still applied if someone skips the app
/// and talks to the API directly. If you change a number here, change it there
/// and in `docs/06-security-and-privacy.md`.
abstract final class FieldLimits {
  // Account
  static const int email = 254; // longest valid email address
  static const int password = 72; // Supabase Auth rejects anything longer
  static const int trainerName = 30;
  static const int bio = 160;

  // Binders and decks
  static const int binderName = 40;
  static const int binderCategory = 30;
  static const int deckName = 40;
  static const int description = 300; // binder and deck descriptions

  // Cards, wishlist and trade list
  static const int cardName = 80;
  static const int setName = 80;
  static const int cardNumber = 20;
  static const int notes = 500;
  static const int askingFor = 200;

  // Search boxes (the text is never stored)
  static const int search = 80;

  // Numbers typed into a text box, as a count of digits
  static const int quantityDigits = 4; // up to 9,999 copies
  static const int pageDigits = 3; // binder page numbers and starting pages
  static const int valueWholeDigits = 9; // pesos, plus up to 2 decimals
}

/// Hides Flutter's built-in "12/80" counter. Use it as `buildCounter` on
/// one-line fields where the limit is generous; long multi-line fields keep the
/// counter so people can see how much room is left.
Widget? hideCharacterCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) =>
    null;

/// Whole numbers only, at most [digits] long.
List<TextInputFormatter> digitsUpTo(int digits) => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(digits),
    ];

/// Peso amounts: up to [FieldLimits.valueWholeDigits] digits and, optionally,
/// a decimal point with at most two decimals. Anything else is ignored, so the
/// field keeps its previous text instead of clearing.
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
