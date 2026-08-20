/// The motion table, enforced.
///
/// Every duration here is stated in part 4 of the split canvas and repeated in
/// `docs/design-system.md#motion`. They are asserted rather than trusted
/// because this is exactly where the drift happened: the resync appended the
/// recovered table to the doc instead of replacing the stale block, the stale
/// block carried a `Motion` class listing, and the code was written from it.
///
/// Every value below was wrong until 2026-08-20. If one of these fails, check
/// the canvas before changing the expectation — the number in the test is the
/// design's, not a preference.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/theme/motion.dart';

void main() {
  group('durations match the canvas transition table', () {
    test('a tab change is 120 ms — siblings, not a journey', () {
      expect(Motion.tabChange, const Duration(milliseconds: 120));
    });

    test('a push is 220 ms with a 16 dp parallax on the outgoing screen', () {
      expect(Motion.page, const Duration(milliseconds: 220));
      expect(Motion.pushParallax, 16.0);
    });

    test('a bottom sheet is 260 in and 180 out — not one duration', () {
      expect(Motion.sheet, const Duration(milliseconds: 260));
      expect(Motion.sheetOut, const Duration(milliseconds: 180));
      expect(
        Motion.sheet,
        isNot(Motion.sheetOut),
        reason: 'ease-out on entry, ease-in on dismissal — they differ',
      );
    });

    test('a booking state change is 300 ms', () {
      expect(Motion.stateChange, const Duration(milliseconds: 300));
    });

    test('the wallet balance counts for 400 ms, not 600', () {
      expect(Motion.count, const Duration(milliseconds: 400));
    });

    test('anything entering in place travels 12 dp at most', () {
      expect(Motion.travel, 12.0);
    });
  });

  group('reduce-motion', () {
    testWidgets('collapses to zero rather than shortening', (tester) async {
      // A battery decision on these handsets, not an accessibility edge case.
      late Duration reduced;
      late Duration normal;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              reduced = Motion.of(context, Motion.page);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              normal = Motion.of(context, Motion.page);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(reduced, Duration.zero);
      expect(normal, Motion.page);
    });
  });
}
