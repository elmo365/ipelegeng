/// The sensor, behind a seam.
///
/// **Biometry unlocks; it never authenticates.** That rule is enforced in
/// `session.dart` — [SessionController.unlock] takes no argument saying which
/// method was used, and it only moves a session that was already
/// [SessionStage.locked]. Nothing in this file can sign anyone in; the most it
/// can do is say the person holding the phone is the person who locked it.
///
/// ## Why the fallback is not a fallback
///
/// "Passcode is a full card of equal weight, not fine print, because broken or
/// absent sensors are common on the target hardware." So this exposes the two
/// as **two intents on one API**, not as a happy path with a rescue:
/// [BiometricPrompt.biometric] asks for a fingerprint or a face,
/// [BiometricPrompt.deviceCredential] accepts the device PIN, pattern or
/// password. The unlock screen offers both at once and neither is a
/// consolation.
///
/// ## The states the design names
///
/// The journey map lists *"biometry unavailable or refused → passcode"* among
/// the entry states. [Biometrics.availability] is what lets the unlock screen
/// answer that before the user taps anything, so a handset with no sensor is
/// not offered a fingerprint button that can only fail.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Which of the two the caller is asking for.
enum BiometricPrompt {
  /// A fingerprint or a face. Nothing else is accepted.
  biometric,

  /// The device PIN, pattern or password. Equal standing, not a rescue.
  deviceCredential,
}

/// What this handset can actually do.
enum BiometricAvailability {
  /// A sensor exists and has something enrolled on it.
  ready,

  /// Hardware exists but nothing is enrolled, or the OS has locked it out
  /// after too many attempts. The passcode still works.
  unavailable,

  /// No sensor. Common on the target hardware, which is the whole reason the
  /// passcode card carries equal weight.
  unsupported,
}

/// What happened.
enum BiometricOutcome {
  ok,

  /// Cancelled, or the wrong finger enough times. Not an error to report —
  /// the person may simply have changed their mind.
  refused,

  /// Nothing to prompt with. The caller should offer the passcode instead.
  unavailable,
}

/// The seam. [PlatformBiometrics] is what ships; [AlwaysAllowBiometrics] is the
/// default so a widget test does not need a platform channel — the same shape
/// [OtpVerifier] uses, and for the same reason.
abstract interface class Biometrics {
  Future<BiometricAvailability> availability();

  Future<BiometricOutcome> authenticate({
    required BiometricPrompt prompt,
    required String reason,
  });
}

/// The default, and test-only in practice: says yes to everything.
///
/// It is not a lie about security — nothing in this app grants access on the
/// strength of a biometric result alone. It grants a *reopen* of a session the
/// device already held.
class AlwaysAllowBiometrics implements Biometrics {
  const AlwaysAllowBiometrics();

  @override
  Future<BiometricAvailability> availability() async =>
      BiometricAvailability.ready;

  @override
  Future<BiometricOutcome> authenticate({
    required BiometricPrompt prompt,
    required String reason,
  }) async => BiometricOutcome.ok;
}

class PlatformBiometrics implements Biometrics {
  PlatformBiometrics([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricAvailability> availability() async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return BiometricAvailability.unsupported;
      }
      // `canCheckBiometrics` is hardware; an empty enrolled list is a sensor
      // with no finger registered on it. Both end at the passcode, but only
      // the first means "never offer this".
      if (!await _auth.canCheckBiometrics) {
        return BiometricAvailability.unsupported;
      }
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricAvailability.unavailable
          : BiometricAvailability.ready;
    } on LocalAuthException {
      // A handset that cannot answer the question is a handset that gets the
      // passcode. Failing closed here costs one extra tap; failing open would
      // put a dead button on the screen.
      return BiometricAvailability.unsupported;
    }
  }

  @override
  Future<BiometricOutcome> authenticate({
    required BiometricPrompt prompt,
    required String reason,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        // `false` would let the OS silently substitute the device PIN for a
        // fingerprint, which would make the two buttons on the unlock screen
        // the same button. The design draws them as distinct choices.
        biometricOnly: prompt == BiometricPrompt.biometric,
        // The prompt survives the app going to the background — otherwise an
        // incoming SMS carrying a code cancels the unlock behind it.
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricOutcome.ok : BiometricOutcome.refused;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        // Nothing to prompt with. The caller offers the passcode instead.
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          BiometricOutcome.unavailable,
        // Lockouts are refusals, not faults: the passcode is on the same
        // screen and still works, which is the point of drawing it there.
        _ => BiometricOutcome.refused,
      };
    }
  }
}

final biometricsProvider = Provider<Biometrics>(
  (ref) => const AlwaysAllowBiometrics(),
);
