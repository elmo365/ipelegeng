/// The two full-width actions the entry flow uses.
///
/// The design's secondary here is **not** the outlined button in the theme.
/// On the unlock and location screens it is a raised card carrying an accent
/// label — "a full card of equal weight, not fine print", because a refusal
/// path that looks like fine print is a refusal path nobody finds. It takes a
/// shadow and no border, which is the surface rule.
///
/// Both are 48 dp minimum and stretch to the column, so a decision never
/// depends on hitting a narrow target.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// Brand fill, white label, a shadow in its own hue.
class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;

  /// Null disables it. The OTP screen leans on this: "Verify & continue" is
  /// dead until the code is complete and the required consent is ticked.
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: Space.x4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19),
              const SizedBox(width: Space.x2),
            ],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

/// Surface fill, accent label, a card shadow and no border.
class SoftAction extends StatelessWidget {
  const SoftAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: Radii.buttonAll,
        boxShadow: palette.shadowRow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: Radii.buttonAll,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: Touch.min),
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: palette.accentText),
                  const SizedBox(width: Space.x2),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.buttonLabel.copyWith(
                      fontSize: 14.5,
                      color: palette.accentText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The centred line under the primary action: "Already have an account? Sign
/// in". Plain text with one tappable span, not a button — it is a route out,
/// not a competing decision.
class InlineLink extends StatelessWidget {
  const InlineLink({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
    this.onDark = false,
  });

  final String prefix;
  final String action;
  final VoidCallback onTap;

  /// The splash sets this: the line sits on the gradient, not on a page.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '$prefix $action',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.buttonAll,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: Touch.min),
            alignment: Alignment.center,
            child: Text.rich(
              TextSpan(
                text: prefix.isEmpty ? '' : '$prefix ',
                children: [
                  TextSpan(
                    text: action,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: onDark ? Brand.sky : palette.accentText,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: onDark
                    ? Brand.white.withValues(alpha: 0.7)
                    : palette.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
