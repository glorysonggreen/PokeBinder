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
}

const double kPokemonCardAspectRatio = 5 / 7;
const String kPokemonCardBackAssetPath = '../assets/pokemon_card_back.jpg';
const double kPokemonCardWidthFraction = 0.72;
const double kPokemonCardMaxWidth = 300.0;
const double kPokemonCardImageWidthPx = 600;
const double kPokemonCardImageHeightPx = 825;
const double kPokemonCardImageAspectRatio = kPokemonCardImageWidthPx / kPokemonCardImageHeightPx;
const double kCardInteractionHeightBuffer = 1.25;
// Space reserved below each grid tile for the two-line name/set caption
// (a small gap plus the cardName and cardMeta text rows).
const double kCardCaptionHeight = 28.0;

class PokeBinderSpacing {
  PokeBinderSpacing._();

  static const sp1 = 4.0;
  static const sp2 = 8.0;
  static const sp3 = 12.0;
  static const sp4 = 16.0;
  static const sp5 = 20.0;
  static const sp6 = 24.0;
}

class PokeBinderText {
  PokeBinderText._();
  
  static TextStyle chakraPetch(TextStyle base) =>
      GoogleFonts.chakraPetch(textStyle: base);

  static final eyebrow = chakraPetch(const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.4,
    color: PokeBinderColors.redDeep,
  ));

  static final heading = chakraPetch(const TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.ink,
  ));

  static const subtitle = TextStyle(
    fontSize: 11.5,
    color: PokeBinderColors.inkSoft,
  );

  static const fieldLabel = TextStyle(
    fontSize: 11,
    color: PokeBinderColors.inkSoft,
  );

  static const fieldValue = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.ink,
  );

  static final statLabel = chakraPetch(const TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
    color: PokeBinderColors.inkSoft,
  ));

  static const statNumber = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.redDeep,
  );

  static final buttonLabel = chakraPetch(const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    color: PokeBinderColors.white,
  ));

  static final buttonGhostLabel = chakraPetch(const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    color: PokeBinderColors.redDeep,
  ));

  static final sectionLabel = chakraPetch(const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.7,
    color: PokeBinderColors.inkSoft,
  ));

  static final tabLabelInactive = chakraPetch(const TextStyle(
    fontSize: 11,
    color: PokeBinderColors.inkSoft,
  ));

  static final tabLabelActive = chakraPetch(const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.redDeep,
  ));

  static const listRowTitle = TextStyle(
    fontSize: 12,
    color: PokeBinderColors.ink,
  );

  static const listRowSubtitle = TextStyle(
    fontSize: 9.5,
    color: PokeBinderColors.inkSoft,
  );

  static final chipLabel = chakraPetch(const TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
    color: PokeBinderColors.inkSoft,
  ));

  static final chipLabelActive = chakraPetch(const TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
    color: PokeBinderColors.white,
  ));

  static final resultCount = chakraPetch(const TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.6,
    color: PokeBinderColors.inkSoft,
  ));

  static final cardName = chakraPetch(const TextStyle(
    fontSize: 8.5,
    fontWeight: FontWeight.bold,
    color: PokeBinderColors.inkSoft,
  ));

  static final cardMeta = chakraPetch(TextStyle(
    fontSize: 7.5,
    fontWeight: FontWeight.w500,
    color: PokeBinderColors.inkSoft.withValues(alpha: 0.75),
  ));

  static final backLink = chakraPetch(const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: PokeBinderColors.redDeep,
  ));
}