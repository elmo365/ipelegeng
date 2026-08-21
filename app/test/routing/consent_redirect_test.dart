/// Consent supersede, enforced.
///
/// FR-1.10 and the DPA require re-consent "before anything else proceeds". The
/// repo modelled that and did not route it: `Session.canBook` returned false on
/// a stale version and nothing sent the session anywhere, so a superseded user
/// could browse indefinitely and only met the rule at the booking action. That
/// is a weaker promise than the design makes.
///
/// The case only arises through [SessionController.restore] — the state machine
/// cannot otherwise produce an active session on an old version — which is the
/// same path session persistence will use.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/session.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/ui/screens/consumer/home_screen.dart';
import 'package:ipelege/ui/screens/entry/consent_screen.dart';

void main() {
  /// A router wired to the real session, the way `routerProvider` wires it.
  Future<ProviderContainer> pumpAt(
    WidgetTester tester,
    String location, {
    Session? restore,
  }) async {
    late final ProviderContainer container;
    container = ProviderContainer(
      overrides: [
        routerProvider.overrideWith(
          (ref) => createRouter(
            initialLocation: location,
            readSession: () => container.read(sessionProvider),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    if (restore != null) {
      container.read(sessionProvider.notifier).restore(restore);
    }

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

  /// Signed in yesterday, on a version that has since been superseded.
  const superseded = Session(
    stage: SessionStage.active,
    name: 'Kabo Mothibi',
    phone: '71 234 567',
    consentVersion: '2.0',
  );

  group('a superseded session cannot proceed', () {
    test('the state says so before any routing is involved', () {
      expect(superseded.needsReconsent, isTrue);
      expect(superseded.canBook, isFalse);
    });

    testWidgets('opening at Home lands on consent instead', (tester) async {
      await pumpAt(tester, Routes.home, restore: superseded);

      expect(find.byType(ConsentScreen), findsOneWidget);
      expect(
        find.byType(ConsumerHomeScreen),
        findsNothing,
        reason:
            'a superseded session reached Home, so re-consent is still a '
            'prompt someone has to remember to show',
      );
    });

    testWidgets('so does opening deep in a tab', (tester) async {
      // "Before anything else proceeds" is not "before booking".
      await pumpAt(tester, Routes.categoryOf('plumbing'), restore: superseded);

      expect(find.byType(ConsentScreen), findsOneWidget);
    });

    testWidgets('the redirect does not fight itself', (tester) async {
      // Sending /consent to /consent is a loop, and go_router throws on one
      // rather than hanging — so this passing at all is the assertion.
      await pumpAt(tester, Routes.consent, restore: superseded);

      expect(find.byType(ConsentScreen), findsOneWidget);
    });

    testWidgets('agreeing again releases them', (tester) async {
      final container = await pumpAt(tester, Routes.home, restore: superseded);
      expect(find.byType(ConsentScreen), findsOneWidget);

      container.read(sessionProvider.notifier).agree();
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).needsReconsent, isFalse);
      expect(container.read(sessionProvider).canBook, isTrue);
    });
  });

  group('and everyone else is left alone', () {
    testWidgets('a visitor still browses freely — UC-4', (tester) async {
      // The wall is at the booking action. Bouncing a stranger who has agreed
      // to nothing into a consent form is the exact wall the design moved.
      await pumpAt(tester, Routes.home);

      expect(find.byType(ConsumerHomeScreen), findsOneWidget);
      expect(find.byType(ConsentScreen), findsNothing);
    });

    testWidgets('a current session is not asked twice', (tester) async {
      await pumpAt(
        tester,
        Routes.home,
        restore: const Session(
          stage: SessionStage.active,
          consentVersion: Consent.current,
        ),
      );

      expect(find.byType(ConsumerHomeScreen), findsOneWidget);
    });

    testWidgets('a locked session goes to unlock, not to two gates at once', (
      tester,
    ) async {
      // Trapping someone behind unlock *and* an undismissable consent form is
      // a dead end. Unlocking makes the session active and the redirect fires
      // on the next movement.
      const locked = Session(stage: SessionStage.locked, consentVersion: '2.0');
      expect(locked.needsReconsent, isFalse);

      await pumpAt(tester, Routes.unlock, restore: locked);
      expect(find.byType(ConsentScreen), findsNothing);
    });
  });
}
