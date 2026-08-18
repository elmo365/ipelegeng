/// Pula formatting.
///
/// Money is [Decimal], never `double`, and the format is set explicitly here
/// rather than inherited from the device locale — a handset set to en-US would
/// otherwise render `P1,250.00` with a comma, and one set to fr-FR would
/// render `1 250,00 P`. Neither is what a Botswana user reads.
///
/// The rules, from docs/test-strategy.md#money-formatting:
///
/// - symbol `P`, immediately before the digits, no space
/// - always two decimal places, including on whole numbers
/// - thousands separator is a **space**, not a comma
/// - negative amounts lead with a true minus sign, `−`, not a hyphen
library;

import 'package:decimal/decimal.dart';

abstract final class Money {
  static const symbol = 'P';

  /// A true minus (U+2212). It aligns with the figure width in IBM Plex Mono;
  /// a hyphen does not.
  static const minus = '−';

  /// The thousands separator: a narrow no-break space (U+202F), so a wrapping
  /// line can never break `P1 250.00` in half.
  static const groupSeparator = ' ';

  static const decimalSeparator = '.';

  /// `P1 250.00`, `P0.00`, `−P1.34`.
  ///
  /// The sign leads the symbol: the amount is negative, not the currency.
  static String format(Decimal amount) {
    final negative = amount.sign < 0;
    final digits = _twoPlaces(negative ? -amount : amount);
    final sign = negative ? minus : '';
    return '$sign$symbol$digits';
  }

  /// The same, without the `P`. For a column that carries the symbol in its
  /// header, or a field the user is typing into.
  static String formatBare(Decimal amount) {
    final negative = amount.sign < 0;
    final digits = _twoPlaces(negative ? -amount : amount);
    return negative ? '$minus$digits' : digits;
  }

  /// A signed amount for a ledger row: `+P250.00` / `−P250.00`.
  ///
  /// Zero carries no sign — there is nothing to have moved.
  static String formatSigned(Decimal amount) {
    if (amount.sign == 0) return format(amount);
    final sign = amount.sign < 0 ? minus : '+';
    return '$sign$symbol${_twoPlaces(amount.abs())}';
  }

  /// Parses what [format] or [formatBare] produced, plus what a user is
  /// likely to type: a plain hyphen, a comma or ordinary space for grouping,
  /// a leading `P`. Returns null when the text is not a number.
  static Decimal? tryParse(String text) {
    final cleaned = text
        .replaceAll(minus, '-')
        .replaceAll(symbol, '')
        .replaceAll(groupSeparator, '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    if (cleaned.isEmpty) return null;
    return Decimal.tryParse(cleaned);
  }

  /// Two decimal places always, grouped in threes.
  static String _twoPlaces(Decimal amount) {
    // Round half-up at two places. Money is never displayed at a precision the
    // ledger does not hold.
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    return '${_group(parts[0])}$decimalSeparator${parts[1]}';
  }

  static String _group(String whole) {
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(groupSeparator);
      buffer.write(whole[i]);
    }
    return buffer.toString();
  }
}

/// `Decimal.zero.pula` reads better at a call site than `Money.format(x)`.
extension PulaFormat on Decimal {
  String get pula => Money.format(this);
  String get pulaSigned => Money.formatSigned(this);
  String get pulaBare => Money.formatBare(this);
}
