/// Type tokens.
///
/// IBM Plex Sans mapped onto Material 3's five type roles, so the scale drops
/// into Flutter's [TextTheme] with nothing custom to maintain. IBM Plex Mono
/// is reserved for money, timestamps and OTP — tabular figures keep `P250.00`
/// and `P1 200.00` aligned in a list, and a monospace figure signals
/// "check this number".
///
/// Both faces are bundled in assets/fonts rather than fetched at runtime:
/// this app has to start on a bad connection.
///
/// Body text never drops below 13. See docs/design-system.md#type.
library;

import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const sans = 'IBMPlexSans';

  /// Money, balances, timestamps, OTP. Nothing else.
  static const mono = 'IBMPlexMono';
}

abstract final class AppTypography {
  /// The design's nine roles, mapped onto the M3 [TextTheme] slots that
  /// Material's own components already read.
  ///
  /// | Design role | Slot |
  /// |---|---|
  /// | Display     | `displaySmall`  |
  /// | Headline    | `headlineSmall` |
  /// | Title Large | `titleLarge`    |
  /// | Title Medium| `titleMedium`   |
  /// | Body Large  | `bodyLarge`     |
  /// | Body Small  | `bodySmall`     |
  /// | Label       | `labelLarge`    |
  /// | Caption     | `labelSmall`    |
  static const textTheme = TextTheme(
    // Display — hero numbers, empty states.
    displaySmall: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 40 / 32,
    ),
    // Headline — screen titles.
    headlineSmall: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 30 / 24,
    ),
    // Title Large — section and listing names.
    titleLarge: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 19,
      fontWeight: FontWeight.w600,
      height: 26 / 19,
    ),
    // Title Medium — card titles, list headlines.
    titleMedium: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 22 / 16,
    ),
    // Body Large — descriptions, requirements.
    bodyLarge: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 22 / 15,
    ),
    // Body Medium is Flutter's default for bare Text. Held at Body Large's
    // weight one step down in size so unstyled text still lands in the scale.
    bodyMedium: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 22 / 15,
    ),
    // Body Small — helper and secondary text. The floor: never below 13.
    bodySmall: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 18 / 13,
    ),
    // Label — buttons, tabs, badges.
    labelLarge: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 16 / 13,
    ),
    labelMedium: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      height: 16 / 12.5,
    ),
    // Caption — timestamps, metadata.
    labelSmall: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 14 / 11,
    ),
  );

  /// Money, at the size of the text around it. Tabular by construction —
  /// IBM Plex Mono has no proportional figures to fall back to.
  static const figure = TextStyle(
    fontFamily: AppFonts.mono,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// A balance or hero amount.
  static const figureLarge = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// An amount inside a row or card.
  static const figureBody = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 22 / 15,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Timestamps and OTP digits.
  static const figureSmall = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 18 / 13,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// The button label from the component table: 15 / 600, one step above the
  /// [TextTheme] label role because a button is not a badge.
  static const buttonLabel = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
  );

  /// Chips and badges: 12.5 / 600.
  static const chipLabel = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 16 / 12.5,
  );

  /// Applies [color] across a whole [TextTheme]. The palette supplies the
  /// colour; the scale never carries one of its own.
  static TextTheme tinted(TextTheme base, Color color) =>
      base.apply(bodyColor: color, displayColor: color);
}
