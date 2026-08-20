/// One ledger entry, as a card.
///
/// VAT is not a detail. It is 14% of the Ipelege commission — never of the
/// customer's payment — it is owed to BURS, and it appears in a filing-ready
/// figure derived from this same journal. So wherever a fee is shown, its VAT
/// is shown **nested under it**, tied by a dashed line and a stub, so a fee and
/// its tax read as one event rather than two lookalike rows. Never round it
/// away, never merge it into a single "fee" number.
///
/// Three shapes, and the differences between them are the rules:
///
/// - a **fee** carries a nested VAT line;
/// - a **reversal** mirrors the deduction line for line — fee back and VAT
///   back, same figures, opposite sign — and its VAT credit gets its own
///   credit-note label, because it cannot vanish from the trail;
/// - a **pending reversal has no amount at all**, because an amount would
///   imply money has already moved. It has not: the balance does not change
///   until a reversal is confirmed.
///
/// See docs/wallet.md and docs/design-system.md#surface-treatment.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';
import 'money_text.dart';
import 'status_chip.dart';
import 'surface.dart';

/// The tax line hanging off a fee.
@immutable
class VatLine {
  const VatLine({required this.amount, required this.label});

  /// `VAT · 14% of P9.60` on a charge; `VAT reversed · credit note` on a
  /// reversal. The reversal wording is not decoration — the credit note is
  /// what keeps the reversed tax auditable.
  const VatLine.charged(Decimal vat, {required String ofFee})
    : this(amount: vat, label: 'VAT · 14% of $ofFee');

  const VatLine.reversed(Decimal vat)
    : this(amount: vat, label: 'VAT reversed · credit note');

  final Decimal amount;
  final String label;
}

class LedgerEntry extends StatelessWidget {
  const LedgerEntry({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.amount,
    this.vat,
    this.pendingLabel,
    this.tone = ChipTone.neutral,
  });

  /// A reversal that has been raised but not decided.
  ///
  /// Deliberately has no amount. The row exists so the provider can see the
  /// claim is live; the balance is untouched and the subtitle says so.
  const LedgerEntry.reversalPending({Key? key, required String reference})
    : this(
        key: key,
        icon: Icons.hourglass_top,
        title: 'Reversal under review',
        subtitle: '$reference · balance unchanged',
        pendingLabel: 'PENDING',
        tone: ChipTone.pending,
      );

  final IconData icon;

  /// `Commission · ride #4471`, `Top-up · Orange Money`.
  final String title;

  /// `Today 09:12 · 8% of P120`. The basis of the charge belongs here: a
  /// figure the provider cannot reconstruct is a figure they will dispute.
  final String subtitle;

  /// Null only when [pendingLabel] is set — see [LedgerEntry.reversalPending].
  final Decimal? amount;

  /// The tax line tied to [amount]. Required on every fee and every reversal
  /// of a fee; absent on a top-up, which is not a fee and carries no VAT.
  final VatLine? vat;

  final String? pendingLabel;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    assert(
      amount != null || pendingLabel != null,
      'A ledger entry shows an amount or says why there is not one.',
    );

    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconPlate(
                icon: icon,
                plate: palette.subtleBg,
                ink: palette.textMuted,
                size: 34,
                iconSize: 18,
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.labelSmall?.copyWith(
                        fontSize: 11.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.x2),
              if (pendingLabel != null)
                StatusChip(label: pendingLabel!, tone: tone)
              else
                MoneyText(amount!, signed: true),
            ],
          ),
          if (vat != null) _VatRow(vat: vat!),
        ],
      ),
    );
  }
}

/// The nested tax line: a dashed tie-line drops from the parent fee and turns
/// into a stub under it, so the eye reads one event with two postings rather
/// than two unrelated rows.
class _VatRow extends StatelessWidget {
  const _VatRow({required this.vat});

  final VatLine vat;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: Space.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            height: 18,
            child: CustomPaint(
              painter: _TieLinePainter(color: palette.divider),
            ),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Text(
              vat.label,
              style: text.labelSmall?.copyWith(
                fontSize: 11.5,
                color: palette.textMuted,
              ),
            ),
          ),
          const SizedBox(width: Space.x2),
          MoneyText(
            vat.amount,
            size: MoneySize.small,
            signed: true,
            color: palette.textMuted,
          ),
        ],
      ),
    );
  }
}

/// Drops from the centre of the icon plate above, then turns right into a
/// short stub. Dashed, because the relationship is a reference rather than a
/// container.
class _TieLinePainter extends CustomPainter {
  const _TieLinePainter({required this.color});

  final Color color;

  static const _dash = 2.5;
  static const _gap = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final x = size.width / 2;
    for (var y = 0.0; y < size.height / 2; y += _dash + _gap) {
      canvas.drawLine(Offset(x, y), Offset(x, y + _dash), paint);
    }

    final y = size.height / 2;
    for (var dx = x; dx < size.width; dx += _dash + _gap) {
      canvas.drawLine(Offset(dx, y), Offset(dx + _dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_TieLinePainter old) => old.color != color;
}
