/// The entry flow as a process — docs/entry-flow.md, invariants S-2, S-3, S-7
/// and S-8.
///
/// `entry_test.dart` covers the screens; this covers the **joins between
/// them**, which is where all three bugs found on a Galaxy S24 on 2026-08-21
/// actually were. Every test here drives a real screen against a fake sender
/// and asks where the app ended up, rather than asking what a widget drew.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/session.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/ui/components/choice_cards.dart';
import 'package:ipelege/ui/screens/entry/biometric_enrolment_screen.dart';
import 'package:ipelege/ui/screens/entry/consent_screen.dart';
import 'package:ipelege/ui/screens/entry/sign_in_screen.dart';
import 'package:ipelege/ui/screens/entry/verify_screen.dart';

/// A sender with no network and a settable answer.
///
/// Counting [sends] is the point of it: two of the invariants below are about
/// whether a message was actually asked for, and a fake that only returns a
/// value cannot answer that.
class _FakeSender implements OtpVerifier {
  OtpSendOutcome outcome = OtpSendOutcome.sent;
  int sends = 0;

  final _auto = StreamController<void>.broadcast();

  @override
  Future<OtpSendOutcome> send(String phone) async {
    sends++;
    return outcome;
  }

  @override
  Stream<void> get autoVerifications => _auto.stream;

  @override
  Future<bool> isCorrect(String code) async =>
      code.length == Session.codeLength;

  /// The platform read the SMS while the verify screen was up.
  void readTheSms() => _auto.add(null);

  void dispose() => _auto.close();
}

