import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/ui/screens/consumer/listing_detail_screen.dart';
import 'package:ipelege/ui/screens/entry/splash_screen.dart';
import 'package:ipelege/ui/shell/app_shell.dart';

/// Navigation is the part of the design most easily broken by a later change,
/// because the three movements look alike on screen. These tests hold the
/// distinctions that matter: two separate tab sets, one stack per tab, and a
/// mode switch that discards rather than suspends.
void main() {
  /// Starts inside the shell. These tests are about tab behaviour, and since
  /// Phase 1 the app's own cold start lands on the splash instead — which is
  /// asserted on its own below rather than assumed by every test here.
  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        routerProvider.overrideWithValue(
          createRouter(initialLocation: Routes.home),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpelegeApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('cold start lands on the splash, not on a tab', (tester) async {
    // Phase 1 changed what a cold start means. Before it, the app booted
    // straight into the consumer shell with no way to sign in at all; now it
    // opens on the entry flow, and the tab bar does not exist until there is
    // an account.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpelegeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.text('Get started'), findsOneWidget);
    // "Already have an account? Sign in" is one rich span, so the sign-in
    // route has to be found inside it. That the route is visible here at all
    // is the design's point: a returning user must not have to tap
    // "Get started" to find it.
    expect(find.textContaining('Sign in', findRichText: true), findsOneWidget);
  });

  testWidgets('the consumer shell carries four tabs', (tester) async {
    await pumpApp(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
  });

  testWidgets('changing tab is lateral — it swaps content in place', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.event_note_outlined));
    await tester.pumpAndSettle();

    // The bar itself does not change; only which tab is selected.
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byIcon(Icons.event_note), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
  });

  testWidgets('each tab keeps its own stack across a switch', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(routerProvider);

    // Go deep inside the Home tab.
    router.push(Routes.listingOf('abc'));
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailScreen), findsWidgets);

    // Leave and come back. The pushed screen is still there.
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailScreen), findsNothing);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailScreen), findsWidgets);
  });

  testWidgets('tapping the tab you are on returns it to its root', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).push(Routes.listingOf('abc'));
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailScreen), findsWidgets);

    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();

    expect(find.byType(ListingDetailScreen), findsNothing);
  });

  testWidgets('switching mode replaces the bar rather than adding to it', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final router = container.read(routerProvider);

    router.go(Routes.dashboard);
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Listings'), findsOneWidget);
    // No consumer tab survives the switch.
    expect(find.text('Messages'), findsNothing);
    expect(find.text('Bookings'), findsNothing);
  });

  testWidgets('the wallet hangs off the dashboard, not the tab bar', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final router = container.read(routerProvider);

    router.go(Routes.dashboard);
    await tester.pumpAndSettle();
    expect(find.text('Wallet'), findsNothing);

    router.push(Routes.wallet);
    await tester.pumpAndSettle();
    expect(find.text('Wallet'), findsWidgets);
  });
}
