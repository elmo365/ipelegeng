/// The single place the app's look is assembled.
///
/// Screens do not carry colours, radii or type of their own: they use plain
/// Material widgets and this file decides how those widgets look. A change to
/// the design lands here, once, and every screen follows.
///
/// The palette lives in [AppPalette] as a [ThemeExtension], reachable from any
/// widget as `context.palette`. Anything Material already themes — buttons,
/// inputs, chips, cards, the nav bar — is configured below so a screen never
/// has to.
///
/// See docs/design-system.md#components.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dimens.dart';
import 'motion.dart';
import 'tokens.dart';
import 'typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    palette: AppPalette.light,
    // The design's disabled label: oklch(0.65 0.012 250).
    disabledFg: Neutral.n300,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    palette: AppPalette.dark,
    // Re-toned to the same perceptual step, not re-hued.
    disabledFg: AppPalette.dark.textMuted,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
    required Color disabledFg,
  }) {
    final isLight = brightness == Brightness.light;
    final text = AppTypography.tinted(
      AppTypography.textTheme,
      palette.textPrimary,
    );

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isLight ? Brand.deep : Brand.sky,
      onPrimary: isLight ? Brand.white : Brand.navy,
      secondary: palette.accentText,
      onSecondary: isLight ? Brand.white : Brand.navy,
      error: Status.danger,
      onError: Brand.white,
      surface: palette.cardBg,
      onSurface: palette.textPrimary,
      surfaceContainerLowest: palette.screenBg,
      surfaceContainerLow: palette.screenBg2,
      surfaceContainer: palette.subtleBg,
      surfaceContainerHigh: palette.sectionAlt,
      surfaceContainerHighest: palette.stripe1,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.cardBorder,
      outlineVariant: palette.divider,
      // The brand blue is the action colour in both themes; the fill stays
      // constant so a primary button is recognisable across the swap.
      primaryContainer: Brand.deep,
      onPrimaryContainer: Brand.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.screenBg,
      canvasColor: palette.screenBg,
      dividerColor: palette.divider,
      textTheme: text,
      fontFamily: AppFonts.sans,
      extensions: [palette],

      // Push is the default because it is the only movement that deepens
      // history; lateral and replace are chosen explicitly at the route.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _PushTransitionBuilder(),
          TargetPlatform.iOS: _PushTransitionBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: palette.navBg,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),

      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: palette.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardAll,
          side: BorderSide(color: palette.cardBorder),
        ),
      ),

      // Primary action: brand fill, white label, radius 12, padding 14x24.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? palette.chipNeutralBg
                : Brand.deep,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? disabledFg : Brand.white,
          ),
          overlayColor: WidgetStatePropertyAll(
            Brand.white.withValues(alpha: 0.12),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          textStyle: const WidgetStatePropertyAll(AppTypography.buttonLabel),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Space.x6, vertical: 14),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, Touch.min)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.buttonAll),
          ),
          animationDuration: Motion.tap,
        ),
      ),

      // Secondary: surface fill, brand label, 1.5 px brand border.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? palette.chipNeutralBg
                : palette.cardBg,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? disabledFg
                : palette.accentText,
          ),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? BorderSide.none
                : BorderSide(color: palette.accentText, width: 1.5),
          ),
          textStyle: const WidgetStatePropertyAll(AppTypography.buttonLabel),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Space.x6, vertical: 12.5),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, Touch.min)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.buttonAll),
          ),
          animationDuration: Motion.tap,
        ),
      ),

      // Text action: no fill, no border, tight padding — but still 48 dp tall.
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? disabledFg
                : palette.accentText,
          ),
          textStyle: const WidgetStatePropertyAll(AppTypography.buttonLabel),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Space.x1, vertical: Space.x2),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, Touch.min)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.buttonAll),
          ),
          animationDuration: Motion.tap,
        ),
      ),

      // Input: 1.5 px border, brand on focus, radius 10, padding 12x14.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: Space.x3,
        ),
        border: OutlineInputBorder(
          borderRadius: Radii.inputAll,
          borderSide: BorderSide(color: palette.inputBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.inputAll,
          borderSide: BorderSide(color: palette.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.inputAll,
          borderSide: BorderSide(color: palette.accentText, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.inputAll,
          borderSide: const BorderSide(color: Status.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.inputAll,
          borderSide: const BorderSide(color: Status.danger, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: Radii.inputAll,
          borderSide: BorderSide(color: palette.divider, width: 1.5),
        ),
        // The field label sits above the input at 13/500. It does not float
        // into the border, which would hide it while the field is being typed
        // into — exactly when a requirement needs re-reading.
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: text.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: palette.textSecondary,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: palette.textFaint),
        helperStyle: text.bodySmall?.copyWith(
          fontSize: 12,
          color: palette.textMuted,
        ),
        errorStyle: text.bodySmall?.copyWith(
          fontSize: 12,
          color: palette.dangerText,
        ),
      ),

      // Chips are pills. The verified and neutral variants differ only by
      // colour, which the call site takes from the palette.
      chipTheme: ChipThemeData(
        backgroundColor: palette.chipNeutralBg,
        disabledColor: palette.chipNeutralBg,
        selectedColor: palette.selectedBg,
        labelStyle: AppTypography.chipLabel.copyWith(
          color: palette.chipNeutralText,
        ),
        secondaryLabelStyle: AppTypography.chipLabel.copyWith(
          color: palette.accentText,
        ),
        padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: 6),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: Radii.pillAll),
        showCheckmark: false,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.navBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.selectedBg,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: Radii.pillAll,
        ),
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppTypography.textTheme.labelLarge!.copyWith(
            color: s.contains(WidgetState.selected)
                ? palette.accentText
                : palette.navMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? palette.accentText
                : palette.navMuted,
          ),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.cardBg,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.cardBg,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheetTop),
        showDragHandle: true,
        dragHandleColor: palette.chipNeutralBg,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge?.copyWith(
          color: palette.textSecondary,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? Brand.navy : palette.cardBg,
        contentTextStyle: text.bodyLarge?.copyWith(
          color: isLight ? Brand.white : palette.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.buttonAll),
        elevation: 0,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: palette.textMuted,
        textColor: palette.textPrimary,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall?.copyWith(color: palette.textMuted),
        minVerticalPadding: Space.x3,
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
      ),

      // A progress indicator is allowed only where it is bounded. The design
      // has no shimmer and no spinning mark: nothing loops.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accentText,
        linearTrackColor: palette.chipNeutralBg,
        circularTrackColor: palette.chipNeutralBg,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Brand.white : palette.cardBg,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Brand.deep
              : palette.chipNeutralBg,
        ),
        trackOutlineColor: WidgetStatePropertyAll(palette.inputBorder),
      ),

      iconTheme: IconThemeData(color: palette.textSecondary, size: 24),
      primaryIconTheme: IconThemeData(color: palette.textPrimary, size: 24),
    );
  }
}

/// Wires [PageMotion.push] into Material's per-platform transition slot, so a
/// plain push already moves the way the design says a push moves.
class _PushTransitionBuilder extends PageTransitionsBuilder {
  const _PushTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => PageMotion.push(context, animation, secondaryAnimation, child);
}
