/// Accept and decline, as one component.
///
/// The design's rule, stated on the components sheet: **accept is success
/// green, decline is a danger-toned outline, and never two blue buttons side
/// by side — the pair has to be readable at a glance.** A provider working a
/// request inbox against a countdown is the exact case where two identical
/// buttons produce the wrong tap.
///
/// It ships as a pair rather than two buttons so the rule cannot be half
/// applied at a call site.
///
/// See docs/design-system.md#components.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

class DecisionPair extends StatelessWidget {
  const DecisionPair({
    super.key,
    required this.onAccept,
    required this.onDecline,
    this.acceptLabel = 'Accept',
    this.declineLabel = 'Decline',
  });

  /// Null disables the action — a provider whose balance is short cannot
  /// accept, and the control says so by being disabled rather than by
  /// failing after the tap.
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  final String acceptLabel;
  final String declineLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        // Decline first in source order but visually left: the destructive
        // option is never the one under the thumb's resting position.
        Expanded(
          child: _Button(
            label: declineLabel,
            onTap: onDecline,
            foreground: palette.dangerText,
            background: palette.cardBg,
            border: palette.dangerText,
            shadow: null,
          ),
        ),
        const SizedBox(width: Space.x2),
        Expanded(
          child: _Button(
            label: acceptLabel,
            icon: Icons.check,
            onTap: onAccept,
            foreground: Brand.white,
            background: Status.success,
            border: null,
            shadow: palette.shadowSuccessButton,
          ),
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    required this.foreground,
    required this.background,
    required this.border,
    required this.shadow,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Color foreground;
  final Color background;
  final Color? border;
  final List<BoxShadow>? shadow;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onTap != null;

    final fg = enabled ? foreground : palette.textFaint;
    final bg = enabled ? background : palette.chipNeutralBg;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: Radii.buttonAll,
        boxShadow: enabled ? shadow : null,
      ),
      child: Material(
        color: bg,
        borderRadius: Radii.buttonAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.buttonAll,
          child: Container(
            height: Touch.min,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: Radii.buttonAll,
              border: border != null && enabled
                  ? Border.all(color: border!, width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTypography.buttonLabel.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
