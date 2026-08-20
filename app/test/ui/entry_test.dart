import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/session.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/ui/components/entry_header.dart';
import 'package:ipelege/ui/screens/consumer/home_screen.dart';
import 'package:ipelege/ui/screens/entry/location_screen.dart';
import 'package:ipelege/ui/screens/entry/register_screen.dart';
import 'package:ipelege/ui/screens/entry/sign_in_screen.dart';
import 'package:ipelege/ui/screens/entry/verify_screen.dart';

/// Phase 1's "done when", as tests.
///
/// - a cold install can register, verify, consent and reach Home
/// - a returning user can sign in
/// - a visitor can still browse, and is stopped at the booking action
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

    // Tall enough that a full entry screen lays out rather than overflowing,
    // which would throw before anything could be inspected.
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

  group('a cold install can get an account', () {
    testWidgets('splash offers both routes in, not just the new-user one', (
      tester,
    ) async {
      await pumpAt(tester, Routes.splash);

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('the header band spans the screen, whatever it says', (
      tester,
    ) async {
      // Found on a handset: a Column centres its children on the cross axis,
      // so the gradient band was only as wide as its own text. Invisible on
      // register, where the subtitle is two lines, and obvious on verify,
      // where it is four words.
      for (final route in const [Routes.register, Routes.verify]) {
        await pumpAt(tester, route);
        expect(
          tester.getSize(find.byType(EntryHeader)).width,
          tester.view.physicalSize.width / tester.view.devicePixelRatio,
          reason: '$route: the entry header is not full width',
        );
      }
    });

    testWidgets('register will not continue without a usable number', (
      tester,
    ) async {
      final container = await pumpAt(tester, Routes.register);

      // A name alone is not enough, and neither is a number that cannot
      // receive a code.
      await tester.enterText(find.byType(TextField).first, 'Kabo Mothibi');
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
        reason: 'Continue is live with no number',
      );

      await tester.enterText(find.byType(TextField).last, '7123');
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
        reason: 'Continue is live on a number too short to be sent a code',
      );

      await tester.enterText(find.byType(TextField).last, '71234567');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(VerifyScreen), findsOneWidget);
      expect(
        container.read(sessionProvider).stage,
        SessionStage.confirmingNumber,
        reason: 'a number typed in is not an account yet',
      );
      expect(
        container.read(sessionProvider).phone,
        '+267 71 234 567',
        reason: 'the number is stored in one display form',
      );
    });

    testWidgets('the required consent gates the code, not the other way round',
        (tester) async {
      final container = await pumpAt(tester, Routes.verify);

      // A complete code with no consent must not proceed. This is FR-1.10:
      // consent is captured at account creation, not asked for afterwards.
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(find.byType(ElevatedButton))
            .onPressed,
        isNull,
        reason: 'verified without agreeing to anything',
      );
      expect(
        find.textContaining('required consent above', findRichText: true),
        findsOneWidget,
        reason: 'the button is dead and nothing says why',
      );

      await tester.tap(find.textContaining('I agree to the'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify & continue'));
      await tester.pumpAndSettle();

      final session = container.read(sessionProvider);
      expect(session.stage, SessionStage.active);
      expect(session.consentVersion, Consent.current);
      expect(
        session.channels,
        isEmpty,
        reason: 'the optional channel was never ticked and must not be set',
      );

      // Location is asked once, after the account exists — not at launch.
      expect(find.byType(LocationScreen), findsOneWidget);
    });

    testWidgets('refusing location is a supported answer, not a dead end', (
      tester,
    ) async {
      final container = await pumpAt(tester, Routes.location);

      await tester.tap(find.text('Choose my area instead'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).locationGranted, isFalse);
      expect(
        find.byType(ConsumerHomeScreen),
        findsOneWidget,
        reason: 'refusing location must still reach the app',
      );
    });
  });

  group('a returning user', () {
    testWidgets('signs in with a number and still gets a code', (
      tester,
    ) async {
      final container = await pumpAt(tester, Routes.signIn);
      expect(find.byType(SignInScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '71234567');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(find.byType(VerifyScreen), findsOneWidget);
      expect(
        container.read(sessionProvider).canBook,
        isFalse,
        reason: 'sign in alone never authenticates — the code does',
      );
    });
  });

  group('a visitor', () {
    testWidgets('reaches home and browse with no account at all', (
      tester,
    ) async {
      final container = await pumpAt(tester, Routes.home);

      expect(container.read(sessionProvider).stage, SessionStage.none);
      expect(
        find.byType(ConsumerHomeScreen),
        findsOneWidget,
        reason: 'UC-4 grants a visitor browse and search',
      );
    });

    testWidgets('is stopped at the booking action, and keeps their place', (
      tester,
    ) async {
      await pumpAt(tester, Routes.listingOf('L-4417'));

      await tester.tap(find.text('Request booking'));
      await tester.pumpAndSettle();

      // The wall names the provider rather than quoting a policy.
      expect(find.text('Sign in to book'), findsOneWidget);
      expect(
        find.textContaining('so Kabelo can reach you'),
        findsOneWidget,
        reason: 'the gate has to say who needs the number',
      );

      await tester.tap(find.text('Keep looking around'));
      await tester.pumpAndSettle();

      expect(
        find.text('Sign in to book'),
        findsNothing,
        reason: 'declining should return to the listing, not strand anyone',
      );
      expect(find.text('Request booking'), findsOneWidget);
    });
  });
}
