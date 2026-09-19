import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PokeBinderColors {
  PokeBinderColors._();

  static const red = Color(0xFFD6301B);
  static const redDeep = Color(0xFF98200E);
  static const redShadow = Color(0xFF6E1709);
  static const cream = Color(0xFFF5EFE1);
  static const cream2 = Color(0xFFEAE0C8);
  static const ink = Color(0xFF241F1C);
  static const inkSoft = Color(0xFF5A5148);
  static const gold = Color(0xFFE8AC3E);
  static const goldDeep = Color(0xFFC48A24);
  static const white = Color(0xFFFFFFFF);
  static const teal = Color(0xFF3E7C8C);
  static const danger = Color(0xFFB23A2C);
  static const slate = Color(0xFF5C6B73);
  static const hint = Color(0xFFA89C86);

  static const redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0402A), redDeep],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6D68B), goldDeep],
  );

  static const tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8FD0D8), teal],
  );

  static const slateGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE6E6E6), Color(0xFFBDBDBD)],
  );
}

const double kPokemonCardAspectRatio = 5 / 7;
const String kPokemonCardBackAssetPath = '../assets/pokemon_card_back.jpg';
const double kPokemonCardWidthFraction = 0.72;
const double kPokemonCardMaxWidth = 300.0;
const double kPokemonCardImageWidthPx = 600;
const double kPokemonCardImageHeightPx = 825;
const double kPokemonCardImageAspectRatio = kPokemonCardImageWidthPx / kPokemonCardImageHeightPx;
const double kCardInteractionHeightBuffer = 1.25;
const double kCardCaptionHeight = 36.0;
/// Height of the horizontally scrolling filter-chip rows. Matches
/// [kMinTapTarget] so the chips inside them can hit that target without
/// growing visually (see [MinTapTarget]).
const double kFilterChipRowHeight = 44.0;

/// Minimum width/height for anything tappable, per Apple's 44pt and
/// Material's 48dp guidance (44 is the stricter/shared floor). Small visual
/// controls (pills, icon buttons, text links) should keep their compact look
/// but sit inside a tap area of at least this size — see [MinTapTarget].
const double kMinTapTarget = 44.0;

/// The spacing scale. Every gap, padding and margin in the app should come
/// from here so the UI stays on one rhythm.
///
///   sp0  2   hairline gap (e.g. between a title and its subtitle)
///   sp1  4
///   sp2  8
///   sp3  12
///   sp4  16  standard page inset
///   sp5  20
///   sp6  24  bottom-of-page breathing room
class PokeBinderSpacing {
  PokeBinderSpacing._();

  static const sp0 = 2.0;
  static const sp1 = 4.0;
  static const sp2 = 8.0;
  static const sp3 = 12.0;
  static const sp4 = 16.0;
  static const sp5 = 20.0;
  static const sp6 = 24.0;

  /// Outer padding for every scrolling screen.
  static const page = EdgeInsets.fromLTRB(sp4, sp4, sp4, sp6);

  /// Padding inside small pills / tags / chips.
  static const chip = EdgeInsets.symmetric(horizontal: sp2, vertical: sp1);
}

final List<BoxShadow> kCardElevation = [
  BoxShadow(
    color: PokeBinderColors.ink.withValues(alpha: 0.06),
    blurRadius: 10,
    offset: const Offset(0, 3),
  ),
];

/// The type scale. Whole-pixel sizes only:
///
///   11 · 12 · 14 · 15 · 18 · 22
///
/// 11 is the floor (labels, chips, tags, card captions); 12 is for
/// secondary text; 14 is body / input / button size.
///
/// Chakra Petch is used for headings, labels, buttons and chips. Body copy
/// (the `const` styles below) has no family of its own and inherits
/// [PokeBinderTheme.bodyTextTheme], so it is the same font everywhere,
/// including dialogs, snackbars and text fields.
class PokeBinderText {
  PokeBinderText._();

  static TextStyle chakraPetch(TextStyle base) =>
      GoogleFonts.chakraPetch(textStyle: base);

  // ---- Headings & labels (Chakra Petch) ---------------------------------

