/// Phase 0's gate, as a run rather than a ritual.
///
/// Phase 0 exists because five screens were built and shipped before anyone
/// looked at one on a handset, and running it the first time found the app had
/// no identity at all — a stock Flutter icon and a white cold-start flash that
/// no amount of widget testing would ever have surfaced. It was then widened to
/// cover motion after the colour-only pass missed that every duration in the
/// app was wrong.
///
/// The lesson both times was the same: **a gate nobody can re-run is a gate
/// that gets skipped.** So it is a script. It walks every screen built since
/// 2026-08-20, in light and in dark, and writes a PNG per artboard into
/// `build/gate/` for comparison against the canvas.
///
/// Run it:
///
/// ```
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/gate_test.dart -d emulator-5554
/// ```
///
/// **This renders real screens on a real device.** It asserts almost nothing,
/// on purpose — what it produces is evidence for a human comparison against the
/// artboards, not a pass/fail. The rules that *can* be asserted are asserted in
/// `test/`, where they run in a second rather than in minutes; see
/// `test/ui/motion_test.dart` for the motion half.
///
/// Screens are reached by overriding [routerProvider], the same seam the widget
/// tests use, rather than by tapping through the app: a gate that has to
/// complete a nine-step journey to photograph the ninth screen fails at step
/// two and shows nothing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ipelege/core/booking.dart';
import 'package:ipelege/core/demo_data.dart';
import 'package:ipelege/core/session.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/theme/theme_mode.dart';

/// One artboard to photograph.
@immutable
class Shot {
  const Shot(this.name, this.location, {this.session = _visitor, this.after});

  /// The file stem. Prefixed with the mode when written.
  final String name;

  final String location;

  /// What has to be true of the session for the screen to be reachable. A
  /// visitor by default, because that is a cold install.
  final void Function(SessionController) session;

  /// Anything that has to happen on the screen before it is worth
  /// photographing — a tap that opens a sheet, say. Kept to that: a gate that
  /// drives a journey is a gate that fails at step two and shows nothing.
  final Future<void> Function(WidgetTester)? after;

  static void _visitor(SessionController _) {}

  /// Registered, verified, consented — the state most of the app is seen in.
  static void signedIn(SessionController s) {
    s
      ..requestCode(name: 'Neo Kgosi', phone: '71 234 567')
      ..confirmCode()
      ..agree();
  }

  /// Signed in, then locked — how a reopened app with biometry on comes back.
  static void locked(SessionController s) {
    signedIn(s);
    s.lock();
  }

  /// Mid-verification: a code has been sent and not yet entered.
  static void verifying(SessionController s) {
    s.requestCode(name: 'Neo Kgosi', phone: '71 234 567');
  }
}

/// Everything built since 2026-08-20, in the order the design's own journey
/// map walks it. The eleven booking states are expanded below rather than
/// listed here, because they are one artboard in eleven costumes.
final _shots = <Shot>[
  // Phase 1 · the account gap.
  const Shot('01-splash', Routes.splash),
  const Shot('02-register', Routes.register),
  const Shot('03-sign-in', Routes.signIn),
  const Shot('04-verify', Routes.verify, session: Shot.verifying),
  const Shot('05-consent', Routes.consent, session: Shot.verifying),
  const Shot('06-biometric-enrolment', Routes.biometricEnrolment,
      session: Shot.signedIn),
  const Shot('07-unlock', Routes.unlock, session: Shot.locked),
  const Shot('08-location', Routes.location, session: Shot.signedIn),

  // The shell, for the colour comparison the first gate made against these.
  const Shot('09-home', Routes.home, session: Shot.signedIn),
  Shot('10-category-browse', Routes.categoryOf('plumbing'),
      session: Shot.signedIn),
  Shot('11-listing-detail', Routes.listingOf(Demo.listing.id),
      session: Shot.signedIn),

  // Phase 2 · booking.
  Shot('12-booking-request', Routes.bookingRequestOf(Demo.listing.id),
      session: Shot.signedIn),
  Shot('30-rate-review', Routes.bookingRateOf(Demo.bookingId),
      session: Shot.signedIn),

  // Phase 3 · the loop prompt. **This is the only placement that can be
  // photographed at all.** The design's other one is a completed booking, and
  // all three of its pairs — movers→plumbing, catering→hire, hire→catering —
  // point at categories the demo marks thin, so the empty-room rule withholds
  // every one of them. That is the feature working, not a gap: see
  // docs/design-deltas.md §18.
  Shot('31-rentals-listing', Routes.listingOf('R-2210'), session: Shot.signedIn),
  Shot(
    '32-loop-handoff-sheet',
    Routes.listingOf('R-2210'),
    session: Shot.signedIn,
    after: (tester) async {
      final enquire = find.text('Enquire about this room');
      if (enquire.evaluate().isEmpty) return;
      await tester.tap(enquire);
    },
  ),

  // The provider side, unchanged since Phase 0 but re-shot so the dark mode
  // this gate has never compared is on the record.
  const Shot('33-provider-home', Routes.dashboard, session: Shot.signedIn),
  const Shot('34-wallet', Routes.wallet, session: Shot.signedIn),
];

/// The eleven states, each its own artboard — `BOOKING STATUS · 11 STATES` is
/// one canvas artboard and eleven things to compare.
Iterable<Shot> get _bookingStates sync* {
  for (var i = 0; i < BookingState.all.length; i++) {
    final state = BookingState.all[i];
    yield Shot(
      '${13 + i}-booking-${state.key.toLowerCase().replaceAll('_', '-')}',
      '${Routes.bookingOf(Demo.bookingId)}?state=${state.key}',
      session: Shot.signedIn,
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the gate', (tester) async {
    // Android renders into a SurfaceView, which screencap cannot read. This
    // swaps it for an image-backed surface for the rest of the run; it must
    // happen once, before the first shot, and never again.
    await binding.convertFlutterSurfaceToImage();

    final shots = [..._shots, ..._bookingStates]
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final label = mode == ThemeMode.light ? 'light' : 'dark';

      for (final shot in shots) {
        final container = ProviderContainer(
          overrides: [
            routerProvider.overrideWithValue(
              createRouter(initialLocation: shot.location),
            ),
          ],
        );
        container.read(themeModeProvider.notifier).select(mode);
        shot.session(container.read(sessionProvider.notifier));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const IpelegeApp(),
          ),
        );

        // Not pumpAndSettle: the splash holds a timer, and a screen that never
        // stops scheduling frames turns settling into a ten-minute timeout
        // rather than an error. A fixed window photographs whatever is on
        // screen, which is the point.
        await _hold(tester);

        if (shot.after != null) {
          await shot.after!(tester);
          await _hold(tester);
        }

        debugPrint('gate: $label/${shot.name}');
        await binding.takeScreenshot('$label-${shot.name}');

        container.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}

/// Pump for a fixed wall-clock window, so an animating screen is photographed
/// rather than waited on forever.
Future<void> _hold(
  WidgetTester tester, [
  Duration total = const Duration(milliseconds: 900),
]) async {
  final end = DateTime.now().add(total);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
