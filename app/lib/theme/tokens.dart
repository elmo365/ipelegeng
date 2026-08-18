/// Colour tokens from the Ipelege design system.
///
/// The design authors colour in OKLCH, which Flutter cannot parse. These are
/// the converted sRGB values — do not hand-edit them. If a token changes in
/// the design, re-run the conversion rather than eyeballing a hex code.
///
/// See docs/design-system.md for the source values and what each token means.
library;

import 'package:flutter/material.dart';

/// Brand colours. Fixed across both themes.
abstract final class Brand {
  static const sky = Color(0xFF75BDEB);
  static const deep = Color(0xFF145A8D); // primary
  static const ink = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);
  static const navy = Color(0xFF061326); // header, balance card base
}

/// Status hues. Re-toned per theme via [AppPalette], never re-hued —
/// approved never stops being green.
abstract final class Status {
  static const success = Color(0xFF359658);
  static const warning = Color(0xFFD59800);
  static const danger = Color(0xFFD33A3C);
}

/// Cool, low-chroma neutral ramp, hue-matched to the brand blue.
abstract final class Neutral {
  static const n10 = Color(0xFFF8FAFD);
  static const n50 = Color(0xFFEFF2F6);
  static const n100 = Color(0xFFDDE2E6);
  static const n200 = Color(0xFFBFC5CA);
  static const n300 = Color(0xFF8A9096);
  static const n400 = Color(0xFF636A71);
  static const n500 = Color(0xFF42484F);
  static const n600 = Color(0xFF292E34);
  static const n700 = Color(0xFF13161A);
}

