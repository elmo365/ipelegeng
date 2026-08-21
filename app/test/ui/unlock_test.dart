/// The sensor, wired.
///
/// Until 2026-08-21 both buttons on the unlock screen called `unlock()`
/// directly and no prompt was ever shown — the screen, the states and the
/// fallback's visual weight were right, and the sensor was not connected.
///
/// Two rules under all of these:
///
/// - **Biometry unlocks; it never authenticates.** A refusal leaves the session
///   locked. It cannot leave it signed in, because [SessionController.unlock]
///   only moves a session that was already locked.
/// - **The passcode is not a consolation.** On a handset with no usable sensor
///   it becomes the primary action, because there it is the only way in.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/biometrics.dart';
import 'package:ipelege/core/session.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/ui/screens/consumer/home_screen.dart';

/// Records what it was asked for, and answers however the test says.
class FakeBiometrics implements Biometrics {
  FakeBiometrics({
    this.available = BiometricAvailability.ready,
    this.outcome = BiometricOutcome.ok,
  });

  BiometricAvailability available;
  BiometricOutcome outcome;

  final prompts = <BiometricPrompt>[];

  @override
  Future<BiometricAvailability> availability() async => available;

  @override
  Future<BiometricOutcome> authenticate({
    required BiometricPrompt prompt,
    required String reason,
  }) async {
    prompts.add(prompt);
    return outcome;
  }
}

void main() {
  /// A locked session on the unlock screen, with a fake sensor behind it.
  Future<ProviderContainer> pumpLocked(
    WidgetTester tester,
    FakeBiometrics biometrics,
  ) async {
    final container = ProviderContainer(
      overrides: [
        biometricsProvider.overrideWithValue(biometrics),
        routerProvider.overrideWithValue(
          createRouter(initialLocation: Routes.unlock),
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(sessionProvider.notifier)
        .restore(
          const Session(
            stage: SessionStage.locked,
            name: 'Kabo Mothibi',
            phone: '71 234 567',
            consentVersion: Consent.current,
            biometricOffered: true,
            biometricUnlock: true,
          ),
        );

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

  group('a fingerprint reopens the session', () {
    testWidgets('the prompt is asked for, and it is biometric-only', (
      tester,
    ) async {
      final biometrics = FakeBiometrics();
      final container = await pumpLocked(tester, biometrics);

      await tester.tap(find.text('Use fingerprint'));
      await tester.pumpAndSettle();

      expect(
        biometrics.prompts,
        [BiometricPrompt.biometric],
        reason:
            'allowing the device credential here would make the two buttons '
            'on this screen the same button',
      );
      expect(container.read(sessionProvider).canBook, isTrue);
      expect(find.byType(ConsumerHomeScreen), findsOneWidget);
    });

    testWidgets('the passcode asks for the device credential instead', (
      tester,
    ) async {
      final biometrics = FakeBiometrics();
      final container = await pumpLocked(tester, biometrics);

      await tester.tap(find.text('Enter device passcode'));
      await tester.pumpAndSettle();

      expect(biometrics.prompts, [BiometricPrompt.deviceCredential]);
      expect(container.read(sessionProvider).canBook, isTrue);
    });
  });

  group('a refusal leaves the door shut', () {
    testWidgets('cancelling does not unlock, and does not shout', (
      tester,
    ) async {
      final biometrics = FakeBiometrics(outcome: BiometricOutcome.refused);
      final container = await pumpLocked(tester, biometrics);

      await tester.tap(find.text('Use fingerprint'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).stage, SessionStage.locked);
      expect(container.read(sessionProvider).canBook, isFalse);
      expect(find.byType(ConsumerHomeScreen), findsNothing);

      // A cancelled prompt is a change of mind, not an error — and the other
      // way in is already on screen.
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.text('Enter device passcode'),
        findsOneWidget,
        reason: 'the way in that still works has to stay on screen',
      );
    });

    testWidgets('and it can be retried', (tester) async {
      final biometrics = FakeBiometrics(outcome: BiometricOutcome.refused);
      final container = await pumpLocked(tester, biometrics);

      await tester.tap(find.text('Use fingerprint'));
      await tester.pumpAndSettle();

      biometrics.outcome = BiometricOutcome.ok;
      await tester.tap(find.text('Use fingerprint'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).canBook, isTrue);
    });
  });

  group('a handset with no sensor', () {
    testWidgets('is not offered a button that can only fail', (tester) async {
      // "Broken or absent sensors are common on the target hardware."
      await pumpLocked(
        tester,
        FakeBiometrics(available: BiometricAvailability.unsupported),
      );

      expect(find.text('Use fingerprint'), findsNothing);
      expect(find.text('Enter device passcode'), findsOneWidget);
    });

    testWidgets('is not told to use a fingerprint either', (tester) async {
      await pumpLocked(
        tester,
        FakeBiometrics(available: BiometricAvailability.unsupported),
      );

      expect(find.textContaining('fingerprint'), findsNothing);
      expect(
        find.textContaining('device passcode to continue'),
        findsOneWidget,
      );
    });

    testWidgets('and is not shown a fingerprint either', (tester) async {
      // The copy and the buttons were conditional from the start; the 50 dp
      // glyph above them was not, and Phase 0's colour gate caught it on the
      // emulator's no-enrolment path. A picture of a fingerprint over the
      // words "use your device passcode" is the same bug as the copy, drawn
      // larger — it is what makes someone think the app is broken rather than
      // their phone. See docs/design-deltas.md §18.4.
      await pumpLocked(
        tester,
        FakeBiometrics(available: BiometricAvailability.unsupported),
      );

      expect(find.byIcon(Icons.fingerprint), findsNothing);
      expect(find.byIcon(Icons.dialpad), findsWidgets);
    });

    testWidgets('the passcode still gets all the way in', (tester) async {
      final biometrics = FakeBiometrics(
        available: BiometricAvailability.unsupported,
      );
      final container = await pumpLocked(tester, biometrics);

      await tester.tap(find.text('Enter device passcode'));
      await tester.pumpAndSettle();

      expect(biometrics.prompts, [BiometricPrompt.deviceCredential]);
      expect(container.read(sessionProvider).canBook, isTrue);
    });

    testWidgets('one reported mid-prompt collapses the screen to passcode', (
      tester,
    ) async {
      // The check said ready and the prompt disagreed — a sensor in use by
      // another app, or an enrolment removed since launch.
      final biometrics = FakeBiometrics(outcome: BiometricOutcome.unavailable);
      await pumpLocked(tester, biometrics);

      expect(find.text('Use fingerprint'), findsOneWidget);
      await tester.tap(find.text('Use fingerprint'));
      await tester.pumpAndSettle();

      expect(
        find.text('Use fingerprint'),
        findsNothing,
        reason: 'a button the platform just said cannot work is still drawn',
      );
      expect(find.text('Enter device passcode'), findsOneWidget);
    });
  });

  group('signing out is the only path that re-authenticates', () {
    testWidgets('it clears the session rather than unlocking it', (
      tester,
    ) async {
      final container = await pumpLocked(tester, FakeBiometrics());

      await tester.tap(find.text('Sign in as someone else'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).stage, SessionStage.none);
      expect(container.read(sessionProvider).phone, isNull);
    });
  });
}
