import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/booking.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/ui/screens/consumer/booking_status_screen.dart';

/// Phase 2's promises, as tests.
///
/// The copy assertions are deliberate: every string on this screen comes from
/// the canvas's `BSTATES` array, and a paraphrase here is a changed promise
/// about money. If one of these fails, check the canvas before changing the
/// expectation.
void main() {
  Future<void> pumpState(WidgetTester tester, String key) async {
    final container = ProviderContainer(
      overrides: [
        routerProvider.overrideWithValue(
          createRouter(
            initialLocation: '${Routes.bookingOf('BK-77410')}?state=$key',
          ),
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

  group('all eleven states render', () {
    test('the design gives eleven, and eleven is what we carry', () {
      expect(BookingState.all.length, 11);
    });

    for (final state in BookingState.all) {
      testWidgets('${state.key} shows its own heading and action', (
        tester,
      ) async {
        await pumpState(tester, state.key);

        expect(find.byType(BookingStatusScreen), findsOneWidget);
        expect(
          find.text(state.head),
          findsOneWidget,
          reason: '${state.key} is not showing its heading',
        );
        expect(
          find.text(state.action),
          findsOneWidget,
          reason: '${state.key} is not offering its single action',
        );
      });
    }
  });

  group('the payment moment', () {
    test('sits at step 4, before the provider marks complete', () {
      // Order is the correction the whole phase exists to carry: activity
      // diagram A-2 puts paying the provider *before* "mark complete".
      final keys = BookingState.all.map((b) => b.key).toList();
      expect(
        keys.indexOf('AWAITING_PAYMENT'),
        lessThan(keys.indexOf('PENDING_CONFIRMATION')),
      );
      expect(BookingState.byKey('AWAITING_PAYMENT').step, 4);
      expect(BookingState.byKey('PENDING_CONFIRMATION').step, 5);
    });

    testWidgets('is the only state that gets the pay panel', (tester) async {
      await pumpState(tester, 'AWAITING_PAYMENT');
      expect(find.textContaining('PAY KABELO DIRECTLY, NOW'), findsOneWidget);

      // And it says, at full size, that the platform is not in the
      // transaction. This sentence is the one that must not be misread.
      expect(find.textContaining('never holds your money'), findsOneWidget);

      await pumpState(tester, 'IN_PROGRESS');
      expect(find.textContaining('PAY KABELO DIRECTLY, NOW'), findsNothing);
    });
  });

  group('endings do not pretend to be progress', () {
    testWidgets('a finished state hides the step bar entirely', (tester) async {
      // "Forward progress animates, every ending is instant." A step bar drawn
      // empty on a declined booking reads as progress lost rather than as an
      // ending.
      //
      for (final key in const ['DECLINED', 'EXPIRED', 'CANCELLED']) {
        await pumpState(tester, key);
        expect(
          find.byType(BookingStepBar),
          findsNothing,
          reason: '$key is drawing a step bar',
        );
      }

      // And a live state still shows it, so the assertion above is not passing
      // because the bar never renders at all.
      await pumpState(tester, 'ACCEPTED');
      expect(find.byType(BookingStepBar), findsOneWidget);
      expect(
        tester.widget<BookingStepBar>(find.byType(BookingStepBar)).step,
        2,
      );
    });
  });

  group('provisional copy ships with its caveat', () {
    testWidgets('the three unsettled states say so on the screen', (
      tester,
    ) async {
      // The design wrote these notes against itself. Building the state and
      // hiding the note would be worse than not building it: it would present
      // an unsettled rule as settled.
      const expected = {
        'CANCELLED': 'Cancellation rules are not settled',
        'NO_SHOW': 'No fee rule exists yet',
        'DISPUTED': 'Dispute handling is undesigned in the spec',
      };

      for (final entry in expected.entries) {
        await pumpState(tester, entry.key);
        expect(
          find.textContaining(entry.value),
          findsOneWidget,
          reason: '${entry.key} is not showing its provisional note',
        );
      }
    });

    test('no other state carries a caveat it does not need', () {
      final noted = BookingState.all
          .where((b) => b.note != null)
          .map((b) => b.key)
          .toSet();
      expect(noted, {
        'PENDING_CONFIRMATION',
        'CANCELLED',
        'NO_SHOW',
        'DISPUTED',
      });
    });
  });

  group('one action per state', () {
    test('never two primaries competing', () {
      for (final state in BookingState.all) {
        expect(
          state.action.isNotEmpty,
          isTrue,
          reason: '${state.key} has no action, so the screen is a dead end',
        );
      }
    });
  });
}
