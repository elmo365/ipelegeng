/// The three movements, made distinct in code.
///
/// Push, lateral and replace look alike on screen and must not be built
/// alike. Calling `context.go` or `context.push` directly at a screen is how
/// they get confused; these three names make the intent explicit and put the
/// stack rule in one place.
///
/// See docs/design-system.md#sideways-is-not-forward.
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'nav_tabs.dart';

extension AppNavigation on BuildContext {
  /// **Push** — a listing, a booking, a form step. Adds to the stack; back
  /// pops it. The only movement that deepens history.
  Future<T?> pushScreen<T>(String path, {Object? extra}) =>
      GoRouter.of(this).push<T>(path, extra: extra);

  /// **Lateral** — changing category or filter within a tab. Replaces content
  /// in place and adds nothing to the stack, so back returns to where the tab
  /// started rather than walking every filter the user tried.
  void goLateral(String path, {Object? extra}) =>
      GoRouter.of(this).replace(path, extra: extra);

  /// **Replace** — booking created, listing published, mode switched, OTP
  /// verified. The flow behind it is discarded, so back cannot re-enter it and
  /// post a second deduction.
  void goReplacing(String path, {Object? extra}) =>
      GoRouter.of(this).go(path, extra: extra);

  /// Switching mode is a replace by definition: the other side's stack is
  /// dropped, not suspended.
  void switchMode(AppMode to) => goReplacing(to.entryPath);
}
