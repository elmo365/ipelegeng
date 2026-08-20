import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/theme/app_theme.dart';
import 'package:ipelege/theme/tokens.dart';
import 'package:ipelege/theme/typography.dart';
import 'package:ipelege/ui/components/category_tile.dart';
import 'package:ipelege/ui/components/money_text.dart';
import 'package:ipelege/ui/components/status_chip.dart';

/// Components are tested in both themes, because a two-theme design's most
/// common defect is a light token reused inside a dark widget.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, ThemeData theme) =>
      tester.pumpWidget(
        MaterialApp(theme: theme, home: Scaffold(body: Center(child: child))),
      );

  final themes = {
    'light': (AppTheme.light, AppPalette.light),
    'dark': (AppTheme.dark, AppPalette.dark),
  };

  group('StatusChip', () {
    themes.forEach((name, pair) {
      final (theme, palette) = pair;

      testWidgets('$name verified chip takes its tone from the palette', (
        tester,
      ) async {
        await pump(tester, const StatusChip.verified('Plumbing'), theme);

        expect(find.text('Verified · Plumbing'), findsOneWidget);

        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(StatusChip),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = box.decoration as BoxDecoration;
        expect(decoration.color, palette.verifiedBg);
      });

      testWidgets('$name new-provider chip states absence, not fault', (
        tester,
      ) async {
        await pump(tester, const StatusChip.newProvider(), theme);
        expect(find.text('New on Ipelege'), findsOneWidget);

        // The restyle moved the neutral token itself off grey and onto a
        // tinted blue plate, so this chip reads as information rather than as
        // a disabled state. It is the chip a provider with no history wears,
        // and grey made that look like a fault.
        final label = tester.widget<Text>(find.text('New on Ipelege'));
        expect(label.style?.color, palette.chipNeutralText);

        // And it is the one tone with no glyph: there is no icon for
        // "nothing has happened yet" that does not read as a warning.
        expect(
          find.descendant(
            of: find.byType(StatusChip),
            matching: find.byType(Icon),
          ),
          findsNothing,
        );
      });

      testWidgets('$name status chips pair a hue with a glyph', (
        tester,
      ) async {
        // "Status never depends on colour alone" — the design states this as
        // a rule, and it is also what keeps the chip legible to a
        // colour-blind user.
        for (final (chipTone, glyph) in [
          (ChipTone.verified, Icons.verified_user),
          (ChipTone.pending, Icons.hourglass_top),
          (ChipTone.danger, Icons.error),
        ]) {
          await pump(
            tester,
            StatusChip(label: 'Status', tone: chipTone),
            theme,
          );
          expect(
            find.byIcon(glyph),
            findsOneWidget,
            reason: '$chipTone must carry $glyph',
          );
        }
      });
    });
  });

  group('CategoryTile', () {
    themes.forEach((name, pair) {
      final (theme, _) = pair;

      testWidgets('$name holds the category hue across the theme swap', (
        tester,
      ) async {
        await pump(
          tester,
          const CategoryTile(
            category: Categories.plumbing,
            supplyLabel: '6 nearby',
          ),
          theme,
        );

        expect(find.text('Plumbing'), findsOneWidget);

        // The tinted plate takes the category's own hue in either theme, and
        // the Material Symbol on it takes the matching ink. The monogram is
        // gone: identity is carried by icon and hue, not by two grey letters.
        final plate = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(CategoryTile),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (plate.decoration as BoxDecoration).color,
          Categories.plumbing.plateOf(theme.brightness),
        );

        final icon = tester.widget<Icon>(
          find.descendant(
            of: find.byType(CategoryTile),
            matching: find.byType(Icon),
          ),
        );
        expect(icon.icon, Icons.plumbing);
        expect(icon.color, Categories.plumbing.inkOf(theme.brightness));
      });

      testWidgets('$name states supply honestly rather than hiding it', (
        tester,
      ) async {
        // Thin supply is shown, not suppressed — a home screen that hides low
        // supply looks broken the moment the customer taps in.
        await pump(
          tester,
          const CategoryTile(
            category: Categories.tiling,
            supplyLabel: '4 nearby',
          ),
          theme,
        );
        expect(find.text('4 nearby'), findsOneWidget);
      });
    });

    testWidgets('the supply count is never truncated on a 360 dp phone', (
      tester,
    ) async {
      // Found in Phase 0, on a handset: every thin category was rendering as
      // "New in Gaborone · 6 plum…". An ellipsis here hides the exact number
      // the tile exists to state, which turns an honest young category back
      // into a vague one — the failure the supply copy was written against.
      const longest = 'New in Gaborone · 6 plumbers';

      // Measure in the real face. The default test font draws every glyph a
      // full em wide, which makes this string about twice its true width and
      // would fail the check on a screen where it actually fits.
      final plex = FontLoader('IBMPlexSans')
        ..addFont(rootBundle.load('assets/fonts/IBMPlexSans-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/IBMPlexSans-Medium.ttf'));
      await plex.load();

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: CategoryGrid(
              supplyLabels: {'plumbing': longest},
              standings: {'plumbing': SupplyStanding.thin},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(longest),
      );
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason:
            'the supply count is being ellipsised, so the count is hidden — '
            'give it the lines it needs or shorten the copy, never both',
      );
    });

    testWidgets('the grid goes two columns on a phone, three when wider', (
      tester,
    ) async {
      Future<int> columnsAt(double width) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SizedBox(width: width, child: const CategoryGrid()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final grid = tester.widget<GridView>(find.byType(GridView));
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        return delegate.crossAxisCount;
      }

      expect(await columnsAt(360), 2);
      expect(await columnsAt(700), 3);
    });
  });

  group('MoneyText', () {
    testWidgets('renders through the Pula formatter in the mono face', (
      tester,
    ) async {
      await pump(tester, MoneyText(Decimal.parse('1250')), AppTheme.light);

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, 'P1 250.00');
      expect(text.style?.fontFamily, AppFonts.mono);
    });

    testWidgets('a signed credit and debit read differently', (tester) async {
      await pump(
        tester,
        MoneyText(Decimal.parse('250'), signed: true),
        AppTheme.light,
      );
      final credit = tester.widget<Text>(find.byType(Text));
      expect(credit.data, '+P250.00');
      expect(credit.style?.color, AppPalette.light.creditColor);

      await pump(
        tester,
        MoneyText(Decimal.parse('-250'), signed: true),
        AppTheme.light,
      );
      final debit = tester.widget<Text>(find.byType(Text));
      expect(debit.data, '−P250.00');
      expect(debit.style?.color, AppPalette.light.dangerText);
    });

    testWidgets('a screen reader hears words, not glyphs', (tester) async {
      await pump(
        tester,
        MoneyText(Decimal.parse('-1250.5'), signed: true),
        AppTheme.light,
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.semanticsLabel, 'minus 1250.50 Pula');
    });
  });
}
