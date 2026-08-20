/// Who is signed in, and how far through the entry flow they are.
///
/// The design's rules, which this type exists to make structural rather than
/// remembered:
///
/// - **Every fresh login goes through OTP.** There is no password to skip it
///   with, so there is no state that reaches [SessionStage.active] without
///   passing through [SessionStage.confirmingNumber].
/// - **Biometry unlocks, it never authenticates.** [SessionStage.locked] is
///   only reachable from an account that has already been verified on this
///   device; a new device or a reinstall starts at [SessionStage.none].
/// - **Consent is versioned.** [consentVersion] records what was agreed to. A
///   session whose version is behind [Consent.current] is not usable, which is
///   what makes re-consent a state rather than a prompt someone remembers to
///   show.
/// - **A visitor is a real state.** Browsing is free (UC-4), so
///   [SessionStage.none] must reach home, browse and listing detail. The wall
///   is at the booking action.
///
/// Nothing here persists yet — that lands with the settings store and the
/// Django session. Until then a restart is a new device, which is the safe
/// direction to be wrong in.
library;

import 'package:characters/characters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The consent documents and the version in force.
///
/// Versioned because FR-1.10 and the DPA make a superseded version force
/// re-consent before anything else proceeds. Bumping this constant is what
/// triggers that, so it is the only place the version is written.
abstract final class Consent {
  static const current = '2.1';
  static const termsLabel = 'Terms v$current';
  static const privacyLabel = 'Privacy v$current';
}

/// Optional channels, each recorded separately — the design is explicit that
/// they are not one "marketing" switch.
enum ConsentChannel {
  sms('Booking updates by SMS'),
  whatsApp('Booking updates on WhatsApp');

  const ConsentChannel(this.label);
  final String label;
}

/// What happened when a code was submitted.
///
/// The design names these among the OTP states: *code sent · wrong code ·
/// resend cooling down · locked after N attempts*. Only the first two are drawn
/// on the artboard; the rest are named in the journey map and have to be built
/// from the rule rather than from a mockup.
enum OtpOutcome { accepted, wrongCode, locked }

/// Checks a code. Until the Django backend exists there is nothing to check
/// against, so [DemoOtpVerifier] accepts any complete code — but the wrong-code
/// and locked paths are real, and this is the seam the API call lands in rather
/// than a hook that exists only for tests.
abstract interface class OtpVerifier {
  bool isCorrect(String code);
}

class DemoOtpVerifier implements OtpVerifier {
  const DemoOtpVerifier();

  @override
  bool isCorrect(String code) => code.length == Session.codeLength;
}

final otpVerifierProvider = Provider<OtpVerifier>(
  (ref) => const DemoOtpVerifier(),
);

enum SessionStage {
  /// No account on this device. Browsing is allowed; booking is not.
  none,

  /// A number has been given and a code sent. Nothing is signed in yet.
  confirmingNumber,

  /// Verified, but on a consent version older than [Consent.current], or
  /// never having agreed at all.
  needsConsent,

  /// Signed in, consent current. The only state that can book.
  active,

  /// Signed in, but the app has been closed and reopened. Biometry or the
  /// device passcode reopens it; it never re-authenticates.
  locked,
}

class Session {
  /// Four boxes on the artboard.
  static const codeLength = 4;

  /// The N in "locked after N attempts". The design names the state but not
  /// the number, so this is the repo's, recorded in design-deltas.md as an
  /// assumption rather than presented as the design's.
  static const maxCodeAttempts = 5;

  const Session({
    this.stage = SessionStage.none,
    this.name,
    this.phone,
    this.consentVersion,
    this.channels = const <ConsentChannel>{},
    this.locationGranted = false,
    this.biometricOffered = false,
    this.biometricUnlock = false,
    this.codeAttemptsLeft = maxCodeAttempts,
  });

  final SessionStage stage;

  /// Shown on sign in and on the unlock screen so the person knows which
  /// account they are entering. Null before an account exists.
  final String? name;
  final String? phone;

  /// What was agreed to, not whether. Null means never.
  final String? consentVersion;
  final Set<ConsentChannel> channels;

  /// Answered separately from consent, and it is allowed to be refused —
  /// picking an area from a list is a first-class path, not a degraded one.
  final bool locationGranted;

  /// Whether the enrolment offer has been made. The design offers it **once**,
  /// after the first OTP, and a declined offer is never re-asked — so this is
  /// remembered separately from the answer.
  final bool biometricOffered;

  /// The answer. Off means an OTP every time the app is opened, which is what
  /// the Security screen tells the user in those words.
  final bool biometricUnlock;

