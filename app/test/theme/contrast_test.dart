/// Contrast floors, in both palettes.
///
/// Phase 0's colour gate ran on a handset on 2026-08-21 and found three
/// interactive controls drawn in hairline tokens: the rating stars in
/// `divider`, the consent screen's **required** tick and the notification
/// switches in `inputBorder`. On the dark card that is 1.4:1 and 1.8:1 — five
/// stars you cannot see are not a rating input, and a consent control nobody
/// can find on a screen the DPA requires is worse than a cosmetic bug.
///
/// The fix was a token, [AppPalette.controlOutline], and a token can be
/// "tidied" back to `divider` by anyone who reads it as a border. This is what
/// stops that. It is arithmetic on the palette rather than a screenshot, so it
/// runs in milliseconds and cannot drift the way a comparison by eye does.
///
/// **The floor is WCAG 1.4.11's 3:1 for non-text UI components**, not 4.5:1 —
/// these are shapes, not prose. Text tokens are held to their own floors
/// below.
///
/// See docs/design-deltas.md §18 and docs/design-system.md#colour.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/theme/tokens.dart';

/// Relative luminance, per WCAG 2.x.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

/// The WCAG contrast ratio between two opaque colours, 1:1 to 21:1.
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// Both palettes, by the name a failure should print.
const _palettes = <String, AppPalette>{
  'light': AppPalette.light,
  'dark': AppPalette.dark,
};

void main() {
  group('an interactive control is visible at rest', () {
    // 1.4.11. A control's resting outline against whatever it sits on.
    const floor = 3.0;

    for (final entry in _palettes.entries) {
      final name = entry.key;
      final palette = entry.value;

      test('$name · the outline clears 3:1 on a card', () {
        expect(
          contrast(palette.controlOutline, palette.cardBg),
          greaterThanOrEqualTo(floor),
          reason:
              'An empty rating star and an unticked consent box are drawn in '
              'controlOutline on cardBg. Below 3:1 the control is invisible '
              'and the screen has no visible input.',
        );
      });

      test('$name · and on the page behind a card', () {
        // The switches on the consent screen sit on `sectionAlt` rows, and a
        // control can land directly on the page in a future screen.
        for (final surface in {palette.screenBg, palette.screenBg2}) {
          expect(
            contrast(palette.controlOutline, surface),
            greaterThanOrEqualTo(floor),
            reason: 'controlOutline is unreadable on a page background.',
          );
        }
      });

      test('$name · a chosen star still outranks an empty one', () {
        // Legible is not the whole rule: the point of the control is the
        // *difference* between chosen and not. If the two ever converge, the
        // rating reads as five identical stars.
        expect(
          contrast(palette.accentText, palette.controlOutline),
          greaterThan(1.4),
          reason:
              'The filled and empty star must not be the same weight of mark.',
        );
      });
    }

    test('no palette quietly reuses a hairline for a control', () {
      // The regression this whole file exists to catch, stated directly.
      for (final entry in _palettes.entries) {
        final p = entry.value;
        expect(
          p.controlOutline,
          isNot(p.divider),
          reason: '${entry.key}: controlOutline has been set back to divider.',
        );
        expect(
          p.controlOutline,
          isNot(p.inputBorder),
          reason:
              '${entry.key}: controlOutline has been set back to inputBorder.',
        );
      }
    });
  });

  group('the hairline tokens stay hairlines', () {
    // The other half of the rule. If someone "fixes" contrast by darkening
    // `divider`, every card on every screen grows a visible border and the
    // design's whole no-borders-only-shadow treatment goes with it.
    for (final entry in _palettes.entries) {
      test('${entry.key} · divider is still subtle', () {
        expect(
          contrast(entry.value.divider, entry.value.cardBg),
          lessThan(3.0),
          reason:
              'divider has been pushed up to control weight. The design '
              'removed grey borders in favour of tinted shadow — see '
              'AppPalette.cardBorder.',
        );
      });
    }
  });

  group('text clears its own floors', () {
    for (final entry in _palettes.entries) {
      final name = entry.key;
      final p = entry.value;

      test('$name · body text on a card is 4.5:1', () {
        expect(contrast(p.textPrimary, p.cardBg), greaterThanOrEqualTo(4.5));
      });

      test('$name · muted text on a card is 4.5:1', () {
        // Muted carries real sentences — a booking's body copy, a provider's
        // category line — not decoration, so it takes the full text floor.
        expect(contrast(p.textMuted, p.cardBg), greaterThanOrEqualTo(4.5));
      });

      test('$name · the accent is legible as a link and a label', () {
        expect(contrast(p.accentText, p.cardBg), greaterThanOrEqualTo(4.5));
      });
    }
  });
}
