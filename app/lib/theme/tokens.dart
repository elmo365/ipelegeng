/// Colour tokens from the Ipelege design system.
///
/// The design authors colour in OKLCH, which Flutter cannot parse. These are
/// the converted sRGB values — do not hand-edit them. If a token changes in
/// the design, re-run the conversion rather than eyeballing a hex code.
///
/// Re-pulled 2026-08-20 from the design project, after the canvas was split
/// into four files so the whole of it could be read. **Every colour below is
/// read from the design's own `PAL` object** — both modes — rather than
/// inferred from the mockups. See docs/design-system.md for the source values
/// and what each token means, and docs/design-deltas.md for what moved.
library;

import 'package:flutter/material.dart';

/// Brand colours. Fixed across both themes.
abstract final class Brand {
  static const sky = Color(0xFF75BDEB);
  static const deep = Color(0xFF145A8D); // primary
  static const ink = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);
  static const navy = Color(0xFF061326); // header, balance card base

  /// The hero gradient's light and dark stops. The provider dashboard header
  /// and the balance card are the same object at two sizes.
  static const heroLight = Color(0xFF1E7BB5);
  static const heroMid = Color(0xFF145A8D);
  static const heroDeep = Color(0xFF0D3D62);
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
/// Usage: `context.palette.shadowCard`
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
    required this.navPillBg,
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
    required this.heroGradient,
    required this.entryGradient,
    required this.splashGradient,
    required this.shadowRow,
    required this.shadowCard,
    required this.shadowHero,
    required this.shadowNav,
    required this.shadowPrimaryButton,
    required this.shadowSuccessButton,
  });

  /// The page. Tinted, not white — this is the single change the design says
  /// "does most of the work", because white cards need something to float on.
  final Color screenBg;
  final Color screenBg2;
  final Color cardBg;

  /// Kept for inputs, dividers and the admin surface. Cards no longer use it:
  /// the design removed grey borders in favour of tinted shadow.
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

  /// The tinted pill behind the active nav icon. 42 x 30 at [Radii.navPill].
  final Color navPillBg;
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

  /// The provider dashboard hero. "Blue as a field, not as trim" — a real
  /// gradient carrying its own actions, rather than a link colour.
  final Gradient heroGradient;

  /// The header band on register, sign in and OTP: the same three hero stops
  /// as [heroGradient], but radial from the top right, and squared off at the
  /// top so it reads as the top of the page rather than as a floating card.
  ///
  /// An inline literal in the canvas rather than a `PAL` token, like
  /// [navPillBg] — recorded here as the literal it is. The dark form takes the
  /// dark hero's stops, so the two stay in step.
  final Gradient entryGradient;

  /// First open. Darker than [entryGradient] and it lands on navy rather than
  /// on the hero's deep blue, because the splash is the one screen with no
  /// surface on it at all.
  ///
  /// Identical in both themes on purpose. Like the balance card, it is already
  /// dark in light mode, and re-darkening it in dark mode would only cost
  /// contrast against the white lockup it carries.
  final Gradient splashGradient;

  /// The three surface depths, blue-tinted. These replace borders; a card
  /// gets a shadow or a border, never both.
  final List<BoxShadow> shadowRow;
  final List<BoxShadow> shadowCard;
  final List<BoxShadow> shadowHero;

  /// The nav sheet casts upward.
  final List<BoxShadow> shadowNav;

  /// A filled action carries a shadow in its own hue, at a far higher alpha
  /// than any surface.
  final List<BoxShadow> shadowPrimaryButton;
  final List<BoxShadow> shadowSuccessButton;

  static const light = AppPalette(
    // #EDF3F8 — the tinted page. Named in the design's "what changed" list.
    screenBg: Color(0xFFFFFFFF),
    screenBg2: Color(0xFFEDF3F8),
    cardBg: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFDDE2E6),
    // Deep navy ink, not pure black — it sits on a tinted page now.
    textPrimary: Color(0xFF0D2436),
    textSecondary: Color(0xFF2E3339),
    textMuted: Color(0xFF5F7387),
    textFaint: Color(0xFF9CAFBF),
    inputBorder: Color(0xFFDCE7EF),
    inputBg: Color(0xFFFFFFFF),
    divider: Color(0xFFE9F0F5),
    navBg: Color(0xFFFFFFFF),
    navMuted: Color(0xFF9CAFBF),
    navPillBg: Color(0xFFE1EDF5),
    stripe1: Color(0xFFE4E8ED),
    stripe2: Color(0xFFF3F5F8),
    chipNeutralBg: Color(0xFFE1EDF5),
    chipNeutralText: Color(0xFF5F7387),
    verifiedBg: Color(0xFFE0F5E5),
    verifiedText: Color(0xFF005222),
    pendingBg: Color(0xFFFFEFD1),
    pendingText: Color(0xFF7A4A00),
    notUploadedBg: Color(0xFFE1EDF5),
    notUploadedText: Color(0xFF5F7387),
    selectedBg: Color(0xFFE6F4FE),
    sectionAlt: Color(0xFFF3F5F8),
    infoBg: Color(0xFFE6F4FE),
    infoBorder: Color(0xFFC5DBE9),
    infoTitle: Color(0xFF061326),
    infoText: Color(0xFF145A8D),
    accentText: Color(0xFF145A8D),
    creditColor: Color(0xFF05773B),
    subtleBg: Color(0xFFF0F4F7),
    dangerBg: Color(0xFFFFE8E4),
    dangerText: Color(0xFFA92227),
    balanceCardGradient: RadialGradient(
      center: Alignment(0.7, -1.3),
      radius: 1.35,
      colors: [Color(0xFF16406B), Color(0xFF0A2242), Color(0xFF061326)],
      stops: [0.0, 0.45, 1.0],
    ),
    heroGradient: LinearGradient(
      // 145deg in CSS, measured from the top; Flutter measures from the left.
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Brand.heroLight, Brand.heroMid, Brand.heroDeep],
      stops: [0.0, 0.52, 1.0],
    ),
    // `radial-gradient(130% 110% at 80% -10%, …)`. CSS measures the centre
    // from the top left as a percentage; Flutter measures it from the middle
    // in half-widths, so 80%/-10% becomes (0.6, -1.2).
    entryGradient: RadialGradient(
      center: Alignment(0.6, -1.2),
      radius: 1.3,
      colors: [Brand.heroLight, Brand.heroMid, Brand.heroDeep],
      stops: [0.0, 0.45, 1.0],
    ),
    // `radial-gradient(130% 100% at 78% -8%, #1E7BB5, #0F4874 42%, #061326)`.
    splashGradient: RadialGradient(
      center: Alignment(0.56, -1.16),
      radius: 1.3,
      colors: [Brand.heroLight, Color(0xFF0F4874), Brand.navy],
      stops: [0.0, 0.42, 1.0],
    ),
    shadowRow: _shRowLight,
    shadowCard: _shCardLight,
    shadowHero: _shHeroLight,
    shadowNav: _shNavLight,
    shadowPrimaryButton: _shPrimaryLight,
    shadowSuccessButton: _shSuccessLight,
  );

  /// Dark mode, **read from the design's `PAL` object**, not derived.
  ///
  /// Recovered 2026-08-20 when the canvas was split into four files, each
  /// under the read cap. Two things it corrected: the dark surfaces sit on
  /// hue **235**, not 250 — they are a shade cooler and bluer than the values
  /// carried over from the pre-restyle import — and the dark shadows drop the
  /// blue tint entirely and raise their alpha, because a tinted shadow on a
  /// near-black ground reads as a colour cast rather than as depth.
  ///
  /// `navPillBg` remains the one derived value here: it is an inline literal
  /// in the canvas rather than a token, so it has no published dark form.
  static const dark = AppPalette(
    screenBg: Color(0xFF0B1317),
    screenBg2: Color(0xFF050B0F),
    cardBg: Color(0xFF171F25),
    cardBorder: Color(0xFF2E373D),
    textPrimary: Color(0xFFF0F2F4),
    textSecondary: Color(0xFFBFC5CA),
    textMuted: Color(0xFF9399A0),
    textFaint: Color(0xFF7B8187),
    inputBorder: Color(0xFF42484F),
    inputBg: Color(0xFF181E23),
    divider: Color(0xFF30363C),
    navBg: Color(0xFF11171C),
    navMuted: Color(0xFF6C7278),
    navPillBg: Color(0xFF0A2C3E),
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
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B4B7A), Color(0xFF123A5C), Color(0xFF0A2B45)],
      stops: [0.0, 0.52, 1.0],
    ),
    entryGradient: RadialGradient(
      center: Alignment(0.6, -1.2),
      radius: 1.3,
      colors: [Color(0xFF1B4B7A), Color(0xFF123A5C), Color(0xFF0A2B45)],
      stops: [0.0, 0.45, 1.0],
    ),
    // Deliberately the same as light — see the field's doc comment.
    splashGradient: RadialGradient(
      center: Alignment(0.56, -1.16),
      radius: 1.3,
      colors: [Brand.heroLight, Color(0xFF0F4874), Brand.navy],
      stops: [0.0, 0.42, 1.0],
    ),
    shadowRow: _shRowDark,
    shadowCard: _shCardDark,
    shadowHero: _shHeroDark,
    shadowNav: _shNavDark,
    shadowPrimaryButton: _shPrimaryDark,
    shadowSuccessButton: _shSuccessDark,
  );

  // Shadows, read from the design's own PAL object (part 4 of the split
  // canvas) rather than inferred. Its names map onto ours:
  //
  //   pal.shCard  -> shadowRow   0 4px 14px  — the common surface
  //   pal.shRaise -> shadowCard  0 6px 20px  — a card that groups rows
  //   pal.shNav   -> shadowNav   0 -6px 24px — casts upward
  //
  // The hero's 28 px shadow and the coloured button shadows are inline
  // literals in the canvas, not tokens, so they are recorded here as the
  // literals they are.
  static const _shRowLight = [
    BoxShadow(color: Color(0x0F145A8D), offset: Offset(0, 4), blurRadius: 14),
  ];
  static const _shCardLight = [
    BoxShadow(color: Color(0x12145A8D), offset: Offset(0, 6), blurRadius: 20),
  ];
  static const _shHeroLight = [
    BoxShadow(color: Color(0x4D0D3D62), offset: Offset(0, 12), blurRadius: 28),
  ];
  static const _shNavLight = [
    BoxShadow(color: Color(0x14145A8D), offset: Offset(0, -6), blurRadius: 24),
  ];
  static const _shPrimaryLight = [
    BoxShadow(color: Color(0x4D145A8D), offset: Offset(0, 8), blurRadius: 20),
  ];
  static const _shSuccessLight = [
    BoxShadow(color: Color(0x4D05773B), offset: Offset(0, 8), blurRadius: 20),
  ];

  // Dark: also read, not derived. The design drops the blue tint entirely on
  // a dark ground and raises the alpha — a tinted shadow on near-black reads
  // as a colour cast rather than as depth.
  static const _shRowDark = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 4), blurRadius: 14),
  ];
  static const _shCardDark = [
    BoxShadow(color: Color(0x57000000), offset: Offset(0, 6), blurRadius: 20),
  ];
  static const _shHeroDark = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 12), blurRadius: 28),
  ];
  static const _shNavDark = [
    BoxShadow(color: Color(0x5C000000), offset: Offset(0, -6), blurRadius: 24),
  ];
  static const _shPrimaryDark = [
    BoxShadow(color: Color(0x59062A45), offset: Offset(0, 8), blurRadius: 20),
  ];
  static const _shSuccessDark = [
    BoxShadow(color: Color(0x4D06381D), offset: Offset(0, 8), blurRadius: 20),
  ];

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

