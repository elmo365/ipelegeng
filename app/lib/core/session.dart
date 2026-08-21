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
/// **This does persist, as of 2026-08-21** — "OTP on every fresh login; the
/// session then persists until explicit logout". What is kept, what is dropped,
/// and what a reopen restores *to* all live in session_store.dart, because they
/// are storage decisions rather than properties of the model. The one that
/// matters: a reopen never lands on [SessionStage.active].
library;

import 'package:characters/characters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_store.dart';

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
/// What happened when a code was asked for.
enum OtpSendOutcome {
  sent,

  /// The platform rejected the number itself. Distinct from *not delivered*:
  /// there is something to fix on this screen.
  invalidNumber,

  /// Rate-limited — by us, by the platform, or by the network.
  tooManyRequests,

  /// No sender reachable. Offline, misconfigured, or quota exhausted.
  unavailable,
}

/// The seam between the app and whatever actually sends a code.
///
/// Both halves are async because a real one is: sending crosses a network and
/// confirming may too. [DemoOtpVerifier] keeps the whole entry flow testable
/// without either.
abstract interface class OtpVerifier {
  /// Ask for a code to be sent to [phone].
  ///
  /// [onAutoVerified] fires only where the **platform reads the SMS itself**.
  /// On Android that is real — Firebase's auto-retrieval completes without the
  /// user typing anything, which is why the verify screen must be able to move
  /// on without a tap. On iOS nothing calls this: the code is offered to the
  /// field by `AutofillHints.oneTimeCode` and the user still taps.
  Future<OtpSendOutcome> send(String phone, {void Function()? onAutoVerified});

  /// Whether a typed code is the one that was sent.
  Future<bool> isCorrect(String code);
}

/// The default, and the only one until a sender is configured: **sends
/// nothing** and accepts any complete code.
///
/// This is deliberately permissive, which is the safe direction for a fake —
/// no test can pass *because* the fake rejected something the real sender
/// would allow. See docs/test-strategy.md, "What a green suite does not mean".
class DemoOtpVerifier implements OtpVerifier {
  const DemoOtpVerifier();

  @override
  Future<OtpSendOutcome> send(
    String phone, {
    void Function()? onAutoVerified,
  }) async => OtpSendOutcome.sent;

  @override
  Future<bool> isCorrect(String code) async =>
      code.length == Session.codeLength;
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
  /// How many digits a code has. **The single source of truth** — the verify
  /// screen draws this many boxes rather than carrying its own number, which
  /// it did until 2026-08-21 and which is exactly how two constants drift.
  ///
  /// **Six, not the artboard's four.** Firebase Auth sends a six-digit code
  /// and the length is not configurable, so this is not a preference the
  /// design gets to hold: a four-box screen cannot accept the code that
  /// arrives. Recorded in docs/design-deltas.md §21 and raised with the design
  /// in design/CORRECTIONS.md — the artboard draws four boxes and needs to
  /// draw six.
  static const codeLength = 6;

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

  /// Signed in, on a consent version that has since been superseded.
  ///
  /// FR-1.10 and the DPA require re-consent "before anything else proceeds",
  /// which is stronger than [canBook] returning false — that only stops a
  /// booking, and the design wants the session routed. The router reads this
  /// and redirects; see `createRouter`.
  ///
  /// **Deliberately excludes [SessionStage.locked].** A locked session has to
  /// get through unlock first: sending it to a consent form it cannot dismiss
  /// would trap someone behind two gates at once. Unlocking makes it
  /// [SessionStage.active], and the redirect fires on the next movement.
  ///
  /// **And excludes [SessionStage.none].** A visitor has agreed to nothing and
  /// needs to have agreed to nothing — browsing is free under UC-4, and
  /// bouncing a stranger into a consent form is exactly the wall the design
  /// moved to the booking action.
  bool get needsReconsent =>
      stage == SessionStage.active && consentVersion != Consent.current;

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
  Session build() {
    final stored = ref.read(sessionStoreProvider).read();
    // Never straight back to `active` — see SessionCodec.reopened. A restored
    // session that is immediately signed in makes a stolen handset a signed-in
    // handset.
    return stored == null ? const Session() : SessionCodec.reopened(stored);
  }

