/// The router.
///
/// Two [StatefulShellRoute]s — one per mode — each with a branch per tab, so
/// every tab keeps its own [Navigator] and its own stack. The two shells are
/// siblings rather than nested, which is what makes a mode switch discard the
/// other side's history instead of suspending it.
///
/// Screens do not call `go` or `push` directly; they use the three named
/// movements in routing/navigation.dart.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/booking.dart';
import '../core/demo_data.dart';
import '../core/loop_prompt.dart';
import '../core/session.dart';
import '../theme/motion.dart';
import '../ui/screens/consumer/booking_request_screen.dart';
import '../ui/screens/consumer/booking_status_screen.dart';
import '../ui/screens/consumer/category_browse_screen.dart';
import '../ui/screens/consumer/home_screen.dart';
import '../ui/screens/consumer/listing_detail_screen.dart';
import '../ui/screens/consumer/rate_review_screen.dart';
import '../ui/screens/entry/biometric_enrolment_screen.dart';
import '../ui/screens/entry/consent_screen.dart';
import '../ui/screens/entry/location_screen.dart';
import '../ui/screens/entry/register_screen.dart';
import '../ui/screens/entry/sign_in_screen.dart';
import '../ui/screens/entry/splash_screen.dart';
import '../ui/screens/entry/unlock_screen.dart';
import '../ui/screens/entry/verify_screen.dart';
import '../ui/screens/placeholder_screen.dart';
import '../ui/screens/provider/dashboard_screen.dart';
import '../ui/screens/provider/wallet_screen.dart';
import '../ui/screens/settings/preferences_screen.dart';
import '../ui/shell/app_shell.dart';
import 'entry_flow.dart';
import 'nav_tabs.dart';
import 'navigation.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// [initialLocation] defaults to the splash, because a cold start with no
/// account is the normal case. Tests that are about the shell rather than the
/// entry flow pass [Routes.home] instead.
GoRouter createRouter({
  String initialLocation = Routes.splash,
  Session Function()? readSession,
}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    restorationScopeId: 'app',
    // **Consent supersede, enforced.** FR-1.10 and the DPA require re-consent
    // "before anything else proceeds", and until now that was modelled and not
    // routed: `Session.canBook` returned false and nothing sent the session
    // anywhere, so a superseded user could browse indefinitely and only meet
    // the rule at the booking action.
    //
    // There is no `refreshListenable` on purpose. `Consent.current` is a
    // compile-time constant, so a version cannot be superseded mid-session —
    // it changes when a new build ships, which means a restart. Evaluating on
    // movement is therefore sufficient today, and a listenable would be
    // machinery for a case that cannot occur. **When session persistence
    // lands** this redirect is what catches a restored session carrying an old
    // version, which is the case it exists for.
    redirect: (context, state) {
      final session = readSession?.call();
      if (session == null) return null;

      // **The launch decision.** Only the welcome screen is guarded, because
      // that is the only place a launch can land: `initialLocation` is the
      // splash and nothing else navigates to it except a sign-out, which
      // leaves stage `none` and so falls through here untouched.
      //
      // It lives in the router rather than in SplashScreen.initState because a
      // screen that decides where to go is only consulted when that screen is
      // built — and the welcome screen is exactly the screen a returning
      // member must never be shown. See docs/entry-flow.md §5.2.
      if (state.matchedLocation == Routes.splash) {
        final destination = launchRoute(session);
        return destination == Routes.splash ? null : destination;
      }

      if (!session.needsReconsent) return null;
      // Not a loop: the consent screen is where we are sending them.
      if (state.matchedLocation == Routes.consent) return null;
      return Routes.consent;
    },
    routes: [
      // Entry sits outside both shells. There is no tab bar until there is an
      // account, and a flow that could be escaped by tapping a tab would not
      // be a gate.
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) =>
            _replacingPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      // Verify, consent and unlock are replaces rather than pushes: each one
      // discards what came before it, so back cannot re-enter a flow that
      // would send a second code.
      GoRoute(
        path: Routes.verify,
        pageBuilder: (context, state) =>
            _replacingPage(state, const VerifyScreen()),
      ),
      GoRoute(
        path: Routes.consent,
        pageBuilder: (context, state) =>
            _replacingPage(state, const ConsentScreen()),
      ),
      GoRoute(
        path: Routes.unlock,
        pageBuilder: (context, state) =>
            _replacingPage(state, const UnlockScreen()),
      ),
      GoRoute(
        path: Routes.biometricEnrolment,
        pageBuilder: (context, state) =>
            _replacingPage(state, const BiometricEnrolmentScreen()),
      ),
      GoRoute(
        path: Routes.location,
        pageBuilder: (context, state) =>
            _replacingPage(state, const LocationScreen()),
      ),
      _shell(AppMode.consumer, [
        _branch(
          Routes.home,
          'Home',
          children: [
            _Sub(
              Routes.category,
              'Category',
              builder: (context, state) => CategoryBrowseScreen(
                data: Demo.browse(state.pathParameters['key'] ?? ''),
              ),
            ),
            _Sub(
              Routes.listing,
              'Listing',
              builder: (context, state) {
                final listing = Demo.listingOf(
                  state.pathParameters['id'] ?? '',
                );
                // Stage 7's first placement. Decided here rather than in the
                // screen: whether to prompt is a supply-and-history question,
                // and the screen has neither.
                return ListingDetailScreen(
                  data: listing,
                  loopPrompt: Demo.loopAfter(
                    listing.category,
                    LoopMoment.rentalEnquiry,
                  ).pair,
                );
              },
            ),
            // The request form belongs to the Home tab, not to Bookings:
            // until it is sent there is no booking, and backing out has to
            // return to the listing the customer was reading.
            _Sub(
              Routes.bookingRequest,
              'Request booking',
              builder: (context, state) =>
                  BookingRequestScreen(data: Demo.bookingRequest),
            ),
          ],
          // Screens take their data as an argument, so swapping Demo for a
          // repository is a change here and nowhere else.
          builder: (context, state) => ConsumerHomeScreen(data: Demo.home),
        ),
        _branch(
          Routes.bookings,
          'Bookings',
          children: [
            _Sub(
              Routes.booking,
              'Booking',
              // `?state=` picks which of the eleven to show. Without a backend
              // there is nothing to advance the state machine, and the design's
              // own artboard exposes the same switch — a row of state tabs
              // above the phone — for exactly this reason.
              builder: (context, state) {
                final booking = BookingState.byKey(
                  state.uri.queryParameters['state'] ?? 'REQUESTED',
                );
                // Stage 7's second placement. Decided once here; the screen
                // gates it on COMPLETED itself.
                final loop = Demo.loopAfter(
                  Demo.bookingCategory,
                  LoopMoment.bookingCompleted,
                );
                return BookingStatusScreen(
                  state: booking,
                  category: Demo.bookingCategory,
                  providerName: Demo.bookingProviderName,
                  providerFirstName: Demo.bookingProviderFirstName,
                  // One of the eleven actions has somewhere to go. The rest
                  // stay inert rather than pretending: messaging has no thread
                  // UI, the dispute flow is undesigned, and cancellation has no
                  // settled rule — all three are in docs/build-order.md's
                  // blocked list.
                  onAction: booking.key == 'COMPLETED'
                      ? () => context.pushScreen(
                          Routes.bookingRateOf(
                            state.pathParameters['id'] ?? Demo.bookingId,
                          ),
                        )
                      : null,
                  loopPrompt: loop.pair,
                  onLoopPrompt: loop.shows
                      ? () => context.pushScreen(
                          Routes.categoryOf(loop.pair!.then.key),
                        )
                      : null,
                );
              },
            ),
            _Sub(
              Routes.bookingRate,
              'Rate & review',
              builder: (context, state) => RateReviewScreen(data: Demo.review),
            ),
          ],
        ),
        _branch(Routes.messages, 'Messages'),
        _branch(
          Routes.account,
          'Account',
          children: [
            _Sub(
              Routes.preferences,
              'Preferences',
              builder: (context, state) => const PreferencesScreen(),
            ),
          ],
        ),
      ]),
      _shell(AppMode.provider, [
        _branch(
          Routes.dashboard,
          'Dashboard',
          children: [
            // The wallet hangs off the dashboard rather than the tab bar.
            _Sub(
              Routes.wallet,
              'Wallet',
              builder: (context, state) => WalletScreen(data: Demo.wallet),
            ),
          ],
          builder: (context, state) =>
              ProviderDashboardScreen(data: Demo.dashboard),
        ),
        _branch(Routes.requests, 'Requests'),
        _branch(Routes.listings, 'Listings'),
        _branch(Routes.providerAccount, 'Account'),
      ]),
    ],
  );
}

