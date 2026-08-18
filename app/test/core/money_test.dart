import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/money.dart';

/// Money formatting gets its own suite because it is user-visible, easy to get
/// wrong, and explicitly must not inherit the device locale. The locale bug
/// only shows up off a Botswana device, so that is where these run.
///
/// See docs/test-strategy.md#money-formatting.
void main() {
  Decimal d(String s) => Decimal.parse(s);

  group('format', () {
    test('zero keeps both decimal places', () {
      expect(Money.format(Decimal.zero), 'P0.00');
    });

    test('a value under one Pula', () {
      expect(Money.format(d('9.6')), 'P9.60');
    });

    test('whole numbers still show two places', () {
      expect(Money.format(d('250')), 'P250.00');
    });

    test('thousands are separated by a space, never a comma', () {
      expect(Money.format(d('1250')), 'P1${Money.groupSeparator}250.00');
      expect(Money.format(d('1250')), isNot(contains(',')));
    });

    test('millions group in threes', () {
      final g = Money.groupSeparator;
      expect(Money.format(d('1234567.89')), 'P1${g}234${g}567.89');
    });

    test('negatives lead with a true minus, before the symbol', () {
      expect(Money.format(d('-1.34')), '−P1.34');
      expect(Money.format(d('-1.34')), isNot(contains('-')));
    });

    test('rounds to two places rather than truncating', () {
      expect(Money.format(d('0.005')), 'P0.01');
      expect(Money.format(d('0.004')), 'P0.00');
    });
  });

  group('formatSigned', () {
    test('a credit leads with a plus', () {
      expect(Money.formatSigned(d('250')), '+P250.00');
    });

    test('a debit leads with a minus', () {
      expect(Money.formatSigned(d('-250')), '−P250.00');
    });

    test('zero carries no sign — nothing moved', () {
      expect(Money.formatSigned(Decimal.zero), 'P0.00');
    });
  });

  group('formatBare', () {
    test('drops the symbol but keeps the shape', () {
      expect(Money.formatBare(d('1250')), '1${Money.groupSeparator}250.00');
      expect(Money.formatBare(d('-1250')), '−1${Money.groupSeparator}250.00');
    });
  });

  group('tryParse', () {
    test('round-trips what format produced', () {
      for (final s in ['0', '9.6', '250', '1250.5', '-1.34', '1234567.89']) {
        final value = d(s);
        expect(Money.tryParse(Money.format(value)), value, reason: s);
      }
    });

    test('accepts what a user actually types', () {
      expect(Money.tryParse('1,250.00'), d('1250'));
      expect(Money.tryParse('1 250'), d('1250'));
      expect(Money.tryParse('P250'), d('250'));
      expect(Money.tryParse('-1.34'), d('-1.34'));
    });

    test('returns null on anything that is not a number', () {
      expect(Money.tryParse(''), isNull);
      expect(Money.tryParse('   '), isNull);
      expect(Money.tryParse('twelve'), isNull);
      expect(Money.tryParse('P'), isNull);
    });
  });

  group('extension', () {
    test('reads the same as the static call', () {
      expect(d('1250').pula, Money.format(d('1250')));
      expect(d('-250').pulaSigned, Money.formatSigned(d('-250')));
      expect(d('250').pulaBare, Money.formatBare(d('250')));
    });
  });
}
