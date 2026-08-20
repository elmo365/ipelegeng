/// The lockup slot.
///
/// **This is not the logo.** The brand artwork has never been in this
/// repository — see docs/identity.md — so this renders the app's name set in
/// the brand face at the size the design's size rules call for, and nothing
/// else. It is a held slot, not a reconstruction: the real mark carries ripple
/// rings and a blue *i* that cannot be inferred from a canvas that only
/// references the PNG.
///
/// When `assets/brand/` lands, this widget is where the image goes, and every
/// call site already passes the width that decides which cut to use:
///
/// - above 180 — the full lockup, with the tagline
/// - 90 to 180 — the horizontal lockup
/// - below 90 — the mark alone
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../theme/typography.dart';

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, required this.width, this.onDark = true});

  /// Which cut the design's size rules select. Kept as the API even while
  /// nothing reads it visually, so the call sites are already correct.
  final double width;

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // The wordmark is set at roughly a quarter of the lockup's width in the
    // canvas; matching that keeps the splash's vertical rhythm right when the
    // artwork replaces this.
    final size = width * 0.24;

    return Semantics(
      label: 'Ipelege',
      image: true,
      child: ExcludeSemantics(
        child: Text(
          'ipelege',
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: size,
            fontWeight: FontWeight.w700,
            letterSpacing: -size * 0.02,
            color: onDark ? Brand.white : palette.textPrimary,
          ),
        ),
      ),
    );
  }
}
