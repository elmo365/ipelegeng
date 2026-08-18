/// The two tab sets, as data.
///
/// One shell widget renders whichever set it is given, so the bars cannot
/// drift apart in styling. Switching mode **replaces** the bar rather than
/// adding to it — a provider deep in a listing does not carry that history
/// into the consumer side.
///
/// See docs/design-system.md#two-tab-sets-one-login.
library;

import 'package:flutter/material.dart';

import 'routes.dart';

@immutable
class NavTab {
  const NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// The tab's root. Its branch keeps its own stack above this.
  final String path;
}

/// Which side of the app the user is currently on.
enum AppMode {
  consumer,
  provider;

  /// Where a mode switch lands. It is a replace, not a push: the flow behind
  /// it is discarded so back cannot re-enter the other mode's stack.
  String get entryPath =>
      this == AppMode.consumer ? Routes.home : Routes.dashboard;

  AppMode get other =>
      this == AppMode.consumer ? AppMode.provider : AppMode.consumer;
}

abstract final class NavTabs {
  static const consumer = <NavTab>[
    NavTab(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      path: Routes.home,
    ),
    NavTab(
      label: 'Bookings',
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
      path: Routes.bookings,
    ),
    NavTab(
      label: 'Messages',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      path: Routes.messages,
    ),
    NavTab(
      label: 'Account',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      path: Routes.account,
    ),
  ];

  static const provider = <NavTab>[
    NavTab(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      path: Routes.dashboard,
    ),
    NavTab(
      label: 'Requests',
      icon: Icons.inbox_outlined,
      selectedIcon: Icons.inbox,
      path: Routes.requests,
    ),
    NavTab(
      label: 'Listings',
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
      path: Routes.listings,
    ),
    NavTab(
      label: 'Account',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      path: Routes.providerAccount,
    ),
  ];

  static List<NavTab> of(AppMode mode) =>
      mode == AppMode.consumer ? consumer : provider;
}
