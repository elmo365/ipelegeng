/// The real sender: Firebase Auth phone verification.
///
/// Kept out of `session.dart` on purpose. The session's state machine is the
/// part with the rules — OTP is unskippable, attempts are limited, a resend
/// does not restore them — and none of that should have to know what a
/// `FirebaseAuthException` is. `session.dart` owns [OtpVerifier]; this owns the
/// one implementation that costs money.
///
/// ## Why Firebase rather than an SMS gateway, for now
///
/// Not because it is cheapest per message — it is not. Because it removes a
/// **lead-time** item: an aggregator contract or an MNO agreement has to be
/// negotiated before a single code can be sent, and that can hold a launch
/// date hostage in a way writing code cannot. Firebase sends today. See
/// docs/sms-otp.md §3.
///
/// It is also the only route that gives Android **auto-retrieval** for free —
/// `verificationCompleted` fires when the platform reads the SMS itself, with
/// no `READ_SMS` permission and no app-hash formatting on our side. Doing that
/// against our own gateway means the SMS Retriever API and an 11-character
/// hash appended to every message.
///
/// ## What has to be true for this to work
///
/// 1. **Phone must be enabled** as a sign-in provider in the Firebase console.
///    It is off by default and nothing here can turn it on.
/// 2. **The app's SHA-1 and SHA-256 must be registered** on the Firebase
///    Android app. Without them Play Integrity cannot vouch for the app and
///    every send fails — this is the step that is usually missed, and it fails
///    with a message that does not name it.
/// 3. Real delivery needs billing enabled past the free quota. **Test phone
///    numbers with fixed codes are free and unlimited**, which is how this
///    should be exercised until launch.
///
/// ## What this deliberately does not do
///
/// It does not make Firebase the identity. `signInWithCredential` produces a
/// Firebase user, and this class throws it away — all it reports is *was this
/// code the right one*. The account of record is the app's own session, and
/// later the row in Postgres beside the wallet and the KYC documents. Splitting
/// identity from the ledger across two systems is a problem this app does not
/// need; see docs/architecture.md, "Why not Firebase".
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'session.dart';

class FirebaseOtpVerifier implements OtpVerifier {
  FirebaseOtpVerifier([FirebaseAuth? auth])
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Handed back by `codeSent` and required to confirm a typed code. Null
  /// until a send succeeds, which is why [isCorrect] refuses rather than
  /// throwing when it is missing.
  String? _verificationId;

  /// Lets a resend reuse the same round rather than starting a new one, which
  /// is what stops a resend looking like a fresh attempt to the network.
  int? _resendToken;

  @override
  Future<OtpSendOutcome> send(
    String phone, {
    void Function()? onAutoVerified,
  }) async {
    // Firebase wants E.164. `Phone.normalise` formats for humans — spaces and
    // all — so the digits are rebuilt here.
    final e164 = _e164(phone);
    if (e164 == null) return OtpSendOutcome.invalidNumber;

    // `verifyPhoneNumber` reports through callbacks rather than by returning,
    // so the outcome is collected into a future the caller can await.
    final sent = _Latch<OtpSendOutcome>();

    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      forceResendingToken: _resendToken,
      // Android only, and the reason this interface has an auto-verified hook
      // at all: the platform read the SMS and there is nothing left to type.
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
          onAutoVerified?.call();
        } on FirebaseAuthException {
          // Auto-retrieval failing is not an error the user should see — the
          // code is still on its way to the field they are looking at.
        }
      },
      verificationFailed: (e) {
        // **Log the platform's own words before collapsing them.**
        // [_readFailure] maps a rich exception onto four enum values, which is
        // right for the screen and useless for diagnosis: the first version of
        // this shipped without the line below, and a real failure on a real
        // handset surfaced as "could not send a code" with nothing anywhere
        // saying why. A seam that discards the cause is not observable.
        debugPrint('otp: verificationFailed code=${e.code} message=${e.message}');
        sent.complete(_readFailure(e));
      },
      codeSent: (verificationId, resendToken) {
        debugPrint('otp: codeSent, verificationId received');
        _verificationId = verificationId;
        _resendToken = resendToken;
        sent.complete(OtpSendOutcome.sent);
      },
      // Auto-retrieval gave up. The code is still valid and still typeable, so
      // this is not a failure — it only means the shortcut did not happen.
      codeAutoRetrievalTimeout: (verificationId) =>
          _verificationId = verificationId,
    );

    return sent.future;
  }

  @override
  Future<bool> isCorrect(String code) async {
    final id = _verificationId;
    // No send has succeeded, so there is nothing this code could be correct
    // *against*. Refusing beats throwing: the screen already handles a wrong
    // code, and it has no handler for an exception.
    if (id == null) return false;

    try {
      await _auth.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: id, smsCode: code),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('otp: confirm rejected code=${e.code}');
      // Wrong code, expired code, or a session that has moved on. All three
      // are "not this code" from the screen's point of view, and the attempt
      // counter in `session.dart` is what decides when that becomes a lockout.
      return false;
    }
  }

  static OtpSendOutcome _readFailure(FirebaseAuthException e) =>
      switch (e.code) {
        'invalid-phone-number' => OtpSendOutcome.invalidNumber,
        'too-many-requests' || 'quota-exceeded' =>
          OtpSendOutcome.tooManyRequests,
        _ => OtpSendOutcome.unavailable,
      };

  /// `+2677XXXXXXX`, or null if this is not a Botswana mobile number.
  ///
  /// Duplicated from `Phone.isPlausible`'s rule rather than imported as a
  /// formatter, because what goes on the wire and what goes on the screen are
  /// different strings and should not share a function.
  static String? _e164(String input) {
    var d = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('267')) d = d.substring(3);
    if (d.length != 8 || !d.startsWith('7')) return null;
    return '+267$d';
  }
}

/// A future completed by whichever callback fires first.
///
/// `verifyPhoneNumber` can call more than one of its callbacks in a single
/// round — `verificationCompleted` after `codeSent`, for instance — so
/// completing twice is normal rather than a bug, and must not throw.
class _Latch<T> {
  final _completer = Completer<T>();

  Future<T> get future => _completer.future;

  void complete(T value) {
    if (!_completer.isCompleted) _completer.complete(value);
  }
}
