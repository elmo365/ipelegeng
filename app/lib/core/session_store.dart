/// Where the session lives between launches.
///
/// The design's rule, from the entry flow: **"OTP on every fresh login; the
/// session then persists until explicit logout."** Until this file existed the
/// second half was not true — every restart was a fresh install, which
/// `session.dart` recorded as "the safe direction to be wrong in" rather than
/// as correct.
///
/// ## What is kept, and what is deliberately dropped
///
/// The design's own restoration list (design-system.md, *What survives being
/// killed*) puts **"any OTP already sent"** under *Not kept*. So a session
/// caught mid-verification is not restored mid-verification: [codeAttemptsLeft]
/// belongs to one round of guessing, not to the account, and a
/// [SessionStage.confirmingNumber] session is dropped entirely rather than
/// resumed into a form whose code has expired.
///
/// ## What a reopen restores *to*
///
/// Never to [SessionStage.active]. The design names two different reopens and
/// they land in different places:
///
/// - **Biometric unlock on** → [SessionStage.locked]. "Signed in, but the app
///   has been closed and reopened. Biometry or the device passcode reopens it;
///   it never re-authenticates."
/// - **Biometric unlock off** → back through the code. The Security screen says
///   this in those words: off means "an OTP every time the app is opened". The
///   number is remembered so it does not have to be typed again, but the code
///   is not skipped.
///
/// Both directions require an action to get in. That is the point: restoring
/// straight to `active` would make a stolen handset a signed-in handset, and it
/// is the one way this file could be wrong that matters.
///
/// ## Why not encrypted storage
///
/// What is held here is a name, a phone number, a consent version and four
/// booleans — the same fields the account screen shows on demand. It lives in
/// app-private storage. **No KYC document, no ledger figure and no token is
/// written here**, and when a token exists it does not belong in this store:
/// see docs/compliance.md before adding one.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session.dart';

/// The seam. [PrefsSessionStore] is what ships; the default is in-memory so a
/// widget test does not need a platform channel to construct a router.
///
/// **Both implementations apply [SessionCodec.isWorthKeeping] in [write].**
/// That is not a detail either one may skip: the in-memory store is what every
/// test runs against, so a store that keeps more than the shipping one would
/// have tests passing against behaviour the app does not have. It was written
/// that way first and a test caught it.
abstract base class SessionStore {
  /// Null when there is nothing stored, or when what is stored cannot be read.
  Session? read();

  /// Drops anything not worth keeping, then defers to [store].
  void write(Session session) {
    if (!SessionCodec.isWorthKeeping(session)) {
      clear();
      return;
    }
    store(session);
  }

  /// Write a session that has already passed the keep test.
  void store(Session session);

  void clear();
}

/// The default: remembers nothing across a process, which is exactly what a
/// test wants and what the app had before persistence landed.
final class InMemorySessionStore extends SessionStore {
  Session? _session;

  @override
  Session? read() => _session;

  @override
  void store(Session session) => _session = session;

  @override
  void clear() => _session = null;
}

final class PrefsSessionStore extends SessionStore {
  PrefsSessionStore(this._prefs);

  static const _key = 'session.v1';

  final SharedPreferences _prefs;

  @override
  Session? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return SessionCodec.fromJson(json);
    } on FormatException {
      // A half-written or downgraded record is not worth a crash on launch.
      // Dropping it costs one sign-in; throwing costs the app.
      return null;
    }
  }

  @override
  void store(Session session) =>
      _prefs.setString(_key, jsonEncode(SessionCodec.toJson(session)));

  @override
  void clear() => _prefs.remove(_key);
}

/// Serialisation, kept out of [Session] so the model has no opinion about
/// storage — and so the decisions about *what* is kept are all in one place.
abstract final class SessionCodec {
  /// Whether this session is worth writing at all.
  ///
  /// A visitor has nothing to remember. A session mid-verification is
  /// deliberately not remembered either: the design's restoration list puts
  /// "any OTP already sent" under *Not kept*, and resuming into a form whose
  /// code has expired is worse than starting the round again.
  static bool isWorthKeeping(Session session) =>
      session.stage == SessionStage.active ||
      session.stage == SessionStage.locked ||
      session.stage == SessionStage.needsConsent;

  static Map<String, dynamic> toJson(Session session) => {
    'stage': session.stage.name,
    'name': session.name,
    'phone': session.phone,
    'consentVersion': session.consentVersion,
    'channels': session.channels.map((c) => c.name).toList(),
    'locationGranted': session.locationGranted,
    'biometricOffered': session.biometricOffered,
    'biometricUnlock': session.biometricUnlock,
    // codeAttemptsLeft is absent on purpose: it is a property of one
    // verification round, not of the account.
  };

  static Session fromJson(Map<String, dynamic> json) {
    final stage = SessionStage.values.firstWhere(
      (s) => s.name == json['stage'],
      orElse: () => SessionStage.none,
    );
    final channels = <ConsentChannel>{
      for (final name in (json['channels'] as List? ?? const []))
        ...ConsentChannel.values.where((c) => c.name == name),
    };

    return Session(
      stage: stage,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      consentVersion: json['consentVersion'] as String?,
      channels: channels,
      locationGranted: json['locationGranted'] as bool? ?? false,
      biometricOffered: json['biometricOffered'] as bool? ?? false,
      biometricUnlock: json['biometricUnlock'] as bool? ?? false,
    );
  }

  /// What a restored session becomes on this launch.
  ///
  /// See the file comment: never [SessionStage.active], because a restored
  /// session that is immediately active makes a stolen handset a signed-in
  /// handset.
  static Session reopened(Session stored) {
    if (stored.stage != SessionStage.active) return stored;

    return stored.biometricUnlock
        // "Biometry or the device passcode reopens it."
        ? stored.copyWith(stage: SessionStage.locked)
        // "Off means an OTP every time the app is opened." The number is
        // remembered so it need not be retyped; the code is not skipped.
        : stored.copyWith(
            stage: SessionStage.confirmingNumber,
            codeAttemptsLeft: Session.maxCodeAttempts,
          );
  }
}

/// Overridden in `main()` with [PrefsSessionStore] once
/// `SharedPreferences.getInstance()` has resolved, so every read and write
/// after startup is synchronous and [SessionController.build] stays sync.
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => InMemorySessionStore(),
);