  static final eyebrow = chakraPetch(const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.4,
    color: PokeBinderColors.redDeep,
  ));

  static final heading = chakraPetch(const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.ink,
  ));

  /// Secondary headings: dialog titles, deck / trainer names.
  static final headingSm = chakraPetch(const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.ink,
  ));

  /// Title of an item in a list row (card, binder, deck, wishlist entry...).
  static final rowTitle = chakraPetch(const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.ink,
  ));

  static final statLabel = chakraPetch(const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.7,
    color: PokeBinderColors.ink,
  ));

  static final sectionLabel = chakraPetch(const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.7,
    color: PokeBinderColors.inkSoft,
  ));

  static final formLabel = chakraPetch(const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.7,
    color: PokeBinderColors.inkSoft,
  ));

  static final resultCount = chakraPetch(const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.7,
    color: PokeBinderColors.inkSoft,
  ));

  static final backLink = chakraPetch(const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: PokeBinderColors.redDeep,
  ));

  // ---- Buttons ------------------------------------------------------------

  static final buttonLabel = chakraPetch(const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    color: PokeBinderColors.white,
  ));

  static final buttonGhostLabel = chakraPetch(const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    color: PokeBinderColors.redDeep,
  ));

  static final buttonDangerLabel = chakraPetch(const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    color: PokeBinderColors.danger,
  ));

  // ---- Tabs, pills, chips & tags -----------------------------------------

  static final tabLabelInactive = chakraPetch(const TextStyle(
    fontSize: 12,
    color: PokeBinderColors.inkSoft,
  ));

  static final tabLabelActive = chakraPetch(const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.redDeep,
  ));

  /// Label of a selectable filter / sort pill.
  static TextStyle pillLabel({required bool selected}) => chakraPetch(TextStyle(
        fontSize: 14,
        fontWeight: selected ? FontWeight.bold : FontWeight.w600,
        color: selected ? PokeBinderColors.redDeep : PokeBinderColors.ink,
      ));

  static final chipLabel = chakraPetch(const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    color: PokeBinderColors.inkSoft,
  ));

  static final chipLabelActive = chakraPetch(const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    color: PokeBinderColors.white,
  ));

  /// Small status tag (format, legality...). Pass the tag's foreground color.
  static TextStyle tagLabel(Color color) => chakraPetch(TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
        color: color,
      ));

  /// Quantity shown between the +/- buttons of a stepper.
  static TextStyle quantityLabel({required bool active}) =>
      chakraPetch(TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: active ? PokeBinderColors.redDeep : PokeBinderColors.inkSoft,
      ));

  // ---- Card captions -------------------------------------------------------

  static final cardName = chakraPetch(const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.inkSoft,
  ));

  static final cardMeta = chakraPetch(TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: PokeBinderColors.inkSoft.withValues(alpha: 0.9),
  ));

  // ---- Body copy (inherits the app body font) -----------------------------

  static const subtitle = TextStyle(
    fontSize: 14,
    color: PokeBinderColors.inkSoft,
  );

  static const fieldLabel = TextStyle(
    fontSize: 12,
    color: PokeBinderColors.inkSoft,
  );

  static const fieldValue = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.ink,
  );

  /// Current value shown in a dropdown-style selector.
  static const selectValue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: PokeBinderColors.ink,
  );

  /// Text typed into a text field.
  static const input = TextStyle(
    fontSize: 14,
    color: PokeBinderColors.ink,
  );

  /// Placeholder text inside a text field.
  static const hint = TextStyle(
    fontSize: 14,
    color: PokeBinderColors.hint,
  );

  static const statNumber = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.redDeep,
  );

  static const statNumberSm = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.redDeep,
  );

  static const listRowTitle = TextStyle(
    fontSize: 14,
    color: PokeBinderColors.ink,
  );

  static const listRowSubtitle = TextStyle(
    fontSize: 12,
    color: PokeBinderColors.inkSoft,
  );

  static const formError = TextStyle(
    fontSize: 12,
    color: PokeBinderColors.danger,
  );

  static const authLinkText = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: PokeBinderColors.inkSoft,
  );
}

/// The app-wide [ThemeData]. Dialogs, snackbars, buttons and text fields are
/// styled here so individual screens do not need to restyle them.
class PokeBinderTheme {
  PokeBinderTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PokeBinderColors.red,
      primary: PokeBinderColors.red,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: PokeBinderColors.cream,
    );

    return base.copyWith(
      textTheme: bodyTextTheme(base.textTheme),
      dialogTheme: DialogThemeData(
        backgroundColor: PokeBinderColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: PokeBinderText.headingSm,
        contentTextStyle: PokeBinderText.subtitle.copyWith(height: 1.4),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PokeBinderColors.redDeep,
          textStyle: PokeBinderText.buttonGhostLabel,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PokeBinderColors.ink,
        contentTextStyle: PokeBinderText.chakraPetch(const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: PokeBinderColors.white,
        )),
      ),
    );
  }

  /// One body font for the whole app (Inter), sized and colored to match the
  /// `const` body styles in [PokeBinderText]. Change the font here and every
  /// screen follows.
  static TextTheme bodyTextTheme(TextTheme base) {
    final inter = GoogleFonts.interTextTheme(base);
    return inter.copyWith(
      bodyLarge: inter.bodyLarge?.copyWith(
        fontSize: 14,
        color: PokeBinderColors.ink,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontSize: 14,
        color: PokeBinderColors.ink,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        fontSize: 12,
        color: PokeBinderColors.inkSoft,
      ),
    );
  }
}
