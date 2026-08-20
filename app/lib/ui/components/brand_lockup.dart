/// The brand, at the size the design's rules select.
///
/// The canvas gives five cuts of one lockup and a rule for choosing between
/// them:
///
/// - above ~180 px — the full lockup, with the tagline
/// - 90 to 180 — the horizontal lockup
/// - below 90 — the mark alone, where the tagline stops being legible
///
/// **The mark is real artwork. The wordmark is not yet.** `mark.png` is the
/// design's own cut; the wordmark and both lockups exceed the 256 KiB fetch cap
/// and have to be exported from the design side, so the wordmark is set in the
/// brand face here as a placeholder that is labelled as one. See
/// docs/identity.md.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// The mark alone. Real artwork, transparent, so it sits on the splash
/// gradient and on a light page without a plate.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size, this.onDark = true});

  final double size;

  /// The supplied mark is dark ink. On a dark ground it is drawn through a
  /// white filter rather than swapped for a second file — the design ships a
  /// light and a dark cut, and only one of them came through the cap.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/brand/mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    return Semantics(
      label: 'Ipelege',
      image: true,
      child: onDark
          ? ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Brand.white,
                BlendMode.srcIn,
              ),
              child: image,
            )
          : image,
    );
  }
}

/// Mark over wordmark, as the splash stacks them: the mark at half the
/// wordmark's width, then the name.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, required this.width, this.onDark = true});

  /// Which cut the design's size rules select. The mark is drawn at half this,
  /// matching the splash artboard's 88 against 176.
  final double width;

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: width / 2, onDark: onDark),
        SizedBox(height: width * 0.11),
        // Placeholder. `wordmark-dark-new.png` is 1 of 3 cuts blocked by the
        // fetch cap; when it lands this becomes an Image.asset and the
        // letter-spacing hack below goes with it.
        ExcludeSemantics(
          child: Text(
            'ipelege',
            style: TextStyle(
              fontFamily: AppFonts.sans,
              fontSize: width * 0.24,
              fontWeight: FontWeight.w700,
              letterSpacing: -width * 0.005,
              color: onDark ? Brand.white : palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