void main() {
  late _FakeSender sender;

  setUp(() => sender = _FakeSender());
  tearDown(() => sender.dispose());

  Future<ProviderContainer> pumpAt(
    WidgetTester tester,
    String location, {
    Session? restore,
  }) async {
    late final ProviderContainer container;
    container = ProviderContainer(
      overrides: [
        otpVerifierProvider.overrideWithValue(sender),
        routerProvider.overrideWith(
          (ref) => createRouter(
            initialLocation: location,
            readSession: () => container.read(sessionProvider),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    if (restore != null) {
      container.read(sessionProvider.notifier).restore(restore);
    }

    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpelegeApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Everything answered once already: consent current, offer spent, location
  /// asked. What is left is only the sign-in itself.
  const returning = Session(
    stage: SessionStage.locked,
    name: 'Kabo Mothibi',
    phone: '71 234 567',
    consentVersion: Consent.current,
    channels: {ConsentChannel.whatsApp},
    biometricOffered: true,
    biometricUnlock: true,
    locationAsked: true,
    locationGranted: true,
  );

  Future<void> typeNumberAndSend(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, '71234567');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
  }

  group('a screen only moves on if a code was actually sent — S-2', () {
    testWidgets('a failed send stays put and says why', (tester) async {
      sender.outcome = OtpSendOutcome.unavailable;
      await pumpAt(tester, Routes.signIn, restore: returning);

      await typeNumberAndSend(tester);

      expect(sender.sends, 1);
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(
        find.byType(VerifyScreen),
        findsNothing,
        reason:
            'a "Confirm your number" screen above a code that was never sent '
            'is the worst version of this failing',
      );
      expect(find.textContaining('Could not send a code'), findsOneWidget);
    });

    testWidgets('a throttled send names the throttle', (tester) async {
      sender.outcome = OtpSendOutcome.tooManyRequests;
      await pumpAt(tester, Routes.signIn, restore: returning);

      await typeNumberAndSend(tester);

      expect(find.textContaining('Too many codes'), findsOneWidget);
    });

    testWidgets('a successful send does move on', (tester) async {
      await pumpAt(tester, Routes.signIn, restore: returning);

      await typeNumberAndSend(tester);

      expect(find.byType(VerifyScreen), findsOneWidget);
    });
  });

  group('instant verification is a pass — S-3', () {
    testWidgets('a returning member skips the code screen entirely', (
      tester,
    ) async {
      // The bug: this used to hang on "Sending…" forever, because
      // verificationCompleted resolved nothing. See entry-flow.md §8.1.
      sender.outcome = OtpSendOutcome.autoVerified;
      final container = await pumpAt(tester, Routes.signIn, restore: returning);

      await typeNumberAndSend(tester);

      expect(find.byType(VerifyScreen), findsNothing);
      expect(container.read(sessionProvider).stage, SessionStage.active);
      expect(container.read(sessionProvider).canBook, isTrue);
    });

    testWidgets('but it cannot skip consent for an account that owes it', (
      tester,
    ) async {
      // A brand-new account verified this way has never seen a consent card,
      // because there was no code screen to carry one. FR-1.10 is satisfied by
      // the state machine, not by that screen happening to have a checkbox.
      sender.outcome = OtpSendOutcome.autoVerified;
      final container = await pumpAt(tester, Routes.signIn);

      await typeNumberAndSend(tester);

      expect(container.read(sessionProvider).stage, SessionStage.needsConsent);
      expect(find.byType(ConsentScreen), findsOneWidget);
    });

    testWidgets('and it still makes the biometric offer once', (tester) async {
      sender.outcome = OtpSendOutcome.autoVerified;
      await pumpAt(
        tester,
        Routes.signIn,
        restore: returning.copyWith(biometricOffered: false),
      );

      await typeNumberAndSend(tester);

      expect(find.byType(BiometricEnrolmentScreen), findsOneWidget);
    });
  });

  group('signing in does not renegotiate consent — S-7', () {
    /// Mid-round, on a consent version that is current.
    const confirming = Session(
      stage: SessionStage.confirmingNumber,
      name: 'Kabo Mothibi',
      phone: '71 234 567',
      consentVersion: Consent.current,
      channels: {ConsentChannel.whatsApp},
      biometricOffered: true,
      locationAsked: true,
    );

    testWidgets('the card is not drawn for a member who has agreed', (
      tester,
    ) async {
      await pumpAt(tester, Routes.verify, restore: confirming);

      expect(find.byType(VerifyScreen), findsOneWidget);
      expect(
        find.byType(ConsentCard),
        findsNothing,
        reason:
            'an unticked optional box on a screen a member did not ask for is '
            'a channel withdrawal they never made',
      );
    });

    testWidgets('and their granted channels survive the round', (tester) async {
      final container = await pumpAt(
        tester,
        Routes.verify,
        restore: confirming,
      );

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify & continue'));
      await tester.pumpAndSettle();

      final session = container.read(sessionProvider);
      expect(session.stage, SessionStage.active);
      expect(
        session.channels,
        {ConsentChannel.whatsApp},
        reason:
            'WhatsApp was granted before this sign-in and nothing withdrew it',
      );
    });

    testWidgets('a first account is still asked, and cannot skip it', (
      tester,
    ) async {
      await pumpAt(
        tester,
        Routes.verify,
        restore: const Session(
          stage: SessionStage.confirmingNumber,
          name: 'Kabo Mothibi',
          phone: '71 234 567',
        ),
      );

      expect(find.byType(ConsentCard), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<ElevatedButton>(
              find.ancestor(
                of: find.text('Verify & continue'),
                matching: find.byType(ElevatedButton),
              ),
            )
            .onPressed,
        isNull,
        reason: 'six digits without the required tick is not enough',
      );
    });
  });

  group('resend sends — S-8', () {
    const confirming = Session(
      stage: SessionStage.confirmingNumber,
      name: 'Kabo Mothibi',
      phone: '71 234 567',
      consentVersion: Consent.current,
      biometricOffered: true,
      locationAsked: true,
    );

    /// Past the countdown, one second at a time so the periodic ticker runs the
    /// way it does on a handset.
    Future<void> waitOutTheTimer(WidgetTester tester) async {
      for (var i = 0; i <= VerifyScreen.resendSeconds; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }

    testWidgets('the button asks for a code, not just a new countdown', (
      tester,
    ) async {
      await pumpAt(tester, Routes.verify, restore: confirming);
      expect(sender.sends, 0);

      await waitOutTheTimer(tester);
      await tester.tap(find.text('Resend code'));
      await tester.pumpAndSettle();

      expect(
        sender.sends,
        1,
        reason:
            'this was wired to the countdown alone, so the one situation it '
            'exists for — an SMS that never arrived — was the one it could '
            'not fix',
      );
    });

    testWidgets('it does not restore attempts — S-9 at the screen', (
      tester,
    ) async {
      final container = await pumpAt(
        tester,
        Routes.verify,
        restore: confirming.copyWith(codeAttemptsLeft: 2),
      );

      await waitOutTheTimer(tester);
      await tester.tap(find.text('Resend code'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).codeAttemptsLeft, 2);
    });
  });

  group('auto-retrieval moves the screen on without a tap', () {
    testWidgets('the platform reads the SMS and the round completes', (
      tester,
    ) async {
      // The verify screen was built by a *different* screen's send, which is
      // why this arrives on a stream rather than on a callback handed to send.
      final container = await pumpAt(
        tester,
        Routes.verify,
        restore: const Session(
          stage: SessionStage.confirmingNumber,
          name: 'Kabo Mothibi',
          phone: '71 234 567',
          consentVersion: Consent.current,
          biometricOffered: true,
          locationAsked: true,
        ),
      );

      sender.readTheSms();
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).stage, SessionStage.active);
      expect(find.byType(VerifyScreen), findsNothing);
    });
  });
}
