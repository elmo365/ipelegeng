/// Motion tokens.
///
/// Seven durations and two curves. Motion explains a change; it never
/// decorates one. Anything entering in place travels 12 dp at most — only
/// sheets go further — and **nothing loops**: a shimmer or a pulse holds the
/// GPU awake and drains a battery that is the user's lifeline.
///
/// See docs/design-system.md#motion for the rules and the per-state table.
library;

import 'package:flutter/material.dart';

abstract final class Motion {
  static const tap = Duration(milliseconds: 120);

  /// A tab change. **Cross-fade only, no slide** — "tabs are siblings, not a
  /// journey". Corrected from 220 ms on 2026-08-20: the whole transition table
  /// in part 4 of the canvas had been implemented from memory rather than read,
  /// and a tab that takes as long as a push reads as travel.
  static const tabChange = Duration(milliseconds: 120);

  /// Anything entering in place.
  static const enter = Duration(milliseconds: 220);
  static const exit = Duration(milliseconds: 160);

  /// Push to a detail screen: ease-out, slide in from the right, with
  /// [pushParallax] on the outgoing screen.
  static const page = Duration(milliseconds: 220);

  /// A bottom sheet is the one transition with different durations each way —
  /// ease-out on entry, ease-in on dismissal.
  static const sheet = Duration(milliseconds: 260);
  static const sheetOut = Duration(milliseconds: 180);

  /// A booking state change. The chip colour and the step bar animate together
  /// so the change reads as one event.
  static const stateChange = Duration(milliseconds: 300);

  /// The wallet balance counting to a new figure. "Money changing deserves to
  /// be noticed." Corrected from 600 ms.
  static const count = Duration(milliseconds: 400);

  static const none = Duration.zero;

  static const curve = Curves.easeOutCubic;
  static const curveOut = Curves.easeInCubic;

  /// The distance anything entering in place is allowed to travel.
  static const travel = 12.0;

  /// How far the outgoing screen drifts under an incoming push.
  static const pushParallax = 16.0;

  /// Every duration goes through here. No exceptions.
  ///
  /// Reduce-motion is a battery decision on these handsets, not an
  /// accessibility edge case, so it collapses the animation to zero rather
  /// than shortening it.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.of(context).disableAnimations ? none : d;

  /// True when the platform has asked for no animation.
  static bool disabled(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}

/// Page transitions.
///
/// The three movements in docs/design-system.md#sideways-is-not-forward look
/// alike on screen and must not be built alike. Routing enforces the stack
/// behaviour; these give each one its matching motion.
abstract final class PageMotion {
  /// Push — deepens history. Slides in from the trailing edge.
  /// Push — deepens history. Slides in from the trailing edge, and drifts the
  /// outgoing screen [Motion.pushParallax] the other way so the two planes read
  /// as depth rather than as a swap.
  ///
  /// The parallax is in dp rather than a fraction, because the canvas states it
  /// as "16px parallax on the outgoing screen" and a fraction would scale it
  /// with the display.
  static Widget push(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (Motion.disabled(context)) return child;

    final incoming = SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Motion.curve)).animate(animation),
      child: child,
    );

    // `secondary` runs when this page is the one being covered.
    return AnimatedBuilder(
      animation: secondary,
      builder: (context, inner) => Transform.translate(
        offset: Offset(
          -Motion.pushParallax * Motion.curve.transform(secondary.value),
          0,
        ),
        child: inner,
      ),
      child: incoming,
    );
  }

  /// Lateral — changing tab, category or filter. Content swaps in place and
  /// nothing travels, because nothing got deeper.
  static Widget lateral(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (Motion.disabled(context)) return child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Motion.curve),
      child: child,
    );
  }

  /// Replace — the flow behind it is discarded, so back cannot re-enter it.
  /// Rises [Motion.travel] and fades; it never slides in from the edge, which
  /// would read as something you can back out of.
  static Widget replace(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (Motion.disabled(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: Motion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
