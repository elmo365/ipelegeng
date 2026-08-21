/// The one thing no emulator and no fake can answer.
///
/// `core/biometrics.dart` has always had a seam — [PlatformBiometrics] ships,
/// [AlwaysAllowBiometrics] is the default so a widget test needs no platform
/// channel — and every test to date has run against the fake. The emulator got
/// as far as the *refusal* branch, because it has a sensor with nothing
/// enrolled, which is exactly the design's "biometry unavailable → passcode"
/// case. It could never reach the other one.
///
/// This is the other one. It needs a handset with a real sensor and a real
/// enrolled fingerprint, and it needs **a person to touch it** — which is why
/// it is a separate target from `gate_test.dart` rather than a shot in it. A
/// gate is unattended; this is not.
///
/// Run it:
///
/// ```
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/biometric_test.dart -d <device-id>
/// ```
///
/// Then touch the sensor when the prompt appears. It waits [_reach] for you.
///
/// What it proves, in order: the screen offers biometry on hardware that has
/// it; tapping raises a **real** system prompt; and a real fingerprint carries
/// a locked session all the way back to `active`. The third is the one that
/// matters — biometry *unlocks*, it never authenticates, and the whole point
/// is that the session on the other side is the one that was already there.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ipelege/core/biometrics.dart';
import 'package:ipelege/core/session.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';

/// How long the test waits for a human to touch the sensor.
const _reach = Duration(seconds: 30);

/// Pump for a fixed wall-clock window. Not `pumpAndSettle`: a system prompt is
/// not a Flutter frame, so there is nothing to settle *to*, and settling would
/// simply time out after ten minutes.
Future<void> _hold(WidgetTester tester, Duration total) async {
  final end = DateTime.now().add(total);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a real fingerprint reopens a real locked session', (
    tester,
  ) async {
    await binding.convertFlutterSurfaceToImage();

    final container = ProviderContainer(
      overrides: [
        routerProvider.overrideWithValue(
          createRouter(initialLocation: Routes.unlock),
        ),
        // The whole point. Not the fake.
        biometricsProvider.overrideWithValue(PlatformBiometrics()),
      ],
    );
    addTearDown(container.dispose);

    // Sign in properly and then lock, because `lock()` deliberately does
    // nothing to a session that was never active — biometry can only ever
    // *unlock*, and a test that started from a fabricated locked state would
    // be testing a state the app cannot reach.
    final session = container.read(sessionProvider.notifier);
    session
      ..requestCode(name: 'Neo Kgosi', phone: '71 234 567')
      ..confirmCode()
      ..agree();
    expect(
      container.read(sessionProvider).stage,
      SessionStage.active,
      reason: 'the session must be genuinely signed in before it is locked',
    );
    session.lock();
    expect(container.read(sessionProvider).stage, SessionStage.locked);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpelegeApp(),
      ),
    );
    await _hold(tester, const Duration(seconds: 2));

    // ---- 1. The ready branch, on hardware that actually has a sensor -------
    //
    // The emulator can never produce this. `availability()` has gone to the
    // platform and come back usable, so the fingerprint is the primary and the
    // copy names it.
    expect(
      find.text('Use fingerprint'),
      findsOneWidget,
      reason:
          'This handset has enrolled prints, so the screen must offer them. '
          'If this fails, PlatformBiometrics reported the sensor unusable — '
          'check `adb shell dumpsys fingerprint` for an enrolled count.',
    );
    expect(find.textContaining('Use your fingerprint to continue'), findsOne);
    await binding.takeScreenshot('phone-unlock-ready');

    // ---- 2. Raise a real prompt -------------------------------------------
    debugPrint('biometric: touch the sensor now — waiting ${_reach.inSeconds}s');
    await tester.tap(find.text('Use fingerprint'));
    await _hold(tester, _reach);

    // ---- 3. It carried the session all the way back ------------------------
    expect(
      container.read(sessionProvider).stage,
      SessionStage.active,
      reason:
          'The prompt was raised but the session did not reopen. Either the '
          'sensor was not touched within ${_reach.inSeconds}s, or the '
          'authenticate() result is not being routed back into the session.',
    );

    // And it is the *same* session, not a new one. Biometry unlocks; it never
    // authenticates, so the name that comes back is the one that was there.
    expect(container.read(sessionProvider).name, 'Neo Kgosi');

    debugPrint('biometric: unlocked — the real sensor reopened the session');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