  /// The single write point.
  ///
  /// Every mutation below goes through here rather than assigning `state`
  /// directly, so persistence cannot be forgotten when the next one is added.
  /// [signOut] is the one exception, and it clears rather than writes.
  void _set(Session next) {
    state = next;
    ref.read(sessionStoreProvider).write(next);
  }

  /// Put back a session that was read from storage.
  ///
  /// This is the seam session persistence lands in, not a hook that exists for
  /// tests — the same reasoning [OtpVerifier] carries. It is also the **only**
  /// way to produce a session that is [SessionStage.active] on a superseded
  /// consent version, because the state machine above cannot reach one:
  /// [confirmCode] sends a stale version to [SessionStage.needsConsent] and
  /// [agree] always writes [Consent.current].
  ///
  /// That is exactly why the consent-supersede redirect exists. A version is
  /// superseded by shipping a new build, so the case appears when yesterday's
  /// session is restored against today's constant — through here.
  void restore(Session session) => _set(session);

  /// Register or sign in: both end at the same place, because both send a code.
  ///
  /// Resets the attempt count — a new number is a new round, and carrying a
  /// lockout across it would punish the wrong thing.
  void requestCode({String? name, required String phone}) {
    _set(
      state.copyWith(
        stage: SessionStage.confirmingNumber,
        name: name ?? state.name,
        phone: phone,
        codeAttemptsLeft: Session.maxCodeAttempts,
      ),
    );
  }

  /// Submit a code. The three OTP outcomes the design names, in one place.
  ///
  /// A resend does **not** restore attempts: the limit is on guessing, and
  /// letting a resend reset it would make it decorative.
  Future<OtpOutcome> submitCode(String code, OtpVerifier verifier) async {
    if (state.codeLocked) return OtpOutcome.locked;

    if (await verifier.isCorrect(code)) {
      confirmCode();
      return OtpOutcome.accepted;
    }

    final left = state.codeAttemptsLeft - 1;
    _set(state.copyWith(codeAttemptsLeft: left < 0 ? 0 : left));
    return left <= 0 ? OtpOutcome.locked : OtpOutcome.wrongCode;
  }

  /// The code was accepted. Where this lands depends on consent, not on which
  /// screen asked — a returning user on a current version goes straight in.
  void confirmCode() {
    _set(
      state.copyWith(
        stage: state.consentVersion == Consent.current
            ? SessionStage.active
            : SessionStage.needsConsent,
      ),
    );
  }

  void agree({Set<ConsentChannel> channels = const <ConsentChannel>{}}) {
    _set(
      state.copyWith(
        stage: SessionStage.active,
        consentVersion: Consent.current,
        channels: channels,
      ),
    );
  }

  void setLocationGranted(bool granted) =>
      _set(state.copyWith(locationGranted: granted));

  /// The enrolment offer, answered. Recorded as *offered* either way, because
  /// the design offers it once after the first OTP and never asks again —
  /// declining without penalty means the offer is spent, not deferred.
  void answerBiometricOffer({required bool enrol}) {
    _set(state.copyWith(biometricOffered: true, biometricUnlock: enrol));
  }

  /// Turned on or off later, from Security. Off means an OTP on every open,
  /// which is what that screen says in those words.
  void setBiometricUnlock(bool on) => _set(state.copyWith(biometricUnlock: on));

  /// The app was reopened. Only a session that was active can lock — a visitor
  /// has nothing to unlock.
  void lock() {
    if (state.stage != SessionStage.active) return;
    _set(state.copyWith(stage: SessionStage.locked));
  }

  /// Biometry or the device passcode. Both reopen the same session; neither
  /// proves identity, which is why there is one method and not two.
  void unlock() {
    if (state.stage != SessionStage.locked) return;
    _set(state.copyWith(stage: SessionStage.active));
  }

  /// "Sign in as someone else", and explicit sign-out. The device keeps
  /// nothing, so the next entry is a full phone + OTP.
  void signOut() {
    state = const Session();
    ref.read(sessionStoreProvider).clear();
  }
}
