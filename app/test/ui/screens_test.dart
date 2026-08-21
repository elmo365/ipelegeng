/// Dashboard and home, and the decisions they are required to hold.
///
/// The layout assertions matter here for one specific reason: these screens
/// are built for low-end Android at 360 dp, so anything that overflows at that
/// width is a bug on the target device, not a test artefact. Each screen is
/// pumped at 360 dp in both themes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/demo_data.dart';
import 'package:ipelege/theme/app_theme.dart';
import 'package:ipelege/theme/tokens.dart';
import 'package:ipelege/ui/components/category_tile.dart';
import 'package:ipelege/ui/components/week_chart.dart';
import 'package:ipelege/ui/screens/consumer/home_screen.dart';
import 'package:ipelege/ui/screens/provider/dashboard_screen.dart';

/// A 360 dp phone, tall enough to lay the whole screen out at once.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: theme ?? AppTheme.light, home: screen),
  );
  await tester.pumpAndSettle();
}

void main() {
  final themes = {'light': AppTheme.light, 'dark': AppTheme.dark};

  group('provider dashboard', () {
    themes.forEach((name, theme) {
      testWidgets('$name lays out at 360 dp without overflowing', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          ProviderDashboardScreen(data: Demo.dashboard),
          theme: theme,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('shows the month as a chart, not as a sentence', (
      tester,
    ) async {
      await pumpScreen(tester, ProviderDashboardScreen(data: Demo.dashboard));

      // Seven bars, today emphasised, plus the delta pill.
      expect(find.byType(WeekChart), findsOneWidget);
      expect(find.byType(DeltaPill), findsOneWidget);
      expect(tester.widget<WeekChart>(find.byType(WeekChart)).values.length, 7);
    });

    testWidgets('never renders "provider" as one status', (tester) async {
      await pumpScreen(tester, ProviderDashboardScreen(data: Demo.dashboard));

      // The matrix is the normal case: one account, several categories, each
      // at its own point in its own verification flow.
      expect(find.text('Movers & hauling'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Property rentals'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('states that Ipelege never took the customer’s money', (
      tester,
    ) async {
      await pumpScreen(tester, ProviderDashboardScreen(data: Demo.dashboard));

      expect(
        find.textContaining('never handles your customer’s payment'),
        findsOneWidget,
      );
    });

    testWidgets('offers a top up but no way to withdraw', (tester) async {
      await pumpScreen(tester, ProviderDashboardScreen(data: Demo.dashboard));

      expect(find.text('Top up'), findsOneWidget);
      expect(find.textContaining('Withdraw'), findsNothing);
    });
  });

  group('consumer home', () {
    themes.forEach((name, theme) {
      testWidgets('$name lays out at 360 dp without overflowing', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          ConsumerHomeScreen(data: Demo.home),
          theme: theme,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('gives rides the hero and the other eight the grid', (
      tester,
    ) async {
      await pumpScreen(tester, ConsumerHomeScreen(data: Demo.home));

      // Rides is the dispatch shape: it skips browse and listing detail
      // entirely, so it is an entry point rather than a tile. The other eight
      // are browse-and-book or pay-per-listing, and those go in the grid.
      expect(Categories.all.length, 9);
      expect(find.byType(CategoryTile), findsNWidgets(8));
      expect(find.text('Rides'), findsNothing);
      expect(find.text('Need a ride?'), findsOneWidget);
      expect(find.text('62 drivers nearby right now'), findsOneWidget);
    });

    testWidgets('a thin category reads as new, not as broken', (tester) async {
      await pumpScreen(tester, ConsumerHomeScreen(data: Demo.home));

      // The count is never hidden — but its framing is the decision. "New in
      // Gaborone · 2 providers" says young; "2 nearby" says failing. If a
      // future change flattens this back to a bare count, this catches it.
      expect(find.text('New in Gaborone · 2 providers'), findsOneWidget);
      expect(find.text('New in Gaborone · 3 tilers'), findsOneWidget);

      // No bare "N nearby" on any tile. The rides hero still says "62 drivers
      // nearby right now", which is the dispatch promise rather than a supply
      // count, so the check is scoped to the grid.
      expect(
        find.descendant(
          of: find.byType(CategoryTile),
          matching: find.textContaining('nearby'),
        ),
        findsNothing,
      );
    });

    testWidgets('standing is spoken, not only tinted', (tester) async {
      await pumpScreen(tester, ConsumerHomeScreen(data: Demo.home));

      // The dot is colour alone, so the standing has to reach a screen-reader
      // user in words.
      final hire = tester.getSemantics(
        find.ancestor(
          of: find.text('Hire'),
          matching: find.byType(CategoryTile),
        ),
      );
      expect(hire.label, contains('new in this city'));
    });

    testWidgets('six of nine are thin at launch — the design condition', (
      tester,
    ) async {
      // Seeding goes deep rather than wide, so most categories look new for
      // months. If this ratio quietly improves, someone has invented supply.
      final thin = Demo.home.standings.values
          .where((s) => s == SupplyStanding.thin)
          .length;
      expect(thin, 6);
      expect(Demo.home.standings.length, 9);
    });

    testWidgets('every category carries a count', (tester) async {
      await pumpScreen(tester, ConsumerHomeScreen(data: Demo.home));

      for (final category in Categories.all) {
        expect(
          Demo.home.supplyLabels.containsKey(category.key),
          isTrue,
          reason: '${category.label} has no supply count',
        );
      }
    });

    testWidgets('a visitor can browse without being asked for a number', (
      tester,
    ) async {
      await pumpScreen(tester, ConsumerHomeScreen(data: Demo.home));

      // UC-4 gives browse rights: the account wall belongs at the booking
      // action, not at launch.
      expect(Demo.home.customerName, isNull);
      expect(find.byType(CategoryTile), findsNWidgets(8));
      expect(find.textContaining('Sign in'), findsNothing);
    });
  });
}
