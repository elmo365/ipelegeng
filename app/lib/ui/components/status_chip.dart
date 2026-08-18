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
  verified,

  /// Submitted, awaiting an admin.
  pending,

  /// Nothing wrong — just nothing yet. New on Ipelege, or not uploaded.
  neutral,

  /// Rejected, revoked, expired.
  danger,
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.showDot = false,
  });

  /// `Verified · Plumbing`, `New on Ipelege`, `Awaiting review`.
  const StatusChip.verified(String category, {Key? key})
    : this(
        key: key,
        label: 'Verified · $category',
        tone: ChipTone.verified,
        showDot: true,
      );

  const StatusChip.newProvider({Key? key})
    : this(key: key, label: 'New on Ipelege');

  final String label;
  final ChipTone tone;

  /// The 14 px status dot. Carried by the verified chip so the meaning
  /// survives for a user who cannot separate the two background tints.
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
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x3,
        vertical: Space.x1 + 2,
      ),
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
          ],
          Text(label, style: AppTypography.chipLabel.copyWith(color: c.fg)),
        ],
      ),
    );
  }
}
