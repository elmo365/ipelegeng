/// Motion, as tests — Phase 0's second gate.
///
/// Phase 0 originally checked colour against the canvas and nothing else, and
/// the motion pass that followed found every duration in `theme/motion.dart`
/// wrong. Those numbers were corrected on 2026-08-20; what these tests pin is
/// the half that correcting the numbers did not fix — **whether any screen
/// actually consumes them.**
///
/// The rules under test come from the canvas's transition table and its
/// per-state booking table, and each one is a rule about restraint rather than
/// about polish:
///
/// - the chip and the step bar animate **together**, over one duration, "so
///   the change reads as one event"
/// - **forward progress animates; every ending is instant** — a state that
///   reverses or fails must not travel across the screen as though something
///   were being achieved
/// - a screen **opened at** a state does not replay reaching it, and does not
///   buzz the phone for news it delivered an hour ago
/// - the balance counts **only when it changes** — "a figure that animates
///   every time you look at it reads as a live feed"
/// - reduce-motion collapses everything to zero rather than shortening it: on
///   these handsets that is a battery decision, not an accessibility edge case
///
/// See docs/design-system.md#motion and docs/build-order.md Phase 0.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/booking.dart';
import 'package:ipelege/theme/app_theme.dart';
import 'package:ipelege/theme/motion.dart';
import 'package:ipelege/theme/tokens.dart';
import 'package:ipelege/ui/components/enter_in_place.dart';
import 'package:ipelege/ui/components/money_text.dart';
import 'package:ipelege/ui/screens/consumer/booking_status_screen.dart';

/// The canvas's own numbers, written out rather than read from [Motion], so
/// these tests fail if the tokens drift back to the pre-correction values.
const _stateChange = Duration(milliseconds: 300);
const _enter = Duration(milliseconds: 220);
const _count = Duration(milliseconds: 400);
const _ratingDelay = Duration(milliseconds: 120);

BookingState _state(String key) => BookingState.byKey(key);

