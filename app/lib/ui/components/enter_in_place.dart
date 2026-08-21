/// Anything entering in place.
///
/// The design states one rule for this and it is a rule about restraint:
/// something arriving where it already belongs **rises [Motion.travel] and
/// fades**, over [Motion.enter], and nothing else. Only a sheet goes further,
/// because a sheet comes from off-screen and this does not. Nothing here
/// pulses and nothing loops.
///
/// It animates on the frame it is mounted, which is what makes it correct and
/// also what makes it easy to get wrong: mounted unconditionally, it replays
/// on every rebuild that changes its key, and motion that fires when nothing
/// happened is decoration. Two guards:
///
/// - [enabled] false renders the child in its final position with no
///   animation. A screen opened *at* a state should be correct, not replay
///   the transition that would have reached it.
/// - the `key` should identify **the arrival**, not the widget — see
///   `booking_status_screen.dart`, where it carries the booking state, so the
///   provider row rises when the booking is accepted and stays put while it
///   is in progress.
///
/// Reduce-motion collapses it to nothing through [Motion.of] rather than
/// shortening it: on these handsets that is a battery decision.
///
/// See docs/design-system.md#motion.
library;

import 'package:flutter/material.dart';

import '../../theme/motion.dart';

class EnterInPlace extends StatelessWidget {
  const EnterInPlace({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// False renders [child] outright. See the library doc: the first build of
  /// a screen passes false.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.enter),
      curve: Motion.curve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, Motion.travel * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
