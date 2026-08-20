/// Verification and status chips.
///
/// One widget, four tones. The tone names a meaning, not a colour, and the
/// colours come from the palette — which is what makes the design's rule hold:
/// status pairings are re-toned per theme, never re-hued. Approved never stops
/// being green.
///
/// See docs/design-system.md#components. What the verified badge actually
/// stands behind is an open question in docs/open-questions.md — this widget
/// renders the claim, it does not make it.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

enum ChipTone {
  /// A category the provider is verified in.
  verified(Icons.verified_user),

  /// Submitted, awaiting an admin.
  pending(Icons.hourglass_top),

  /// Nothing wrong — just nothing yet. New on Ipelege, or not uploaded.
  ///
  /// The only tone with no glyph: it marks an absence, and there is no icon
  /// for "nothing has happened yet" that does not read as a warning.
  neutral(null),

  /// Rejected, revoked, expired.
  danger(Icons.error);

  const ChipTone(this.glyph);

  /// Every tone but [neutral] pairs its hue with a glyph, so **status never
  /// depends on colour alone** — the design states this as a rule, and it is
  /// also what makes the chip legible to a colour-blind user and in the
  /// screenshots that end up in a WhatsApp support thread.
  final IconData? glyph;
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.showDot = false,
  });

  /// `Verified · Plumbing`, `New on Ipelege`, `Awaiting review`.
  /// `Verified · Plumbing`. Carries the `verified_user` glyph, not the dot —
  /// the design replaced the dot so the chip states its meaning rather than
  /// relying on the tint.
  const StatusChip.verified(String category, {Key? key})
    : this(key: key, label: 'Verified · $category', tone: ChipTone.verified);

  const StatusChip.newProvider({Key? key})
    : this(key: key, label: 'New on Ipelege');

  final String label;
  final ChipTone tone;

  /// Kept for the rare caller that wants the dot instead of the glyph. The
  /// glyph is the default now: the design replaced the dot with a Material
  /// Symbol per tone so the chip carries meaning, not just emphasis.
  final bool showDot;

  ({Color bg, Color fg, Color dot}) _colours(AppPalette p) => switch (tone) {
    ChipTone.verified => (
      bg: p.verifiedBg,
      fg: p.verifiedText,
      dot: Status.success,
    ),
    ChipTone.pending => (
      bg: p.pendingBg,
      fg: p.pendingText,
      dot: Status.warning,
    ),
    // Still `chipNeutralBg` — but the token itself moved in the restyle, from
    // grey to a tinted blue plate (#E1EDF5 / #5F7387). It reads as
    // information now rather than as a disabled state, which matters because
    // this is the chip a provider with no history wears.
    ChipTone.neutral => (
      bg: p.chipNeutralBg,
      fg: p.chipNeutralText,
      dot: p.textMuted,
    ),
    ChipTone.danger => (bg: p.dangerBg, fg: p.dangerText, dot: Status.danger),
  };

  @override
  Widget build(BuildContext context) {
    final c = _colours(context.palette);

    return Container(
      // 6 x 12, per the components section.
      padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: 6),
      decoration: BoxDecoration(color: c.bg, borderRadius: Radii.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: c.dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ] else if (tone.glyph != null) ...[
            Icon(tone.glyph, size: 15, color: c.fg),
            const SizedBox(width: 6),
          ],
          // Flexible, because the label carries a category name and
          // "Verified · Hairdressing & beauty" is wider than a phone chip.
          // It ellipsizes; it never pushes past its own pill.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.chipLabel.copyWith(color: c.fg),
            ),
          ),
        ],
      ),
    );
  }
}
