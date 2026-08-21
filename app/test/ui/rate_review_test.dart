import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/ui/components/actions.dart';
import 'package:ipelege/ui/screens/consumer/rate_review_screen.dart';

/// Phase 2's closing step, as tests.
///
/// The rule under all of these: **the app does not manufacture a rating.** It
/// does not pre-select one, it does not submit one nobody chose, and — as the
/// listing detail proves from the other side — it does not invent one for a
/// provider with no history.
void main() {
  Future<void> pumpAt(WidgetTester tester, String location) async {
    final container = ProviderContainer(
      overrides: [
        routerProvider.overrideWithValue(
          createRouter(initialLocation: location),
        ),
      ],
    );
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpelegeApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpRate(WidgetTester tester) =>
      pumpAt(tester, Routes.bookingRateOf('BK-77410'));

  /// The star at position [n], in render order.
  Finder starAt(int n) => find.byIcon(Icons.star).at(n - 1);

  Color colourOf(WidgetTester tester, int n) =>
      tester.widget<Icon>(starAt(n)).color!;

  group('the ask is made, and the reason with it', () {
    testWidgets('heading and subtitle are the canvas\'s own words', (
      tester,
    ) async {
      await pumpRate(tester);

      expect(find.byType(RateReviewScreen), findsOneWidget);
      expect(find.text('How did it go?'), findsOneWidget);
      expect(
        find.text('Your rating is the only signal a new provider has.'),
        findsOneWidget,
        reason:
            'the line explaining why the rating matters for a provider with '
            'no history is the point of the screen',
      );
    });

    testWidgets('the comment is labelled optional, and skip is a real target', (
      tester,
    ) async {
      await pumpRate(tester);

      expect(find.text('COMMENT · OPTIONAL'), findsOneWidget);
      expect(find.byType(QuietAction), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('the job being rated is named, with what it cost', (
      tester,
    ) async {
      await pumpRate(tester);
      expect(find.textContaining('Completed today · P250.00'), findsOneWidget);
    });
  });

  group('nothing is pre-selected', () {
    testWidgets('five stars render and none of them is set', (tester) async {
      await pumpRate(tester);

      expect(find.byIcon(Icons.star), findsNWidgets(RateReviewScreen.stars));

      // The canvas artboard sits at four stars the way its booking artboard
      // sits at REQUESTED — that is the demo's state, not a default.
      final unset = colourOf(tester, RateReviewScreen.stars);
      for (var n = 1; n <= RateReviewScreen.stars; n++) {
        expect(
          colourOf(tester, n),
          unset,
          reason: 'star $n is filled before the customer has chosen anything',
        );
      }
    });

    testWidgets('submit is dead until a star is tapped', (tester) async {
      await pumpRate(tester);

      expect(
        tester.widget<PrimaryAction>(find.byType(PrimaryAction)).onPressed,
        isNull,
        reason: 'a review could be submitted without a rating in it',
      );

      await tester.tap(starAt(4));
      await tester.pumpAndSettle();

      expect(
        tester.widget<PrimaryAction>(find.byType(PrimaryAction)).onPressed,
        isNotNull,
      );
    });

    testWidgets('tapping the fourth star fills four and leaves the fifth', (
      tester,
    ) async {
      await pumpRate(tester);
      await tester.tap(starAt(4));
      await tester.pumpAndSettle();

      final set = colourOf(tester, 1);
      for (var n = 1; n <= 4; n++) {
        expect(colourOf(tester, n), set, reason: 'star $n did not fill');
      }
      expect(
        colourOf(tester, 5),
        isNot(set),
        reason: 'the fifth star filled on a four-star rating',
      );
    });
  });

  group('the completed booking reaches it', () {
    testWidgets('COMPLETED\'s action is the one action that goes somewhere', (
      tester,
    ) async {
      await pumpAt(tester, '${Routes.bookingOf('BK-77410')}?state=COMPLETED');

      await tester.tap(find.text('Rate this booking'));
      await tester.pumpAndSettle();

      expect(find.byType(RateReviewScreen), findsOneWidget);
    });
  });
}