  /// Counts down on a wrong code. At zero the code entry is locked and the only
  /// way on is a fresh number — a resend would send a code into a form that
  /// cannot accept it.
  final int codeAttemptsLeft;

  /// Locked out of code entry. Not a [SessionStage] because it is a property of
  /// this verification round, not of the account: starting again from sign in
  /// clears it.
  bool get codeLocked =>
      stage == SessionStage.confirmingNumber && codeAttemptsLeft <= 0;

  /// The one question the rest of the app asks. Deliberately not
  /// `stage != none`: a signed-in session on a superseded consent version
  /// cannot act either.
  bool get canBook =>
      stage == SessionStage.active && consentVersion == Consent.current;

  /// First initials, for the sign-in avatar. "Kabo Mothibi" → "KM".
  String get initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  Session copyWith({
    SessionStage? stage,
    String? name,
    String? phone,
    String? consentVersion,
    Set<ConsentChannel>? channels,
    bool? locationGranted,
    bool? biometricOffered,
    bool? biometricUnlock,
    int? codeAttemptsLeft,
  }) {
    return Session(
      stage: stage ?? this.stage,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      consentVersion: consentVersion ?? this.consentVersion,
      channels: channels ?? this.channels,
      locationGranted: locationGranted ?? this.locationGranted,
      biometricOffered: biometricOffered ?? this.biometricOffered,
      biometricUnlock: biometricUnlock ?? this.biometricUnlock,
      codeAttemptsLeft: codeAttemptsLeft ?? this.codeAttemptsLeft,
    );
  }
}

final sessionProvider = NotifierProvider<SessionController, Session>(
  SessionController.new,
);

class SessionController extends Notifier<Session> {
  @override
  Session build() => const Session();

  /// Register or sign in: both end at the same place, because both send a code.
  ///
  /// Resets the attempt count — a new number is a new round, and carrying a
  /// lockout across it would punish the wrong thing.
  void requestCode({String? name, required String phone}) {
    state = state.copyWith(
      stage: SessionStage.confirmingNumber,
      name: name ?? state.name,
      phone: phone,
      codeAttemptsLeft: Session.maxCodeAttempts,
    );
  }

  /// Submit a code. The three OTP outcomes the design names, in one place.
  ///
  /// A resend does **not** restore attempts: the limit is on guessing, and
  /// letting a resend reset it would make it decorative.
  OtpOutcome submitCode(String code, OtpVerifier verifier) {
    if (state.codeLocked) return OtpOutcome.locked;

    if (verifier.isCorrect(code)) {
      confirmCode();
      return OtpOutcome.accepted;
    }

    final left = state.codeAttemptsLeft - 1;
    state = state.copyWith(codeAttemptsLeft: left < 0 ? 0 : left);
    return left <= 0 ? OtpOutcome.locked : OtpOutcome.wrongCode;
  }

  /// The code was accepted. Where this lands depends on consent, not on which
  /// screen asked — a returning user on a current version goes straight in.
  void confirmCode() {
    state = state.copyWith(
      stage: state.consentVersion == Consent.current
          ? SessionStage.active
          : SessionStage.needsConsent,
    );
  }

  void agree({Set<ConsentChannel> channels = const <ConsentChannel>{}}) {
    state = state.copyWith(
      stage: SessionStage.active,
      consentVersion: Consent.current,
      channels: channels,
    );
  }

  void setLocationGranted(bool granted) =>
      state = state.copyWith(locationGranted: granted);

  /// The enrolment offer, answered. Recorded as *offered* either way, because
  /// the design offers it once after the first OTP and never asks again —
  /// declining without penalty means the offer is spent, not deferred.
  void answerBiometricOffer({required bool enrol}) {
    state = state.copyWith(biometricOffered: true, biometricUnlock: enrol);
  }

  /// Turned on or off later, from Security. Off means an OTP on every open,
  /// which is what that screen says in those words.
  void setBiometricUnlock(bool on) =>
      state = state.copyWith(biometricUnlock: on);

  /// The app was reopened. Only a session that was active can lock — a visitor
  /// has nothing to unlock.
  void lock() {
    if (state.stage != SessionStage.active) return;
    state = state.copyWith(stage: SessionStage.locked);
  }

  /// Biometry or the device passcode. Both reopen the same session; neither
  /// proves identity, which is why there is one method and not two.
  void unlock() {
    if (state.stage != SessionStage.locked) return;
    state = state.copyWith(stage: SessionStage.active);
  }

  /// "Sign in as someone else", and explicit sign-out. The device keeps
  /// nothing, so the next entry is a full phone + OTP.
  void signOut() => state = const Session();
}
