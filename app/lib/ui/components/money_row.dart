/// The money row: a fee with its VAT nested underneath.
///
/// One of three component groups the design **added** in the rebuild — it did
/// not exist in the earlier component set. It is the compact form of the same
/// rule [LedgerEntry] carries at full size: a fee and its tax are one event
/// with two postings, tied by a dashed rule and a stub, never two lookalike
/// rows and never one bundled figure.
///
/// Use this wherever a fee is shown outside the ledger — a booking summary, a
/// completion screen, a listing-fee confirmation. Use [LedgerEntry] in the
/// wallet itself, where each entry is a full card with a status.
///
/// See docs/design-system.md#components and docs/wallet.md.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';
import 'money_text.dart';
import 'surface.dart';

class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.icon,
    required this.label,
    required this.basis,
    required this.amount,
    required this.vatLabel,
    required this.vatAmount,
    this.plate,
    this.ink,
  });

  final IconData icon;

  /// `Commission`.
  final String label;

  /// `8% of P120` — the basis, always. A figure the provider cannot
  /// reconstruct is a figure they will dispute.
  final String basis;

  final Decimal amount;

  /// `VAT · 14%`.
  final String vatLabel;
  final Decimal vatAmount;

  final Color? plate;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return AppRow(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              IconPlate(
                icon: icon,
                plate: plate ?? palette.selectedBg,
                ink: ink ?? palette.accentText,
                size: 34,
                iconSize: 18,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      basis,
                      style: text.labelSmall?.copyWith(
                        fontSize: 10.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.x2),
              MoneyText(amount, signed: true, color: palette.textPrimary),
            ],
          ),
          // The dashed rule and the stub below it are the whole point: they
          // say "this tax belongs to that fee" without repeating the fee.
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.divider, width: 1)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Center(
                    child: Container(
                      width: 2,
                      height: 13,
                      decoration: BoxDecoration(
                        color: palette.divider,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    vatLabel,
                    style: text.labelSmall?.copyWith(
                      fontSize: 11,
                      color: palette.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: Space.x2),
                MoneyText(
                  vatAmount,
                  size: MoneySize.small,
                  signed: true,
                  color: palette.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