StatefulShellRoute _shell(AppMode mode, List<StatefulShellBranch> branches) {
  return StatefulShellRoute.indexedStack(
    branches: branches,
    builder: (context, state, navigationShell) =>
        AppShell(navigationShell: navigationShell, tabs: NavTabs.of(mode)),
  );
}

/// One tab: its root screen, plus the screens that push onto it.
///
/// A route with no [builder] still renders a [PlaceholderScreen], so the
/// navigation graph stays complete and testable while the screens land one at
/// a time.
StatefulShellBranch _branch(
  String path,
  String title, {
  List<_Sub> children = const [],
  GoRouterWidgetBuilder? builder,
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        pageBuilder: (context, state) => _lateralPage(
          state,
          builder?.call(context, state) ??
              PlaceholderScreen(title: title, showAppBar: false),
        ),
        routes: [
          for (final child in children)
            GoRoute(
              // Nested paths are relative to the parent in go_router.
              path: child.path.substring(path.length + 1),
              builder: (context, state) =>
                  child.builder?.call(context, state) ??
                  PlaceholderScreen(title: child.title),
            ),
        ],
      ),
    ],
  );
}

/// A tab root is reached laterally, so it fades rather than travelling. Only a
/// push moves in from the edge.
Page<void> _lateralPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    // 120 ms, both ways. The canvas is explicit: "cross-fade only, no slide —
    // tabs are siblings, not a journey". A tab change that takes as long as a
    // push reads as travel.
    transitionDuration: Motion.tabChange,
    reverseTransitionDuration: Motion.tabChange,
    child: child,
    transitionsBuilder: PageMotion.lateral,
  );
}

/// A step that discards the one before it: OTP, consent, unlock, location. It
/// rises and fades rather than sliding in from the edge, because sliding reads
/// as something you can back out of and these cannot be backed out of.
Page<void> _replacingPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: Motion.page,
    reverseTransitionDuration: Motion.exit,
    child: child,
    transitionsBuilder: PageMotion.replace,
  );
}

@immutable
class _Sub {
  const _Sub(this.path, this.title, {this.builder});
  final String path;
  final String title;

  /// Null until the real screen exists — see [_branch].
  final GoRouterWidgetBuilder? builder;
}
