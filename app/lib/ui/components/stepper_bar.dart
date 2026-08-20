/// The segmented stepper, and the toggle row it is grouped with.
///
/// The other two component groups the design **added** in the rebuild. The
/// stepper is four flat bars rather than numbered circles: it says how far
/// through a multi-step flow you are without implying you may jump around,
/// which matters because create-listing and KYC are both forward-only.
///
/// See docs/design-system.md#components.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

class StepperBar extends StatelessWidget {
  const StepperBar({
    super.key,
    required this.stage,
    required this.of,
    this.label,
  });

  /// 1-based. `stage: 2, of: 4` renders two filled bars, then the current
  /// one part-toned, then the rest untouched.
  final int stage;
  final int of;

  /// Defaults to `Stage <n> of <m>`.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: label ?? 'Stage $stage of $of',
          child: Row(
            children: [
              for (var i = 1; i <= of; i++) ...[
                if (i > 1) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= stage
                          ? Brand.deep
                          : (i == stage + 1
                                // The next step is tinted, not blank: it
                                // shows where you are going.
                                ? palette.navPillBg
                                : palette.subtleBg),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 7),
        ExcludeSemantics(
          child: Text(
            label ?? 'Stage $stage of $of',
            style: text.labelSmall?.copyWith(
              fontSize: 10.5,
              color: palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// A labelled switch on its own row — `Listing active`.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.note,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// What flipping it actually does. A toggle that deactivates a listing
  /// should say so before it is flipped, not after.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note!,
                  style: text.labelSmall?.copyWith(
                    fontSize: 10.5,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 11),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
