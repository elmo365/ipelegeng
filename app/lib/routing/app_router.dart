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

import '../theme/motion.dart';
import '../ui/screens/placeholder_screen.dart';
import '../ui/shell/app_shell.dart';
import 'nav_tabs.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createRouter({String initialLocation = Routes.home}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    restorationScopeId: 'app',
    routes: [
      _shell(AppMode.consumer, [
        _branch(Routes.home, 'Home', const [
          _Sub(Routes.category, 'Category'),
          _Sub(Routes.listing, 'Listing'),
        ]),
        _branch(Routes.bookings, 'Bookings', const [
          _Sub(Routes.booking, 'Booking'),
        ]),
        _branch(Routes.messages, 'Messages'),
        _branch(Routes.account, 'Account'),
      ]),
      _shell(AppMode.provider, [
        _branch(
          Routes.dashboard,
          'Dashboard',
          const [
            // The wallet hangs off the dashboard rather than the tab bar.
            _Sub(Routes.wallet, 'Wallet'),
          ],
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
StatefulShellBranch _branch(
  String path,
  String title, [
  List<_Sub> children = const [],
]) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        pageBuilder: (context, state) => _lateralPage(
          state,
          PlaceholderScreen(title: title, showAppBar: false),
        ),
        routes: [
          for (final child in children)
            GoRoute(
              // Nested paths are relative to the parent in go_router.
              path: child.path.substring(path.length + 1),
              builder: (context, state) => PlaceholderScreen(title: child.title),
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
    transitionDuration: Motion.enter,
    reverseTransitionDuration: Motion.exit,
    child: child,
    transitionsBuilder: PageMotion.lateral,
  );
}

@immutable
class _Sub {
  const _Sub(this.path, this.title);
  final String path;
  final String title;
}
