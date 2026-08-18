/// One shell, two tab sets.
///
/// The bar takes its colours, type and indicator from `navigationBarTheme`,
/// so this widget carries layout and stack behaviour only — nothing visual.
///
/// See docs/design-system.md#two-tab-sets-one-login.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/nav_tabs.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell, required this.tabs});

  /// Holds one [Navigator] per tab, so each tab keeps its own stack across
  /// switches — the state-restoration requirement starts here.
  final StatefulNavigationShell navigationShell;
  final List<NavTab> tabs;

  /// Changing tab is **lateral**: it replaces content in place and adds
  /// nothing to the stack. Tapping the tab you are already on returns that
  /// tab to its root, which is the one case where a tab tap pops.
  void _onTap(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
              tooltip: tab.label,
            ),
        ],
      ),
    );
  }
}
