import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/demo_data.dart';
import 'package:ipelege/core/session.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/ui/screens/consumer/booking_request_screen.dart';
import 'package:ipelege/ui/screens/consumer/booking_status_screen.dart';
import 'package:ipelege/ui/screens/consumer/category_browse_screen.dart';

/// Phase 2's request step, as tests.
///
/// The copy assertions are deliberate, for the same reason the status screen's
/// are: this is the screen that says **nothing is charged now**, and a
/// paraphrase is a changed promise about money.
void main() {
  Future<ProviderContainer> pumpAt(WidgetTester tester, String location) async {
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
    return container;
  }

  Future<ProviderContainer> pumpRequest(WidgetTester tester) =>
      pumpAt(tester, Routes.bookingRequestOf('L-4417'));

  group('the direction set is the canvas\'s, not an inferred one', () {
    test('a customer chooses between exactly two', () {
      // `dirDefs` in the canvas script block. `either` is a property of a
      // listing — docs/booking.md's "Both" — and never an option offered here.
      expect(ServiceDirection.choices, [
        ServiceDirection.comesToYou,
        ServiceDirection.youGoToThem,
      ]);
      expect(
        ServiceDirection.choices.contains(ServiceDirection.either),
        isFalse,
      );
    });

    testWidgets('both cards render with the line the canvas wrote under them', (
      tester,
    ) async {
      await pumpRequest(tester);

      expect(find.byType(BookingRequestScreen), findsOneWidget);
      expect(find.text('Comes to you'), findsOneWidget);
      expect(find.text('Provider travels to your location'), findsOneWidget);
      expect(find.text('You go to them'), findsOneWidget);
      expect(find.text('Service is at their premises'), findsOneWidget);
    });
  });

  group('the location card follows the direction', () {
    testWidgets('asked for when the provider travels, dropped when they do not', (
      tester,
    ) async {
      // The canvas's `needsLocation`. Asking a customer for their address when
      // *they* are the one travelling collects a location with no purpose,
      // which under the DPA is a problem rather than a stray field.
      await pumpRequest(tester);
      expect(find.text('YOUR LOCATION'), findsOneWidget);
      expect(find.text(Demo.bookingRequest.customerLocation), findsOneWidget);

      await tester.tap(find.text('You go to them'));
      await tester.pumpAndSettle();
      expect(find.text('YOUR LOCATION'), findsNothing);
      expect(find.text(Demo.bookingRequest.customerLocation), findsNothing);

      // And back again, so the assertion above is not passing because the card
      // never renders at all.
      await tester.tap(find.text('Comes to you'));
      await tester.pumpAndSettle();
      expect(find.text('YOUR LOCATION'), findsOneWidget);
    });

    testWidgets('when is asked either way', (tester) async {
      await pumpRequest(tester);
      expect(find.text('WHEN'), findsOneWidget);

      await tester.tap(find.text('You go to them'));
      await tester.pumpAndSettle();
      expect(find.text('WHEN'), findsOneWidget);
    });
  });

  group('the money promise', () {
    testWidgets('says nothing is charged now, before anything is sent', (
      tester,
    ) async {
      await pumpRequest(tester);

      expect(
        find.textContaining('Nothing is charged now'),
        findsOneWidget,
        reason: 'the one sentence this screen exists to say is missing',
      );
      expect(find.textContaining('quotes you back'), findsOneWidget);
      expect(find.textContaining('you pay them directly'), findsOneWidget);
    });

    testWidgets('states the price as a starting figure, never as a total', (
      tester,
    ) async {
      await pumpRequest(tester);

      // "from P150.00" — a bare figure here reads as an amount about to be
      // taken, which is the misreading the whole flow is built to avoid.
      expect(find.textContaining('from P150.00'), findsOneWidget);
      expect(find.textContaining('Total'), findsNothing);
    });
  });

  group('the listing leads here, once there is an account', () {
    testWidgets('the booking action opens the form for a signed-in customer', (
      tester,
    ) async {
      // The other half of UC-4, which entry_test covers from the visitor's
      // side: the wall is at the booking action, and past it is this screen.
      final container = await pumpAt(tester, Routes.listingOf('L-4417'));
      container.read(sessionProvider.notifier)
        ..requestCode(phone: '71 234 567')
        ..agree();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Request booking'));
      await tester.pumpAndSettle();

      expect(find.byType(BookingRequestScreen), findsOneWidget);
    });
  });

  group('sending is a replace, not a push', () {
    testWidgets('the form is gone once the request exists', (tester) async {
      await pumpRequest(tester);

      await tester.tap(find.text('Send booking request'));
      await tester.pumpAndSettle();

      expect(find.byType(BookingStatusScreen), findsOneWidget);
      expect(
        find.byType(BookingRequestScreen),
        findsNothing,
        reason:
            'the request form is still on the stack, so a back gesture could '
            'send a second request for the same job',
      );
    });
  });
}
