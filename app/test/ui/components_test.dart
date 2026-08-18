import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
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

        final label = tester.widget<Text>(find.text('New on Ipelege'));
        expect(label.style?.color, palette.chipNeutralText);
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
          const CategoryTile(category: Categories.plumbing),
          theme,
        );

        expect(find.text('Plumbing'), findsOneWidget);

        final monogram = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(CategoryTile),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (monogram.decoration as BoxDecoration).color,
          Categories.plumbing.hue,
        );
      });
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
