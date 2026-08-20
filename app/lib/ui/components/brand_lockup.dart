/// The brand, at the size the design's own rule selects.
///
/// From the Foundations canvas, verbatim:
///
/// > Use the full lockup above about 180px, the horizontal lockup between 90
/// > and 180, and the mark alone below that, where the tagline stops being
/// > legible.
///
/// [BrandLockup] applies that ladder rather than leaving it to call sites, so
/// "which cut" is a property of the size asked for and cannot be got wrong one
/// screen at a time.
///
/// **Never recolour the artwork.** The mark is a map pin built from a stylised
/// *i*, with ripple rings at its base, in two blues over black; the wordmark
/// has a blue *i*. A `ColorFilter` flattens all of that to a silhouette, which
/// is precisely the damage the canvas records from an earlier set that had been
/// "assembled from different exports". Light and dark are **separate artwork**,
/// not a tint of each other — the dark cut has a white *i* body, not a white
/// version of the black one.
///
/// See docs/identity.md for which cuts are present and which are still blocked
/// by the 256 KiB fetch cap.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// Which cut the design's size rule selects.
enum BrandCut {
  /// Below 90 — the mark alone.
  mark,

  /// 90 to 180 — mark and wordmark side by side.
  horizontal,

  /// Above 180 — the full lockup, with the tagline.
  full;

  static BrandCut forWidth(double width) {
    if (width < 90) return BrandCut.mark;
    if (width <= 180) return BrandCut.horizontal;
    return BrandCut.full;
  }
}

/// The mark alone: `mark-light.png`, the design's own cut.
///
/// Only correct on a **light** ground. The dark cut (`mark-dark.png`) is a
/// different drawing and exceeds the fetch cap, so [onDark] renders the
/// wordmark route instead of tinting this one.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size});

  final double size;

  /// The artwork is 542 x 706 — taller than it is wide, so a square box would
  /// letterbox it and shrink the pin.
  static const aspect = 542 / 706;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ipelege',
      image: true,
      child: Image.asset(
        'assets/brand/mark-light.png',
        height: size,
        width: size * aspect,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

/// Mark and wordmark on one line — `lockup-h-light.png`, 733 x 300.
class BrandLockupHorizontal extends StatelessWidget {
  const BrandLockupHorizontal({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ipelege',
      image: true,
      child: Image.asset(
        'assets/brand/lockup-h-light.png',
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

/// The brand at a given width, with the design's rule choosing the cut.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, required this.width, this.onDark = false});

  final double width;

  /// On a dark ground the light cuts are wrong — the mark's *i* body is black
  /// and would disappear. Until `mark-dark.png` and `wordmark-dark-new.png`
  /// clear the fetch cap, a dark ground gets the name set in the brand face,
  /// which is honest about being type rather than a mangled logo.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (onDark) {
      return ExcludeSemantics(
        child: Semantics(
          label: 'Ipelege',
          child: Text(
            'ipelege',
            style: TextStyle(
              fontFamily: AppFonts.sans,
              fontSize: width * 0.24,
              fontWeight: FontWeight.w700,
              letterSpacing: -width * 0.005,
              color: Brand.white,
            ),
          ),
        ),
      );
    }

    return switch (BrandCut.forWidth(width)) {
      BrandCut.mark => BrandMark(size: width),
      BrandCut.horizontal || BrandCut.full => BrandLockupHorizontal(
        width: width,
      ),
    };
  }
}
