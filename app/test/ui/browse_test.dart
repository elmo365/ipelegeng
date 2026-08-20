/// Browse and listing detail — the trust rules.
///
/// The load-bearing one: verification and rating are **separate signals**, and
/// a provider with zero completed jobs must still be bookable and must never
/// be given a fabricated rating. Lynk's shutdown traced partly to ratings
/// working too well; these tests are what stop that being re-introduced by a
/// well-meaning "empty state" change.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/demo_data.dart';
import 'package:ipelege/theme/app_theme.dart';
import 'package:ipelege/theme/tokens.dart';
import 'package:ipelege/ui/screens/consumer/category_browse_screen.dart';
import 'package:ipelege/ui/screens/consumer/listing_detail_screen.dart';

Future<void> pump(
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

  group('category browse', () {
    themes.forEach((name, theme) {
      testWidgets('$name lays out at 360 dp without overflowing', (
        tester,
      ) async {
        await pump(
          tester,
          CategoryBrowseScreen(data: Demo.browse('plumbing')),
          theme: theme,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('names the city with the provider count', (tester) async {
      await pump(tester, CategoryBrowseScreen(data: Demo.browse('plumbing')));

      // A count with no city is a count you cannot trust — supply is a
      // per-city fact.
      expect(find.text('Gaborone · 3 providers'), findsOneWidget);
    });

    testWidgets('a provider with zero jobs is still listed and bookable', (
      tester,
    ) async {
      await pump(tester, CategoryBrowseScreen(data: Demo.browse('plumbing')));

      expect(find.text('Kabelo’s Plumbing & Repairs'), findsOneWidget);
      // Both signals, side by side: verified is a compliance fact from day
      // one, "new" is the absence of a review history.
      expect(find.text('Verified · Plumbing'), findsWidgets);
      expect(find.text('New on Ipelege'), findsWidgets);
    });

    testWidgets('the direction filter narrows the list', (tester) async {
      await pump(tester, CategoryBrowseScreen(data: Demo.browse('plumbing')));

      expect(find.text('Gaborone Drain Care'), findsOneWidget);

      await tester.tap(find.text('Comes to you'));
      await tester.pumpAndSettle();

      // The workshop-based provider drops out; the two mobile ones stay.
      expect(find.text('Gaborone Drain Care'), findsNothing);
      expect(find.text('Kabelo’s Plumbing & Repairs'), findsOneWidget);
      expect(find.text('Tumelo Pipeworks'), findsOneWidget);
    });

    testWidgets('an empty category says so instead of spinning', (
      tester,
    ) async {
      // Catering has no demo listings — the honest empty case.
      await pump(tester, CategoryBrowseScreen(data: Demo.browse('catering')));

      expect(find.text('Nobody here yet'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('listing detail', () {
    themes.forEach((name, theme) {
      testWidgets('$name lays out at 360 dp without overflowing', (
        tester,
      ) async {
        await pump(
          tester,
          ListingDetailScreen(data: Demo.listing),
          theme: theme,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('states the zero and what verification actually covers', (
      tester,
    ) async {
      await pump(tester, ListingDetailScreen(data: Demo.listing));

      expect(find.textContaining('0 completed jobs yet'), findsOneWidget);
      expect(
        find.textContaining('independent of a review history'),
        findsOneWidget,
      );
    });

    testWidgets('never invents a rating for a provider with no jobs', (
      tester,
    ) async {
      await pump(tester, ListingDetailScreen(data: Demo.listing));

      expect(Demo.listing.completedJobs, 0);
      expect(Demo.listing.rating, isNull);
      // No stars anywhere: a rating that does not exist is not drawn as empty
      // stars either, because that reads as "rated badly".
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('the booking action is present despite zero jobs', (
      tester,
    ) async {
      await pump(tester, ListingDetailScreen(data: Demo.listing));

      expect(
        find.widgetWithText(ElevatedButton, 'Request booking'),
        findsOneWidget,
      );
    });

    testWidgets('says plainly that Ipelege never takes the payment', (
      tester,
    ) async {
      await pump(tester, ListingDetailScreen(data: Demo.listing));

      // At the moment it matters, not buried in terms.
      expect(
        find.textContaining('Ipelege never handles your payment'),
        findsOneWidget,
      );
      expect(find.textContaining('cash or by mobile money'), findsOneWidget);
    });

    testWidgets('the price states its basis, not just a figure', (
      tester,
    ) async {
      await pump(tester, ListingDetailScreen(data: Demo.listing));

      expect(find.text('P150.00'), findsOneWidget);
      expect(
        find.textContaining('The quote comes back on your request'),
        findsOneWidget,
      );
    });
  });

  group('new-provider boost', () {
    Listing at(int i, {required bool isNew}) => Listing(
      id: 'L-$i',
      name: 'Provider $i',
      tag: 'tag',
      fromPrice: Decimal.parse('100.00'),
      direction: ServiceDirection.comesToYou,
      verified: true,
      isNew: isNew,
    );

    test('lifts a buried new provider into the top three', () {
      // Labelling someone "New on Ipelege" is only half the fix — a provider
      // nobody scrolls to never gets a first job, which is the failure that
      // contributed to Lynk's shutdown.
      final ranked = CategoryBrowseData.rank([
        at(0, isNew: false),
        at(1, isNew: false),
        at(2, isNew: false),
        at(3, isNew: false),
        at(4, isNew: true),
      ]);

      expect(ranked[1].id, 'L-4');
      // Second position, not first: the boost earns a look, it does not claim
      // to be the best match.
      expect(ranked.first.id, 'L-0');
    });

    test('does not reorder when a new provider is already visible', () {
      final original = [
        at(0, isNew: false),
        at(1, isNew: true),
        at(2, isNew: false),
        at(3, isNew: false),
      ];
      expect(
        CategoryBrowseData.rank(original).map((l) => l.id),
        original.map((l) => l.id),
      );
    });

    test('does not compound as more new providers join', () {
      // Exactly one slot, not a re-sort. Established providers are not buried
      // to make the point.
      final ranked = CategoryBrowseData.rank([
        at(0, isNew: false),
        at(1, isNew: false),
        at(2, isNew: false),
        at(3, isNew: true),
        at(4, isNew: true),
        at(5, isNew: true),
      ]);

      expect(ranked.where((l) => l.isNew).length, 3);
      expect(ranked.take(3).where((l) => l.isNew).length, 1);
    });
  });

  group('journey shape decides the action', () {
    testWidgets('property rentals enquires — it never offers a booking', (
      tester,
    ) async {
      // Pay-per-listing: no booking, no commission, no completion. The tenant
      // enquires and leaves the app.
      final rental = ListingDetailData(
        name: 'Block 8 Rooms',
        category: Categories.rentals,
        location: 'Block 8, Gaborone',
        direction: ServiceDirection.youGoToThem,
        startingFrom: Decimal.parse('1200.00'),
        priceNote: 'Per room, per month.',
        verified: true,
        completedJobs: 0,
      );

      await pump(tester, ListingDetailScreen(data: rental));

      expect(find.text('Enquire about this room'), findsOneWidget);
      expect(find.text('Request booking'), findsNothing);
      expect(Categories.rentals.shape.books, isFalse);
    });

    testWidgets('a browse-and-book category does offer a booking', (
      tester,
    ) async {
      await pump(tester, ListingDetailScreen(data: Demo.listing));

      expect(find.text('Request booking'), findsOneWidget);
      expect(Categories.plumbing.shape.books, isTrue);
    });

    test('rides is dispatch, rentals is pay-per-listing, the rest book', () {
      expect(Categories.rides.shape, JourneyShape.dispatch);
      expect(Categories.rentals.shape, JourneyShape.payPerListing);
      for (final c in Categories.all) {
        if (c.key == 'rides' || c.key == 'rentals') continue;
        expect(
          c.shape,
          JourneyShape.browseAndBook,
          reason: '${c.label} should be browse-and-book',
        );
      }
    });
  });

  group('rides is not a browse category', () {
    test('the dispatch shape skips browse and listing detail', () {
      // Rides goes straight to nearby drivers with sufficient credit
      // (FR-3.10). If it ever gains listings, this shape has changed and the
      // home screen's hero has to change with it.
      expect(Demo.browse('rides').listings, isEmpty);
      expect(Categories.rides.key, 'rides');
    });
  });
}
