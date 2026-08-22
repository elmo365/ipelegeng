/// The launch decision — docs/entry-flow.md §5.2, invariants S-5 and S-6.
///
/// This is the test that did not exist, and its absence is why two of the three
/// bugs found on a Galaxy S24 on 2026-08-21 shipped. `/unlock` had a full suite
/// of its own and every one of those tests **constructed** a locked session and
/// pumped the screen directly, so the suite proved the screen worked and could
/// not notice that nothing in the app ever navigated to it. A test that builds
/// the state it is testing cannot tell you the state is reachable.
///
/// So everything here starts where a real launch starts: at
/// [Routes.splash], with a session that came out of the **store**, restored by
/// `SessionController.build` through `SessionCodec.reopened` — not handed in.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/session.dart';
import 'package:ipelege/core/session_store.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/entry_flow.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/ui/screens/entry/consent_screen.dart';
import 'package:ipelege/ui/screens/entry/splash_screen.dart';
import 'package:ipelege/ui/screens/entry/unlock_screen.dart';

void main() {
  /// A cold start with [stored] already on the device, or a fresh install when
  /// it is null. The router opens at the splash exactly as `main()` leaves it.
  Future<ProviderContainer> launch(WidgetTester tester, Session? stored) async {
    final store = InMemorySessionStore();
    // Through `write`, not `store`: the keep test is part of what is being
    // exercised — a mid-verification session must not survive a launch.
    if (stored != null) store.write(stored);

    late final ProviderContainer container;
    container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        routerProvider.overrideWith(
          (ref) => createRouter(
            initialLocation: Routes.splash,
            readSession: () => container.read(sessionProvider),
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
    return container;
  }

  const member = Session(
    stage: SessionStage.active,
    name: 'Kabo Mothibi',
    phone: '71 234 567',
    consentVersion: Consent.current,
    biometricOffered: true,
    biometricUnlock: true,
    locationGranted: true,
    locationAsked: true,
  );

  group('a stored session never meets the welcome screen — S-5', () {
    testWidgets('it opens on unlock instead', (tester) async {
      final container = await launch(tester, member);

      expect(
        container.read(sessionProvider).stage,
        SessionStage.locked,
        reason: 'the restore itself must lock — S-4',
      );
      expect(find.byType(UnlockScreen), findsOneWidget);
      expect(
        find.byType(SplashScreen),
        findsNothing,
        reason:
            'the welcome screen offers "Get started" and "Sign in" and nothing '
            'else, so showing it to a member is what made a reopen cost an SMS '
            'and then a too-many-requests',
      );
    });

    testWidgets('and it does so with biometrics switched off', (tester) async {
      // The preference decides what /unlock offers first, never whether it
      // appears. Branching here is what the OTP-on-every-open rule used to do,
      // and it was dropped because an SMS cannot tell a thief from an owner
      // when the SIM is in the handset they are holding.
      await launch(tester, member.copyWith(biometricUnlock: false));

      expect(find.byType(UnlockScreen), findsOneWidget);
    });

    testWidgets('a session owing consent lands on consent', (tester) async {
      await launch(
        tester,
        const Session(
          stage: SessionStage.needsConsent,
          name: 'Kabo Mothibi',
          phone: '71 234 567',
        ),
      );

      expect(find.byType(ConsentScreen), findsOneWidget);
    });
  });

  group('and everyone else still gets it', () {
    testWidgets('a fresh install sees the welcome screen', (tester) async {
      await launch(tester, null);

      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('so does a device that was signed out of', (tester) async {
      // Sign-out clears the store, so this is the fresh-install path arrived at
      // a different way — and it must be, because there is nothing to return to.
      final container = await launch(tester, member);
      container.read(sessionProvider.notifier).signOut();
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).stage, SessionStage.none);
      expect(launchRoute(container.read(sessionProvider)), Routes.splash);
    });

    testWidgets('an abandoned verification does not resume into itself', (
      tester,
    ) async {
      // Not worth keeping: the code it was waiting for has expired, and a form
      // that cannot accept anything is worse than starting the round again.
      await launch(
        tester,
        const Session(
          stage: SessionStage.confirmingNumber,
          phone: '71 234 567',
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });

  group('unlocking gets all the way in — S-6', () {
    testWidgets('from a launch, not from an initialLocation', (tester) async {
      final container = await launch(tester, member);
      expect(find.byType(UnlockScreen), findsOneWidget);

      // The screen's own two buttons are covered by unlock_test.dart. What is
      // being proved here is only that the state it needs is reachable.
      container.read(sessionProvider.notifier).unlock();
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).stage, SessionStage.active);
      expect(nextEntryRoute(container.read(sessionProvider)), Routes.home);
    });
  });

  group('the ladder after a verification — nextEntryRoute', () {
    test('consent comes before everything, including a spent offer', () {
      expect(
        nextEntryRoute(
          const Session(
            stage: SessionStage.needsConsent,
            biometricOffered: true,
          ),
        ),
        Routes.consent,
      );
    });

    test('the biometric offer is made once', () {
      const fresh = Session(
        stage: SessionStage.active,
        consentVersion: Consent.current,
      );
      expect(nextEntryRoute(fresh), Routes.biometricEnrolment);
      expect(
        nextEntryRoute(fresh.copyWith(biometricOffered: true)),
        Routes.location,
      );
    });

    test('a refused location is an answer, not a deferral', () {
      // The bug this pins: the ladder used to read `locationGranted`, so
      // refusing looked identical to never having been asked and produced the
      // screen again on every single entry.
      const refused = Session(
        stage: SessionStage.active,
        consentVersion: Consent.current,
        biometricOffered: true,
        locationAsked: true,
        locationGranted: false,
      );
      expect(nextEntryRoute(refused), Routes.home);
    });
  });
}