/// The semantic palette, as a [ThemeExtension] so widgets read tokens rather
/// than raw colours.
///
/// Usage: `context.palette.cardBorder`
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.screenBg,
    required this.screenBg2,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.inputBorder,
    required this.inputBg,
    required this.divider,
    required this.navBg,
    required this.navMuted,
    required this.stripe1,
    required this.stripe2,
    required this.chipNeutralBg,
    required this.chipNeutralText,
    required this.verifiedBg,
    required this.verifiedText,
    required this.pendingBg,
    required this.pendingText,
    required this.notUploadedBg,
    required this.notUploadedText,
    required this.selectedBg,
    required this.sectionAlt,
    required this.infoBg,
    required this.infoBorder,
    required this.infoTitle,
    required this.infoText,
    required this.accentText,
    required this.creditColor,
    required this.subtleBg,
    required this.dangerBg,
    required this.dangerText,
    required this.balanceCardGradient,
  });

  final Color screenBg;
  final Color screenBg2;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color inputBorder;
  final Color inputBg;
  final Color divider;
  final Color navBg;
  final Color navMuted;
  final Color stripe1;
  final Color stripe2;
  final Color chipNeutralBg;
  final Color chipNeutralText;
  final Color verifiedBg;
  final Color verifiedText;
  final Color pendingBg;
  final Color pendingText;
  final Color notUploadedBg;
  final Color notUploadedText;
  final Color selectedBg;
  final Color sectionAlt;
  final Color infoBg;
  final Color infoBorder;
  final Color infoTitle;
  final Color infoText;
  final Color accentText;

  /// Credit / positive money movement. Not the same as [Status.success].
  final Color creditColor;
  final Color subtleBg;
  final Color dangerBg;
  final Color dangerText;

  /// The balance card. Only lightens a step in dark mode so it stays the
  /// darkest surface on screen — one of the three things the design holds
  /// constant across themes.
  final Gradient balanceCardGradient;

  static const light = AppPalette(
    screenBg: Color(0xFFFFFFFF),
    screenBg2: Color(0xFFF8FAFD),
    cardBg: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFDDE2E6),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF2E3339),
    textMuted: Color(0xFF5D646B),
    textFaint: Color(0xFF6C727A),
    inputBorder: Color(0xFFBFC5CA),
    inputBg: Color(0xFFFFFFFF),
    divider: Color(0xFFDDE2E6),
    navBg: Color(0xFFFFFFFF),
    navMuted: Color(0xFFA8AFB5),
    stripe1: Color(0xFFE4E8ED),
    stripe2: Color(0xFFF3F5F8),
    chipNeutralBg: Color(0xFFDDE2E6),
    chipNeutralText: Color(0xFF42484F),
    verifiedBg: Color(0xFFE0F5E5),
    verifiedText: Color(0xFF00481E),
    pendingBg: Color(0xFFFFEFD1),
    pendingText: Color(0xFF7A4A00),
    notUploadedBg: Color(0xFFDDE2E6),
    notUploadedText: Color(0xFF5D646B),
    selectedBg: Color(0xFFE6F4FE),
    sectionAlt: Color(0xFFF3F5F8),
    infoBg: Color(0xFFE6F4FE),
    infoBorder: Color(0xFFC5DBE9),
    infoTitle: Color(0xFF061326),
    infoText: Color(0xFF145A8D),
    accentText: Color(0xFF145A8D),
    creditColor: Color(0xFF05773B),
    subtleBg: Color(0xFFF0F4F7),
    dangerBg: Color(0xFFFFE4DF),
    dangerText: Color(0xFF90101A),
    balanceCardGradient: RadialGradient(
      center: Alignment(0.7, -1.3),
      radius: 1.35,
      colors: [Color(0xFF16406B), Color(0xFF0A2242), Color(0xFF061326)],
      stops: [0.0, 0.45, 1.0],
    ),
  );

  static const dark = AppPalette(
    screenBg: Color(0xFF0B1015),
    screenBg2: Color(0xFF06090D),
    cardBg: Color(0xFF181E23),
    cardBorder: Color(0xFF30363C),
    textPrimary: Color(0xFFF0F2F4),
    textSecondary: Color(0xFFBFC5CA),
    textMuted: Color(0xFF9399A0),
    textFaint: Color(0xFF7B8187),
    inputBorder: Color(0xFF42484F),
    inputBg: Color(0xFF181E23),
    divider: Color(0xFF30363C),
    navBg: Color(0xFF11171C),
    navMuted: Color(0xFF5E646A),
    stripe1: Color(0xFF25292F),
    stripe2: Color(0xFF1C2024),
    chipNeutralBg: Color(0xFF292E35),
    chipNeutralText: Color(0xFFB9BEC4),
    verifiedBg: Color(0xFF12361E),
    verifiedText: Color(0xFFA1DFB1),
    pendingBg: Color(0xFF452E00),
    pendingText: Color(0xFFFAD18A),
    notUploadedBg: Color(0xFF292E35),
    notUploadedText: Color(0xFFA8AFB5),
    selectedBg: Color(0xFF0A2C3E),
    sectionAlt: Color(0xFF12171B),
    infoBg: Color(0xFF052739),
    infoBorder: Color(0xFF184258),
    infoTitle: Color(0xFFBCDCF5),
    infoText: Color(0xFF9DCDF0),
    accentText: Color(0xFF75BDEB),
    creditColor: Color(0xFF51AF6F),
    subtleBg: Color(0xFF14191E),
    dangerBg: Color(0xFF512320),
    dangerText: Color(0xFFFFBEB6),
    balanceCardGradient: RadialGradient(
      center: Alignment(0.7, -1.3),
      radius: 1.35,
      colors: [Color(0xFF1B4B7A), Color(0xFF0C2A4E), Color(0xFF08192E)],
      stops: [0.0, 0.45, 1.0],
    ),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    // Themes swap wholesale rather than interpolating; the design has no
    // cross-fade between light and dark.
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension PaletteAccess on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// One launch category: its tile hue, monogram and label.
///
/// Hues are `oklch(0.55 0.12 <hue>)` converted to sRGB. A few clip a channel
/// at the gamut edge — that is expected and matches what the design shows on
/// an sRGB screen. Monograms are placeholders until real iconography lands.
@immutable
class CategoryToken {
  const CategoryToken({
    required this.key,
    required this.monogram,
    required this.label,
    required this.hue,
  });

  final String key;
  final String monogram;
  final String label;
  final Color hue;
}

/// The nine launch categories, in the order the home grid lays them out.
///
/// Nine, not six: small trades are split because each carries different KYC
/// requirements and so cannot share one verification flow.
/// See docs/categories.md.
abstract final class Categories {
  static const rides = CategoryToken(
    key: 'rides',
    monogram: 'RI',
    label: 'Rides',
    hue: Color(0xFF007DAA),
  );
  static const movers = CategoryToken(
    key: 'movers',
    monogram: 'MV',
    label: 'Movers & hauling',
    hue: Color(0xFF008493),
  );
  static const rentals = CategoryToken(
    key: 'rentals',
    monogram: 'PR',
    label: 'Property rentals',
    hue: Color(0xFF3D73B6),
  );
  static const beauty = CategoryToken(
    key: 'beauty',
    monogram: 'HB',
    label: 'Hairdressing & beauty',
    hue: Color(0xFF00829D),
  );
  static const plumbing = CategoryToken(
    key: 'plumbing',
    monogram: 'PL',
    label: 'Plumbing',
    hue: Color(0xFF2677B2),
  );
  static const electrical = CategoryToken(
    key: 'electrical',
    monogram: 'EL',
    label: 'Electrical',
    hue: Color(0xFF4F6EB7),
  );
  static const tiling = CategoryToken(
    key: 'tiling',
    monogram: 'TL',
    label: 'Tiling',
    hue: Color(0xFF00877B),
  );
  static const catering = CategoryToken(
    key: 'catering',
    monogram: 'CA',
    label: 'Catering',
    hue: Color(0xFF008687),
  );
  static const hire = CategoryToken(
    key: 'hire',
    monogram: 'HR',
    label: 'Hire',
    hue: Color(0xFF258651),
  );

  static const all = <CategoryToken>[
    rides,
    movers,
    rentals,
    beauty,
    plumbing,
    electrical,
    tiling,
    catering,
    hire,
  ];

  static CategoryToken? byKey(String key) {
    for (final c in all) {
      if (c.key == key) return c;
    }
    return null;
  }
}