void main() {
  // ---------------------------------------------------------------- booking

  /// Drives the status screen the way a backend will: the same element, a new
  /// state. Rebuilding the whole widget instead would test nothing, because a
  /// fresh element cannot tell arriving from being opened at.
  late void Function(BookingState) advance;

  Future<void> pumpBooking(
    WidgetTester tester,
    BookingState initial, {
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    var shown = initial;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) {
            advance = (next) => setState(() => shown = next);
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: BookingStatusScreen(
                state: shown,
                category: Categories.plumbing,
                providerName: 'Kabelo Motse',
                providerFirstName: 'Kabelo',
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Every implicitly-animated box on the status card, by duration. The set
  /// having exactly one member **is** the "one event" rule: the accent rule,
  /// the chip plate, its dot and all six step bars move on the same clock.
  Set<Duration> boxDurations(WidgetTester tester) => tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .map((w) => w.duration)
      .toSet();

  /// Records `HapticFeedback.*` platform calls for the life of one test.
  List<String> captureHaptics(WidgetTester tester) {
    final fired = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          fired.add('${call.arguments}');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return fired;
  }

  group('a booking state change reads as one event', () {
    testWidgets('the chip and the step bar move on one clock', (tester) async {
      await pumpBooking(tester, _state('REQUESTED'));

      advance(_state('ACCEPTED'));
      await tester.pump();

      // One duration, not several that happen to be equal today.
      expect(boxDurations(tester), {_stateChange});

      // And it is genuinely the whole card: the accent rule, the plate, the
      // dot and six bars.
      expect(find.byType(AnimatedContainer), findsNWidgets(9));

      await tester.pumpAndSettle();
    });

    testWidgets('the chip re-tones on that same clock, ink included', (
      tester,
    ) async {
      await pumpBooking(tester, _state('REQUESTED'));

      advance(_state('ACCEPTED'));
      await tester.pump();

      // "Chip crossfades pending → ok" is about the tone, not the word:
      // `pending` and `ok` are BookingTones. The label's ink is part of the
      // tone, so it travels with the plate rather than snapping ahead of it.
      // The nearest one above the chip's label. Material puts its own
      // between here and the root, which is why this is anchored to the word
      // rather than looked up by type.
      final ink = tester.widget<AnimatedDefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Accepted'),
              matching: find.byType(AnimatedDefaultTextStyle),
            )
            .first,
      );
      expect(ink.duration, _stateChange);

      // Half-way through, the change is genuinely still happening.
      await tester.pump(_stateChange ~/ 2);
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pumpAndSettle();
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Waiting on Kabelo'), findsNothing);
    });

    testWidgets('opening at a state does not replay reaching it', (
      tester,
    ) async {
      await pumpBooking(tester, _state('ACCEPTED'));

      // Nothing on the card is animating, and nothing is part-way anywhere.
      expect(boxDurations(tester), {Duration.zero});
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('forward progress animates; every ending is instant', () {
    for (final ending in const [
      'DECLINED',
      'EXPIRED',
      'CANCELLED',
      'NO_SHOW',
      'DISPUTED',
    ]) {
      testWidgets('$ending arrives with no travel at all', (tester) async {
        await pumpBooking(tester, _state('REQUESTED'));

        advance(_state(ending));
        await tester.pump();

        // The step bar is gone entirely on an ending, so only the accent
        // rule, the plate and the dot remain — and none of them move.
        expect(boxDurations(tester), {Duration.zero});
        expect(find.byType(BookingStepBar), findsNothing);
      });
    }

    testWidgets('a forward step does travel', (tester) async {
      await pumpBooking(tester, _state('ACCEPTED'));

      advance(_state('IN_PROGRESS'));
      await tester.pump();
      expect(boxDurations(tester), {_stateChange});

      await tester.pumpAndSettle();
    });
  });

  group('the two haptics, and only on arrival', () {
    testWidgets('accepting buzzes once', (tester) async {
      final fired = captureHaptics(tester);
      await pumpBooking(tester, _state('REQUESTED'));

      advance(_state('ACCEPTED'));
      await tester.pumpAndSettle();

      expect(fired, hasLength(1));
    });

    testWidgets('closing the booking buzzes once', (tester) async {
      final fired = captureHaptics(tester);
      await pumpBooking(tester, _state('PENDING_CONFIRMATION'));

      advance(_state('COMPLETED'));
      await tester.pumpAndSettle();

      expect(fired, hasLength(1));
    });

    testWidgets('being opened at accepted buzzes not at all', (tester) async {
      final fired = captureHaptics(tester);
      await pumpBooking(tester, _state('ACCEPTED'));

      expect(fired, isEmpty);
    });

    testWidgets('a decline is not a moment to celebrate', (tester) async {
      final fired = captureHaptics(tester);
      await pumpBooking(tester, _state('REQUESTED'));

      advance(_state('DECLINED'));
      await tester.pumpAndSettle();

      expect(fired, isEmpty);
    });
  });

  group('what enters in place, and when', () {
    EnterInPlace at(WidgetTester tester, String key) =>
        tester.widget<EnterInPlace>(find.byKey(ValueKey(key)));

    testWidgets('the pay panel slides up on arriving at payment', (
      tester,
    ) async {
      await pumpBooking(tester, _state('IN_PROGRESS'));

      advance(_state('AWAITING_PAYMENT'));
      await tester.pump();
      expect(at(tester, 'pay-AWAITING_PAYMENT').enabled, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('and stays put when the screen is opened at it', (
      tester,
    ) async {
      // A separate test rather than a second pump: `pumpWidget` reuses the
      // element tree, so the screen would still be the one opened a moment
      // ago and would report having arrived.
      await pumpBooking(tester, _state('AWAITING_PAYMENT'));

      expect(at(tester, 'pay-AWAITING_PAYMENT').enabled, isFalse);
    });

    testWidgets('the provider row rises when accepted and never again', (
      tester,
    ) async {
      await pumpBooking(tester, _state('REQUESTED'));

      advance(_state('ACCEPTED'));
      await tester.pump();
      expect(at(tester, 'provider-ACCEPTED').enabled, isTrue);
      await tester.pumpAndSettle();

      // The job starting is a long-lived state: "nothing else moves".
      advance(_state('IN_PROGRESS'));
      await tester.pump();
      expect(at(tester, 'provider-IN_PROGRESS').enabled, isFalse);

      await tester.pumpAndSettle();
    });
  });

  group('the rating action arrives after the bar, not with it', () {
    AnimatedSwitcher actionSwitcher(WidgetTester tester) => tester
        .widgetList<AnimatedSwitcher>(find.byType(AnimatedSwitcher))
        // The chip's switcher runs on the state-change clock; the action's
        // does not, which is what makes them two events.
        .firstWhere((s) => s.duration != _stateChange);

    testWidgets('completion sequences the swap 120 ms behind', (tester) async {
      await pumpBooking(tester, _state('PENDING_CONFIRMATION'));

      advance(_state('COMPLETED'));
      await tester.pump();

      final action = actionSwitcher(tester);
      expect(action.duration, _enter + _ratingDelay);
      expect(
        action.switchInCurve,
        isA<Interval>().having(
          (i) => i.begin,
          'starts after the bar completes',
          closeTo(
            _ratingDelay.inMilliseconds /
                (_enter + _ratingDelay).inMilliseconds,
            0.0001,
          ),
        ),
      );

      await tester.pumpAndSettle();
    });

    testWidgets('every other swap is immediate', (tester) async {
      await pumpBooking(tester, _state('ACCEPTED'));

      advance(_state('PENDING_CONFIRMATION'));
      await tester.pump();

      final action = actionSwitcher(tester);
      expect(action.duration, _enter);
      expect(action.switchInCurve, isNot(isA<Interval>()));

      await tester.pumpAndSettle();
    });
  });

  group('reduce motion collapses, it does not shorten', () {
    testWidgets('a state change becomes instant', (tester) async {
      await pumpBooking(tester, _state('REQUESTED'), reduceMotion: true);

      advance(_state('ACCEPTED'));
      await tester.pump();

      expect(boxDurations(tester), {Duration.zero});
      expect(find.text('Waiting on Kabelo'), findsNothing);
      expect(find.text('Accepted'), findsOneWidget);
    });
  });

  // ----------------------------------------------------------------- money

  group('the balance counts only when it changes', () {
    late void Function(Decimal) setBalance;

    Future<void> pumpBalance(WidgetTester tester, Decimal initial) async {
      var shown = initial;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StatefulBuilder(
            builder: (context, setState) {
              setBalance = (next) => setState(() => shown = next);
              return Scaffold(body: Center(child: MoneyCounter(shown)));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('on load it is simply the figure', (tester) async {
      await pumpBalance(tester, Decimal.parse('412.60'));

      expect(find.text('P412.60'), findsOneWidget);
      // Nothing is in flight — a balance is a meter, not a ticker.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a fee posting counts to the new figure', (tester) async {
      await pumpBalance(tester, Decimal.zero);

      setBalance(Decimal.parse('400.00'));
      await tester.pump();
      await tester.pump(_count ~/ 2);

      // Mid-count it is neither figure. That is the whole point of the
      // animation: the money is seen to move.
      expect(find.text('P0.00'), findsNothing);
      expect(find.text('P400.00'), findsNothing);

      await tester.pumpAndSettle();
      // And it lands exactly, never on a rounded approximation.
      expect(find.text('P400.00'), findsOneWidget);
    });
  });
}
