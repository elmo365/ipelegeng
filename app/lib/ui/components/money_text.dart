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
