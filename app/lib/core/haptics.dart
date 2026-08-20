/// The three haptics, and only three.
///
/// "A phone that buzzes at everything gets muted" — and then the three that
/// mattered are gone too. The design names exactly three uses and this class
/// exists so a fourth cannot be added casually: there is no general-purpose
/// `buzz()` here, only the three moments, named after what they mean rather
/// than after how strong they are.
///
/// See docs/design-system.md#haptics.
library;

import 'package:flutter/services.dart';

abstract final class Haptics {
  /// Accepting or declining a request; confirming a booking is done.
  static Future<void> decision() => HapticFeedback.lightImpact();

  /// An incoming ride request, alongside the ringtone. The only heavy one,
  /// because it is the only thing that interrupts.
  static Future<void> incomingRide() => HapticFeedback.heavyImpact();

  /// A wrong OTP or a failed top-up — **paired with the message**, never on
  /// its own. A buzz with nothing on screen to explain it is noise.
  static Future<void> error() => HapticFeedback.vibrate();
}
