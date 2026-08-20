/// The three row shapes the consent and permission screens are built from.
///
/// All three are cards rather than list rows, which is the design's point: a
/// promise, a consent and an optional channel each deserve their own object.
/// "The three promises are cards rather than a paragraph, and the manual
/// fallback carries equal visual weight."
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';

/// A statement the app is making about itself: "Nothing tracked in the
/// background". Not tappable — it is a promise, not a control.
class PromiseCard extends StatelessWidget {
  const PromiseCard({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: Radii.rowAll,
        boxShadow: palette.shadowRow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(
              icon ?? Icons.check_circle,
              size: 19,
              // The design's own green, not the palette's credit colour: this
              // is a reassurance, not money moving.
              color: Status.success,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(
                  fontSize: 12.5,
                  color: palette.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A consent, with its own checkbox and its own record.
///
/// [required] draws the accent rule down the left edge and labels it REQUIRED.
/// The optional channels are the same card without either, so the difference
/// between "you must" and "you may" is visible before the words are read.
class ConsentCard extends StatelessWidget {
  const ConsentCard({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.footnote,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool required;

  /// `REQUIRED` when [required], otherwise `Optional` — or anything else the
  /// call site needs under the label.
  final String? footnote;

  @override
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final note = footnote ?? (required ? 'REQUIRED' : 'Optional');

    return Semantics(
      checked: value,
      label: '$label. $note',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: Radii.rowAll,
          boxShadow: palette.shadowRow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: Radii.rowAll,
            child: ClipRRect(
              borderRadius: Radii.rowAll,
              // IntrinsicHeight, because the accent rule has to run the full
              // height of a card whose height comes from its own text. A
              // stretched Row alone gets an unbounded cross-axis constraint
              // inside a ListView and fails to lay out at all.
              //
              // The rule cannot be a BoxDecoration border either: Flutter
              // rejects a non-uniform border on a rounded rect, and this card
              // is rounded.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (required)
                      Container(width: 4, color: palette.accentText),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Tick(value: value),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ExcludeSemantics(
                                    child: Text(
                                      label,
                                      style: text.bodyMedium?.copyWith(
                                        fontSize: 12.5,
                                        height: 1.5,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  ExcludeSemantics(
                                    child: Text(
                                      note,
                                      style: text.labelSmall?.copyWith(
                                        fontSize: 11,
                                        fontWeight: required
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: required
                                            ? palette.accentText
                                            : palette.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An optional channel, switched rather than ticked. Each one is recorded
/// separately — the design is explicit that they are not one preference.
class ChannelToggle extends StatelessWidget {
  const ChannelToggle({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: Radii.rowAll,
        boxShadow: palette.shadowRow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: palette.textFaint),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// The 21 dp tick box. Filled brand when set, a hairline outline when not —
/// the same shape either way, so the row does not jump.
class _Tick extends StatelessWidget {
  const _Tick({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 21,
      height: 21,
      margin: const EdgeInsets.only(top: 1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value ? palette.accentText : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(
          color: value ? palette.accentText : palette.inputBorder,
          width: 1.5,
        ),
      ),
      child: value
          ? Icon(
              Icons.check,
              size: 15,
              color: Theme.of(context).brightness == Brightness.light
                  ? Brand.white
                  : Brand.navy,
            )
          : null,
    );
  }
}
