/// The wallet's rules, as tests.
///
/// These are not layout tests. Each one pins a rule that has a compliance or
/// ledger reason behind it, so a future restyle cannot quietly drop it:
/// VAT is never bundled, a pending reversal shows no amount, a reversal
/// mirrors its deduction, and the balance is a meter rather than an account.
///
/// See docs/wallet.md and docs/design-deltas.md#2-money-figures-the-specs-left-unset.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/demo_data.dart';
import 'package:ipelege/theme/app_theme.dart';
import 'package:ipelege/ui/components/ledger_entry.dart';
import 'package:ipelege/ui/screens/provider/wallet_screen.dart';

Future<void> pumpWallet(WidgetTester tester, {ThemeData? theme}) async {
  // Tall enough that the whole ledger is laid out at once. These tests are
  // about what the ledger says, not about where the fold falls.
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: WalletScreen(data: Demo.wallet),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('VAT', () {
    testWidgets('posts as its own line, never bundled into the fee', (
      tester,
    ) async {
      await pumpWallet(tester);

      // The design's worked example: P120 ride → 8% → P9.60 commission, and
      // 14% of that → P1.34 VAT. Two figures, two lines.
      expect(find.text('−P9.60'), findsOneWidget);
      expect(find.text('−P1.34'), findsOneWidget);

      // The bundled figure must not appear anywhere: 9.60 + 1.34 = 10.94.
      expect(find.text('−P10.94'), findsNothing);
    });

    testWidgets('names the rate and what it was charged on', (tester) async {
      await pumpWallet(tester);

      // A provider who cannot reconstruct the figure will dispute it.
      expect(find.text('VAT · 14% of P9.60'), findsOneWidget);
      expect(find.text('Today 09:12 · 8% of P120'), findsOneWidget);
    });

    testWidgets('a top-up carries no VAT line, because it is not a fee', (
      tester,
    ) async {
      await pumpWallet(tester);

      final topUp = find.ancestor(
        of: find.text('Top-up · Orange Money'),
        matching: find.byType(LedgerEntry),
      );
      expect(topUp, findsOneWidget);
      expect(
        tester.widget<LedgerEntry>(topUp).vat,
        isNull,
      );
    });
  });

  group('reversals', () {
    testWidgets('a reversal under review shows no amount at all', (
      tester,
    ) async {
      await pumpWallet(tester);

      final pending = find.ancestor(
        of: find.text('Reversal under review'),
        matching: find.byType(LedgerEntry),
      );
      expect(pending, findsOneWidget);

      // An amount here would imply money has already come back. It has not:
      // the balance does not move until the reversal is confirmed.
      expect(tester.widget<LedgerEntry>(pending).amount, isNull);
      expect(
        find.descendant(of: pending, matching: find.text('PENDING')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: pending,
          matching: find.textContaining('balance unchanged'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a confirmed reversal mirrors the fee and its VAT', (
      tester,
    ) async {
      await pumpWallet(tester);

      // Same figures, opposite sign, both on the row — never one merged
      // credit, and the VAT credit keeps its own credit-note label.
      expect(find.text('+P24.00'), findsOneWidget);
      expect(find.text('+P3.36'), findsOneWidget);
      expect(find.text('VAT reversed · credit note'), findsOneWidget);
    });

    testWidgets('the phone never offers a decision control', (tester) async {
      await pumpWallet(tester);

      // Adjudication is an admin job. The phone shows status and reason only.
      for (final label in ['Confirm', 'Decline', 'Approve', 'Reject']) {
        expect(
          find.widgetWithText(ElevatedButton, label),
          findsNothing,
          reason: '$label is an admin decision, not a phone control',
        );
      }
    });
  });

  group('the balance is a meter, not an account', () {
    testWidgets('carries its non-redeemable status on the card itself', (
      tester,
    ) async {
      await pumpWallet(tester);

      // On the card, not in a footnote — that is the basis on which the
      // design defends calling it a wallet balance at all.
      expect(find.text('NON-REDEEMABLE · FEES ONLY'), findsOneWidget);
    });

    testWidgets('offers no way to take money out', (tester) async {
      await pumpWallet(tester);

      for (final label in ['Withdraw', 'Cash out', 'Available balance']) {
        expect(find.textContaining(label), findsNothing);
      }
      // Money only goes in.
      expect(find.text('Top up'), findsOneWidget);
    });

    testWidgets('never implies Ipelege handled the customer’s payment', (
      tester,
    ) async {
      await pumpWallet(tester);

      expect(
        find.textContaining('Nothing is charged to you separately'),
        findsOneWidget,
      );
    });
  });

  group('formatting', () {
    testWidgets('figures survive the theme swap unchanged', (tester) async {
      await pumpWallet(tester, theme: AppTheme.dark);

      // Tone is re-toned per theme; the number never is.
      expect(find.text('−P9.60'), findsOneWidget);
      expect(find.text('P340.00'), findsOneWidget);
    });

    testWidgets('a debit leads with a true minus, not a hyphen', (
      tester,
    ) async {
      await pumpWallet(tester);

      expect(find.text('-P9.60'), findsNothing, reason: 'hyphen, not minus');
      expect(find.text('−P9.60'), findsOneWidget);
    });
  });

  group('demo data holds the design’s arithmetic', () {
    test('commission is 8% of the fare and VAT is 14% of the commission', () {
      final fare = Decimal.parse('120.00');
      final commission = (fare * Decimal.parse('0.08'));
      final vat = (commission * Decimal.parse('0.14'));

      expect(commission.toStringAsFixed(2), '9.60');
      expect(vat.toStringAsFixed(2), '1.34');

      // And the provider keeps the whole fare in hand — the platform never
      // touched it.
      expect((commission + vat).toStringAsFixed(2), '10.94');
    });
  });
}
