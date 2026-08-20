/// The build order, enforced.
///
/// `docs/build-order.md` decides what gets built next. A document alone drifts:
/// it is easy to mark a phase done without finishing it, and easier still to
/// build a screen and forget to record it. So the declared state lives here as
/// well, and this suite checks it against what the router actually renders.
///
/// **Two failure modes, both caught:**
///
/// - A route listed in [_built] that still renders `PlaceholderScreen` — the
///   doc claims work that does not exist.
/// - A route listed in [_notBuilt] that renders something real — work landed
///   without the order being updated, which is how a phase gets skipped.
///
/// When this fails, fix `docs/build-order.md` and this file together. They are
/// one statement in two places on purpose: the duplication is what makes the
/// drift visible.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/ui/screens/placeholder_screen.dart';

/// Routes with a real screen behind them. Keep in step with the "Where things
/// stand" section of docs/build-order.md.
const _built = <String>{
  // Phase 1 — the account gap.
  Routes.splash,
  Routes.register,
  Routes.signIn,
  Routes.verify,
  Routes.consent,
  Routes.unlock,
  Routes.biometricEnrolment,
  Routes.location,
  // Built during the resync, to validate the tokens.
  Routes.home,
  Routes.dashboard,
  Routes.wallet,
};

/// Routes still on `PlaceholderScreen`. Deliberate: the navigation graph stays
/// complete and testable while screens land one at a time.
const _notBuilt = <String>{
  Routes.bookings,
  Routes.messages,
  Routes.account,
  Routes.requests,
  Routes.listings,
  Routes.providerAccount,
};

void main() {
  Future<ProviderContainer> pumpAt(WidgetTester tester, String location) async {
    // Override the router rather than adding a test-only parameter to
    // IpelegeApp: production code should not grow a seam it does not need.
    final container = ProviderContainer(
      overrides: [
        routerProvider.overrideWithValue(
          createRouter(initialLocation: location),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Tall enough that a real screen lays out rather than overflowing, which
    // would throw before we could inspect what rendered.
    tester.view.physicalSize = const Size(1080, 3600);
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

  group('the build order matches what is actually built', () {
    for (final route in _built) {
      testWidgets('$route renders a real screen', (tester) async {
        await pumpAt(tester, route);
        expect(
          find.byType(PlaceholderScreen),
          findsNothing,
          reason:
              'docs/build-order.md claims $route is built, but it still '
              'renders PlaceholderScreen. Either finish it or stop claiming '
              'it.',
        );
      });
    }

    for (final route in _notBuilt) {
      testWidgets('$route is still a placeholder', (tester) async {
        await pumpAt(tester, route);
        expect(
          find.byType(PlaceholderScreen),
          findsOneWidget,
          reason:
              '$route now renders a real screen but docs/build-order.md does '
              'not record it. Update the order — a screen built out of '
              'sequence is how the account gap got skipped.',
        );
      });
    }
  });

  group('phase gates', () {
    test('no route is claimed both built and unbuilt', () {
      expect(_built.intersection(_notBuilt), isEmpty);
    });

    test('every tab root is accounted for', () {
      // A route that is in neither set is a route nobody is tracking.
      const tabRoots = {
        Routes.home,
        Routes.bookings,
        Routes.messages,
        Routes.account,
        Routes.dashboard,
        Routes.requests,
        Routes.listings,
        Routes.providerAccount,
      };
      expect(
        tabRoots.difference(_built.union(_notBuilt)),
        isEmpty,
        reason: 'an untracked route cannot be sequenced',
      );
    });

    test('every entry route is built — Phase 1 is all or nothing', () {
      // A half-built entry flow is worse than none: it strands someone
      // between a register screen and a verify screen that does not exist.
      expect(
        Routes.entry.toSet().difference(_built),
        isEmpty,
        reason: 'an entry route with no screen behind it is a dead end',
      );
    });

    test('the app opens on the entry flow, not inside the shell', () {
      // The defect Phase 1 existed to fix: the app booted straight to Home
      // with no splash, register, sign in or OTP anywhere. If this default
      // ever goes back to a tab root, the account gap has reopened.
      expect(
        createRouter().routeInformationProvider.value.uri.path,
        Routes.splash,
        reason:
            'createRouter() no longer starts at the splash, so a cold start '
            'skips the account gap again',
      );
    });
  });
}
