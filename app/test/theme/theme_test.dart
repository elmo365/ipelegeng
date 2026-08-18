import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/theme/app_theme.dart';
import 'package:ipelege/theme/dimens.dart';
import 'package:ipelege/theme/tokens.dart';
import 'package:ipelege/theme/typography.dart';

/// The theme is the app's only source of look. These tests guard the rules a
/// later change is most likely to break silently: both themes carry a palette,
/// the type floor holds, buttons meet the touch minimum, and status hues are
/// re-toned across themes rather than re-hued.
void main() {
  final themes = {'light': AppTheme.light, 'dark': AppTheme.dark};

  group('every theme', () {
    themes.forEach((name, theme) {
      test('$name carries the palette extension', () {
        expect(theme.extension<AppPalette>(), isNotNull);
      });

      test('$name uses the bundled face, not the platform default', () {
        expect(theme.textTheme.bodyLarge?.fontFamily, AppFonts.sans);
        expect(theme.textTheme.headlineSmall?.fontFamily, AppFonts.sans);
      });

      test('$name keeps body text at or above 13', () {
        final sizes = [
          theme.textTheme.bodyLarge?.fontSize,
          theme.textTheme.bodyMedium?.fontSize,
          theme.textTheme.bodySmall?.fontSize,
        ];
        for (final size in sizes) {
          expect(size, isNotNull);
          expect(size, greaterThanOrEqualTo(13));
        }
      });

      test('$name gives buttons the 48 dp touch floor', () {
        final style = theme.elevatedButtonTheme.style!;
        final size = style.minimumSize?.resolve({});
        expect(size?.height, Touch.min);
      });

      test('$name flattens Material elevation — the design has no shadows', () {
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.cardTheme.elevation, 0);
        expect(theme.navigationBarTheme.elevation, 0);
      });
    });
  });

  group('across themes', () {
    final light = AppPalette.light;
    final dark = AppPalette.dark;

    test('surfaces are re-toned, not shared', () {
      expect(light.screenBg, isNot(dark.screenBg));
      expect(light.cardBg, isNot(dark.cardBg));
      expect(light.verifiedBg, isNot(dark.verifiedBg));
    });

    test('status hues are never re-hued', () {
      // The tokens themselves are fixed; only the background and text tones
      // around them move. Approved never stops being green.
      expect(Status.success, const Color(0xFF359658));
      expect(Status.warning, const Color(0xFFD59800));
      expect(Status.danger, const Color(0xFFD33A3C));
    });

    test('the balance card stays the darkest surface in both themes', () {
      // Its gradient only lightens a step in dark mode — it never inverts.
      final lightStops = (light.balanceCardGradient as RadialGradient).colors;
      final darkStops = (dark.balanceCardGradient as RadialGradient).colors;
      for (var i = 0; i < lightStops.length; i++) {
        expect(darkStops[i].computeLuminance(), lessThan(0.1));
        expect(lightStops[i].computeLuminance(), lessThan(0.1));
      }
    });

    test('the action colour is legible on its fill in both themes', () {
      for (final theme in themes.values) {
        final scheme = theme.colorScheme;
        final ratio = _contrast(scheme.onPrimary, scheme.primary);
        expect(ratio, greaterThan(3.0));
      }
    });
  });

  group('categories', () {
    test('all nine are present and uniquely keyed', () {
      expect(Categories.all, hasLength(9));
      expect(Categories.all.map((c) => c.key).toSet(), hasLength(9));
    });

    test('lookup by key round-trips', () {
      for (final category in Categories.all) {
        expect(Categories.byKey(category.key), same(category));
      }
      expect(Categories.byKey('nope'), isNull);
    });
  });
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance() + 0.05;
  final lb = b.computeLuminance() + 0.05;
  return la > lb ? la / lb : lb / la;
}
