/// B2 · Wallet.
///
/// One wallet per provider, not one per category — that is the ledger's grain,
/// and per-category reporting rides on the journal rather than on splitting the
/// account. See docs/wallet.md.
///
/// The rules this screen has to hold, all of them load-bearing:
///
/// - **A meter, not an account.** No withdraw control, no "available balance",
///   and the non-redeemable disclaimer sits *on the balance card* rather than
///   in a footnote.
/// - **The app never implies it took the customer's money.** Payment happens
///   directly between customer and provider; the copy says so where a fee is
///   shown, not buried in terms.
/// - **VAT is never bundled.** Every deduction posts as two lines, fee and
///   VAT, nested — see [LedgerEntry].
/// - **A cancellation never refunds itself.** The balance does not move until a
///   reversal is confirmed, so a pending reversal shows with no amount.
/// - **Adjudication is not on the phone.** This screen shows status and reason;
///   it never offers a decision control.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/ledger_entry.dart';
import '../../components/money_text.dart';
import '../../components/surface.dart';

/// One row of the ledger, as this screen needs it.
@immutable
class LedgerRow {
  const LedgerRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.amount,
    this.vat,
    this.pending = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Decimal? amount;
  final VatLine? vat;
  final bool pending;
}

@immutable
class WalletData {
  const WalletData({required this.balance, required this.activity});

  final Decimal balance;
  final List<LedgerRow> activity;
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key, required this.data});

  final WalletData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.x2,
            Space.gutter,
            Space.x8,
          ),
          children: [
            _BalanceCard(balance: data.balance),
            const SizedBox(height: Space.x5),
            Row(
              children: [
                Icon(Icons.filter_list, size: 16, color: palette.textMuted),
                const SizedBox(width: 6),
                Text(
                  'RECENT ACTIVITY',
                  style: text.labelSmall?.copyWith(
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: palette.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  'All',
                  style: text.labelLarge?.copyWith(color: palette.accentText),
                ),
              ],
            ),
            const SizedBox(height: Space.x3),
            for (final row in data.activity) ...[
              if (row.pending)
                LedgerEntry.reversalPending(reference: row.subtitle)
              else
                LedgerEntry(
                  icon: row.icon,
                  title: row.title,
                  subtitle: row.subtitle,
                  amount: row.amount,
                  vat: row.vat,
                ),
              const SizedBox(height: Space.x3),
            ],
          ],
        ),
      ),
    );
  }
}

/// The balance card. It stays the darkest surface on screen in both themes —
/// one of the three things the design holds constant across the light/dark
/// swap.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final Decimal balance;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return HeroSurface(
      gradient: palette.balanceCardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WALLET BALANCE',
            style: text.labelSmall?.copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: Brand.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: Space.x2),
          // Counts to the new figure over 400 ms when a fee posts or a
          // reversal is confirmed, and does nothing at all on load — see
          // [MoneyCounter]. "Money changing deserves to be noticed"; money
          // sitting still does not.
          MoneyCounter(balance, onDarkSurface: true),
          const SizedBox(height: Space.x3),
          // The disclaimer is on the card, not in a footnote. This is the
          // whole basis on which the design defends the word "wallet".
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 14,
                color: Brand.white.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 5),
              // Flexible, not fixed: at 360 dp with the letter-spacing this
              // label is within a few pixels of the gutter, and it must never
              // be the thing that clips — it is the disclaimer.
              Flexible(
                child: Text(
                  'NON-REDEEMABLE · FEES ONLY',
                  style: text.labelSmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: Brand.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.x2),
          Text(
            'Every Ipelege fee comes out of here — commission and listing '
            'fees, each plus 14% VAT. Nothing is charged to you separately.',
            style: text.bodySmall?.copyWith(
              color: Brand.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: Space.x4),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Brand.white,
              borderRadius: Radii.buttonAll,
              child: InkWell(
                onTap: () {},
                borderRadius: Radii.buttonAll,
                child: Container(
                  height: Touch.min,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 18, color: Brand.deep),
                      const SizedBox(width: 6),
                      Text(
                        'Top up',
                        style: text.labelLarge?.copyWith(
                          fontSize: 14,
                          color: Brand.deep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
