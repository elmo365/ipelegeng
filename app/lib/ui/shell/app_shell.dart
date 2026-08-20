/// One shell, two tab sets.
///
/// The bar takes its colours, type and indicator from `navigationBarTheme`.
/// What this widget owns is the **sheet the bar sits on**: the restyle
/// replaced a hairline strip with a raised sheet carrying a 26 px top radius
/// and a shadow that casts *upward*, and Material's `NavigationBar` has no
/// way to express either — so the surface is drawn here and the bar is laid
/// on top of it.
///
/// See docs/design-system.md#surface-treatment.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/nav_tabs.dart';
import '../../theme/dimens.dart';
import '../../theme/tokens.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.tabs,
  });

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
    final palette = context.palette;

    return Scaffold(
      // The sheet floats above the page rather than sitting flush on it, so
      // the tinted page reads underneath its corners.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.navBg,
          borderRadius: Radii.sheetTop,
          boxShadow: palette.shadowNav,
        ),
        child: ClipRRect(
          borderRadius: Radii.sheetTop,
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            // The sheet supplies the colour; the bar must not paint over its
            // own rounded corners with a square background.
            backgroundColor: Colors.transparent,
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
        ),
      ),
    );
  }
}