/// The three journey shapes.
///
/// The launch categories do not share a flow — two of them skip whole stages,
/// and a single linear journey would have been wrong. This is not cosmetic:
/// it decides whether a category has a booking at all, and therefore whether
/// it ever produces commission.
///
/// See docs/design-deltas.md#6-the-journey-has-three-shapes-not-one.
enum JourneyShape {
  /// Stages 0–3 customer side, 4–5 provider side. Commission posts on
  /// completion; the service itself is paid outside the app.
  browseAndBook,

  /// Rides. **Skips browse and listing detail entirely** — the request goes
  /// to nearby drivers holding sufficient credit (FR-3.10), and live tracking
  /// is a launch requirement rather than an addition.
  dispatch,

  /// Property rentals. **No booking, no commission, no completion.** The
  /// tenant enquires and leaves the app; the landlord pays per room, per
  /// vacancy. Verification is the only reason to pay rather than post free to
  /// a Facebook group.
  payPerListing;

  /// Whether this shape ends in a booking the platform takes commission on.
  bool get books => this == JourneyShape.browseAndBook;
}

/// One launch category: its icon, its hue, the tinted plate the icon sits on,
/// and the journey shape it follows.
///
/// The design replaced the grey monogram with a Material Symbol on a tinted
/// plate of the category hue — reason 5 of the five it gave for why the
/// screens read flat: "Category identity sits in a 3px bar and a grey
/// monogram. Tinted icon tiles per category ... give every row a reason to be
/// looked at."
///
/// Each category owns a hue **angle**, and both colours are constructed from
/// it: the plate is `oklch(0.95 0.035 h)` and the ink is `oklch(0.5 0.13 h)`.
/// Storing the angle is what keeps the nine consistent — a new category picks
/// an angle, not two hex codes.
@immutable
class CategoryToken {
  const CategoryToken({
    required this.key,
    required this.icon,
    required this.label,
    required this.hueAngle,
    required this.plate,
    required this.ink,
    required this.plateDark,
    required this.inkDark,
    required this.shape,
  });

