/// Invariant S-1 — **every provider callback resolves the round.**
///
/// `verifyPhoneNumber` reports through callbacks rather than by returning, and
/// the failure mode of a callback interface is not an exception: it is a hang,
/// with the button stuck on "Sending…", nothing in the log, and no screen state
/// to inspect. That is the single hardest thing in this flow to diagnose, and
/// it shipped — `verificationCompleted` completed nothing, so the second
/// sign-in on a handset Firebase had already seen never returned at all.
///
/// So these tests do not check what `send` returns so much as **that it
/// returns**, on every branch the SDK can take. See docs/entry-flow.md §6.2 for
/// the contract table this mirrors row for row.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/otp_firebase.dart';
import 'package:ipelege/core/session.dart';

/// Which callback the fake SDK will fire, and in what order.
typedef _Behaviour =
    void Function({
      required PhoneVerificationCompleted completed,
      required PhoneVerificationFailed failed,
      required PhoneCodeSent codeSent,
      required PhoneCodeAutoRetrievalTimeout timedOut,
    });

/// A stand-in for `FirebaseAuth` that fires whichever callbacks a test asks
/// for. `noSuchMethod` covers the rest of the surface — nothing here touches
/// it, and a fake that implemented it would be inventing behaviour.
class _FakeAuth implements FirebaseAuth {
  _FakeAuth(this.behaviour);

  final _Behaviour behaviour;

  int signIns = 0;
  int? lastResendToken;
  int rounds = 0;

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
  }) async {
    rounds++;
    lastResendToken = forceResendingToken;
    behaviour(
      completed: verificationCompleted,
      failed: verificationFailed,
      codeSent: codeSent,
      timedOut: codeAutoRetrievalTimeout,
    );
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    signIns++;
    return _FakeCredential();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PhoneAuthCredential _credential() =>
    PhoneAuthProvider.credential(verificationId: 'vid', smsCode: '123456');

void main() {
  const number = '71 234 567';

  group('every callback resolves the round — S-1', () {
    test('codeSent means a message is on its way', () async {
      final auth = _FakeAuth(
        ({
          required completed,
          required failed,
          required codeSent,
          required timedOut,
        }) => codeSent('vid', 42),
      );

      expect(await FirebaseOtpVerifier(auth).send(number), OtpSendOutcome.sent);
    });

    test(
      'verificationCompleted alone is a pass, not a hang — the 2026-08-21 bug',
      () async {
        // Instead of codeSent, not after it. Nothing else fires in this round,
        // which is exactly why the missing `complete` was invisible until a
        // second sign-in on a real handset.
        final auth = _FakeAuth(
          ({
            required completed,
            required failed,
            required codeSent,
            required timedOut,
          }) => completed(_credential()),
        );

        final outcome = await FirebaseOtpVerifier(auth).send(number);

        expect(outcome, OtpSendOutcome.autoVerified);
        expect(auth.signIns, 1, reason: 'the credential still has to be used');
      },
    );

    test(
      'verificationFailed maps onto the reason, and it is not a hang',
      () async {
        Future<OtpSendOutcome> failWith(String code) {
          final auth = _FakeAuth(
            ({
              required completed,
              required failed,
              required codeSent,
              required timedOut,
            }) => failed(FirebaseAuthException(code: code)),
          );
          return FirebaseOtpVerifier(auth).send(number);
        }

        expect(
          await failWith('invalid-phone-number'),
          OtpSendOutcome.invalidNumber,
        );
        expect(
          await failWith('too-many-requests'),
          OtpSendOutcome.tooManyRequests,
        );
        expect(
          await failWith('quota-exceeded'),
          OtpSendOutcome.tooManyRequests,
        );
        // Anything unrecognised is still an answer. A new SDK error code must
        // not be able to hang the screen.
        expect(
          await failWith('some-code-nobody-has-seen'),
          OtpSendOutcome.unavailable,
        );
      },
    );

    test('auto-retrieval after codeSent does not change the answer', () async {
      // Both fire in one round, which the SDK is entitled to do. The round is
      // already `sent`; completing it twice must not throw.
      final auth = _FakeAuth(({
        required completed,
        required failed,
        required codeSent,
        required timedOut,
      }) {
        codeSent('vid', 42);
        completed(_credential());
      });
      final verifier = FirebaseOtpVerifier(auth);

      expect(await verifier.send(number), OtpSendOutcome.sent);
    });

    test('the retrieval timeout is not a failure', () async {
      // The shortcut gave up; the code is still valid and still typeable.
      final auth = _FakeAuth(({
        required completed,
        required failed,
        required codeSent,
        required timedOut,
      }) {
        codeSent('vid', 42);
        timedOut('vid');
      });

      expect(await FirebaseOtpVerifier(auth).send(number), OtpSendOutcome.sent);
    });
  });

  group('the round is broadcast to whoever is listening', () {
    test(
      'auto-retrieval reaches a screen the sender never knew about',
      () async {
        // The verify screen is built by a *different* screen's send, so a
        // callback handed to `send` could never reach it.
        late PhoneVerificationCompleted fire;
        final auth = _FakeAuth(({
          required completed,
          required failed,
          required codeSent,
          required timedOut,
        }) {
          fire = completed;
          codeSent('vid', 42);
        });
        final verifier = FirebaseOtpVerifier(auth);
        await verifier.send(number);

        final heard = verifier.autoVerifications.first;
        fire(_credential());

        await expectLater(heard, completes);
      },
    );
  });

  group('a resend is a resend, not a new attempt', () {
    test('the second send carries the token the first was given', () async {
      final auth = _FakeAuth(
        ({
          required completed,
          required failed,
          required codeSent,
          required timedOut,
        }) => codeSent('vid', 42),
      );
      final verifier = FirebaseOtpVerifier(auth);

      await verifier.send(number);
      expect(auth.lastResendToken, isNull, reason: 'the first round has none');

      await verifier.send(number);
      expect(
        auth.lastResendToken,
        42,
        reason:
            'without the token the network sees two fresh attempts, which is '
            'what walks a number into a too-many-requests',
      );
      expect(auth.rounds, 2);
    });
  });

  group('a code cannot be right before one was asked for', () {
    test('no send, no verificationId, no acceptance', () async {
      final auth = _FakeAuth(
        ({
          required completed,
          required failed,
          required codeSent,
          required timedOut,
        }) {},
      );

      // Refusing beats throwing: the screen already handles a wrong code and
      // has no handler for an exception.
      expect(await FirebaseOtpVerifier(auth).isCorrect('123456'), isFalse);
      expect(auth.signIns, 0);
    });
  });

  group('a Botswana number, or nothing', () {
    test('the sender is never reached for a number it would reject', () async {
      final auth = _FakeAuth(
        ({
          required completed,
          required failed,
          required codeSent,
          required timedOut,
        }) => codeSent('vid', 42),
      );

      expect(
        await FirebaseOtpVerifier(auth).send('12 345'),
        OtpSendOutcome.invalidNumber,
      );
      expect(auth.rounds, 0);
    });

    test('and 267-prefixed input is the same number', () async {
      final auth = _FakeAuth(
        ({
          required completed,
          required failed,
          required codeSent,
          required timedOut,
        }) => codeSent('vid', 42),
      );

      expect(
        await FirebaseOtpVerifier(auth).send('+267 71 234 567'),
        OtpSendOutcome.sent,
      );
    });
  });
}
