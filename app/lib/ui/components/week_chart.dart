/// The week as seven rounded bars.
///
/// "A provider's week is inherently a chart and we are rendering it as a
/// receipt" — reason 4 of the five the design gave for why the screens read
/// flat. Same numbers, read in one glance.
///
/// It draws with rounded rectangles and no library: nothing here costs
/// performance on the target handsets, which is the constraint the whole
/// surface treatment was chosen under.
///
/// See docs/design-system.md#surface-treatment.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';

class WeekChart extends StatelessWidget {
  const WeekChart({
    super.key,
    required this.values,
    this.todayIndex,
    this.barColor,
    this.mutedBarColor,
    this.height = 44,
  });

  /// Seven values, Monday first. Zero is a real value and draws a stub rather
  /// than nothing — a day with no work is information, not an absence.
  final List<int> values;

  /// The bar to emphasise. Null on a historical week, which has no "today".
  final int? todayIndex;

  final Color? barColor;
  final Color? mutedBarColor;
  final double height;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    assert(values.length == 7, 'A week has seven days.');

    final text = Theme.of(context).textTheme;
    final peak = values.fold<int>(0, (a, b) => b > a ? b : a);

    final on = barColor ?? Brand.white;
    final off = mutedBarColor ?? Brand.white.withValues(alpha: 0.32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: _Bar(
                    // A zero day still shows a stub, so seven days always read
                    // as seven days.
                    fraction: peak == 0 ? 0 : values[i] / peak,
                    color: i == todayIndex ? on : off,
                    maxHeight: height,
                    semanticsLabel:
                        '${_labels[i]}, ${values[i]}'
                        '${i == todayIndex ? ', today' : ''}',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var i = 0; i < _labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(
                      fontSize: 9.5,
                      fontWeight: i == todayIndex
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: i == todayIndex ? on : off,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.color,
    required this.maxHeight,
    required this.semanticsLabel,
  });

  final double fraction;
  final Color color;
  final double maxHeight;
  final String semanticsLabel;

  /// A bar never disappears entirely: a zero day is a fact worth seeing.
  static const _floor = 4.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: _floor + (maxHeight - _floor) * fraction.clamp(0.0, 1.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(3)),
          ),
        ),
      ),
    );
  }
}

/// The delta pill beside the chart: `+2` against last week.
///
/// It states direction as an arrow *and* a sign, so the meaning does not
/// depend on the tint alone.
class DeltaPill extends StatelessWidget {
  const DeltaPill({super.key, required this.delta, this.onDarkSurface = true});

  final int delta;
  final bool onDarkSurface;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    final rising = delta >= 0;
    final fg = onDarkSurface
        ? Brand.white
        : (rising ? palette.creditColor : palette.dangerText);
    final bg = onDarkSurface
        ? Brand.white.withValues(alpha: 0.18)
        : (rising ? palette.verifiedBg : palette.dangerBg);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.x2, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rising ? Icons.trending_up : Icons.trending_down,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: 3),
          Text(
            '${rising ? '+' : ''}$delta',
            style: text.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