  final String key;

  /// The Material Symbol the design names for this category.
  final IconData icon;
  final String label;

  /// The OKLCH hue angle both colours are built from. Kept so the conversion
  /// is reproducible rather than a table of magic hex values.
  final double hueAngle;

  /// `oklch(0.95 0.035 hueAngle)` — the 36 dp plate behind the icon.
  final Color plate;

  /// `oklch(0.5 0.13 hueAngle)` — the icon itself.
  final Color ink;

  /// Dark-mode pair. Derived, like the rest of the dark surface — see
  /// [AppPalette.dark].
  final Color plateDark;
  final Color inkDark;

  /// Which of the three journeys this category follows. Decides whether it
  /// appears in browse at all, and whether its listing ends in a booking.
  final JourneyShape shape;

  Color plateOf(Brightness b) => b == Brightness.dark ? plateDark : plate;
  Color inkOf(Brightness b) => b == Brightness.dark ? inkDark : ink;
}

/// The nine launch categories, in the order the home grid lays them out.
///
/// Nine, not six: small trades are split because each carries different KYC
/// requirements and so cannot share one verification flow.
/// See docs/categories.md.
abstract final class Categories {
  static const rides = CategoryToken(
    key: 'rides',
    icon: Icons.directions_car,
    label: 'Rides',
    hueAngle: 230,
    plate: Color(0xFFD8F4FF),
    ink: Color(0xFF006E9E),
    plateDark: Color(0xFF012D3F),
    inkDark: Color(0xFF43B2E1),
    shape: JourneyShape.dispatch,
  );
  static const movers = CategoryToken(
    key: 'movers',
    icon: Icons.local_shipping,
    label: 'Movers & hauling',
    hueAngle: 205,
    plate: Color(0xFFD4F6FA),
    ink: Color(0xFF007686),
    plateDark: Color(0xFF003036),
    inkDark: Color(0xFF17BAC8),
    shape: JourneyShape.browseAndBook,
  );
  static const rentals = CategoryToken(
    key: 'rentals',
    icon: Icons.meeting_room,
    label: 'Property rentals',
    hueAngle: 255,
    plate: Color(0xFFDFF0FF),
    ink: Color(0xFF2863AB),
    plateDark: Color(0xFF152A43),
    inkDark: Color(0xFF6FA7EE),
    shape: JourneyShape.payPerListing,
  );
  static const beauty = CategoryToken(
    key: 'beauty',
    icon: Icons.content_cut,
    label: 'Hairdressing & beauty',
    hueAngle: 330,
    plate: Color(0xFFFDE7FA),
    ink: Color(0xFF8B4486),
    plateDark: Color(0xFF381E36),
    inkDark: Color(0xFFCF88C8),
    shape: JourneyShape.browseAndBook,
  );
  static const plumbing = CategoryToken(
    key: 'plumbing',
    icon: Icons.plumbing,
    label: 'Plumbing',
    hueAngle: 180,
    plate: Color(0xFFD6F7EF),
    ink: Color(0xFF007A66),
    plateDark: Color(0xFF00312A),
    inkDark: Color(0xFF2FBDA7),
    shape: JourneyShape.browseAndBook,
  );
  static const electrical = CategoryToken(
    key: 'electrical',
    icon: Icons.electrical_services,
    label: 'Electrical',
    hueAngle: 85,
    plate: Color(0xFFF9EDD5),
    ink: Color(0xFF855B00),
    plateDark: Color(0xFF352602),
    inkDark: Color(0xFFC79E41),
    shape: JourneyShape.browseAndBook,
  );
  static const tiling = CategoryToken(
    key: 'tiling',
    icon: Icons.grid_view,
    label: 'Tiling',
    hueAngle: 40,
    plate: Color(0xFFFFE7DD),
    ink: Color(0xFF9E4421),
    plateDark: Color(0xFF3F1E13),
    inkDark: Color(0xFFE4896A),
    shape: JourneyShape.browseAndBook,
  );
  static const catering = CategoryToken(
    key: 'catering',
    icon: Icons.restaurant,
    label: 'Catering',
    hueAngle: 25,
    plate: Color(0xFFFFE6E3),
    ink: Color(0xFFA03F3C),
    plateDark: Color(0xFF401D1B),
    inkDark: Color(0xFFE6857E),
    shape: JourneyShape.browseAndBook,
  );
  static const hire = CategoryToken(
    key: 'hire',
    icon: Icons.chair,
    label: 'Hire',
    hueAngle: 300,
    plate: Color(0xFFF2EAFF),
    ink: Color(0xFF6F4FA1),
    plateDark: Color(0xFF2D2240),
    inkDark: Color(0xFFB093E5),
    shape: JourneyShape.browseAndBook,
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
