/// Money on screen.
///
/// Always IBM Plex Mono, always tabular, always through [Money] — so a figure
/// never picks up the device locale and never renders at a precision the
/// ledger does not hold. A screen that formats an amount itself is a bug.
///
/// See docs/design-system.md#type and docs/test-strategy.md#money-formatting.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../theme/motion.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

enum MoneySize {
  /// A balance or hero amount.
  large,

  /// Inside a row or card.
  body,

  /// Metadata, timestamps, secondary figures.
  small,
}

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.size = MoneySize.body,
    this.signed = false,
    this.color,
    this.onDarkSurface = false,
  });

  final Decimal amount;
  final MoneySize size;

  /// A ledger row: `+P250.00` / `−P250.00`. A balance is not signed.
  final bool signed;

  /// Overrides the tone. Left null, a signed credit takes the palette's
  /// credit colour, a signed debit the danger text, and everything else the
  /// primary text colour.
  final Color? color;

  /// The balance card stays the darkest surface in both themes, so text on it
  /// does not follow the theme's text colour.
  final bool onDarkSurface;

  TextStyle get _base => switch (size) {
    MoneySize.large => AppTypography.figureLarge,
    MoneySize.body => AppTypography.figureBody,
    MoneySize.small => AppTypography.figureSmall,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resolved =
        color ??
        (onDarkSurface
            ? Brand.white
            : switch (amount.sign) {
                > 0 when signed => palette.creditColor,
                < 0 when signed => palette.dangerText,
                _ => palette.textPrimary,
              });

    return Text(
      signed ? Money.formatSigned(amount) : Money.format(amount),
      style: _base.copyWith(color: resolved),
      // A figure is read, not spoken as a glyph run: give the screen reader
      // the words rather than the symbol.
      semanticsLabel: _spoken(amount, signed: signed),
    );
  }

  static String _spoken(Decimal amount, {required bool signed}) {
    final abs = amount.abs().toStringAsFixed(2);
    if (!signed || amount.sign == 0) return '$abs Pula';
    return amount.sign < 0 ? 'minus $abs Pula' : 'plus $abs Pula';
  }
}

/// A figure that counts to a new amount.
///
/// **Never on load.** The first build renders [amount] outright; only a change
/// animates, over [Motion.count]. The design gives the reason in its own
/// words — "a figure that animates every time you look at it reads as a live
/// feed" — and the wallet balance is a meter that moves when a fee posts, not
/// a ticker. The rule is enforced structurally rather than by remembering it:
/// the tween begins at the amount the widget was *born* holding, so on the
/// first frame begin and end are equal and there is nothing to animate.
///
/// The interpolated frames go through [Money.format] like every other figure,
/// at the two places the ledger holds. The last frame is the [Decimal] itself,
/// so a counter can never land on a rounded approximation of the balance.
class MoneyCounter extends StatefulWidget {
  const MoneyCounter(
    this.amount, {
    super.key,
    this.size = MoneySize.large,
    this.color,
    this.onDarkSurface = false,
  });

  final Decimal amount;
  final MoneySize size;
  final Color? color;
  final bool onDarkSurface;

  @override
  State<MoneyCounter> createState() => _MoneyCounterState();
}

class _MoneyCounterState extends State<MoneyCounter> {
  /// The amount this widget was mounted with. It is the tween's `begin` and it
  /// is never updated: [TweenAnimationBuilder] takes `begin` only on the first
  /// build and animates from the *current* value thereafter, which is also
  /// what makes an interrupted count resume rather than jump.
  late final double _openedAt = widget.amount.toDouble();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _openedAt, end: widget.amount.toDouble()),
      duration: Motion.of(context, Motion.count),
      curve: Motion.curve,
      builder: (context, value, _) => MoneyText(
        Decimal.parse(value.toStringAsFixed(2)),
        size: widget.size,
        color: widget.color,
        onDarkSurface: widget.onDarkSurface,
      ),
    );
  }
}
