/// Booking status — the eleven states, one screen.
///
/// "Tap a state above. Payment sits at step 4, before the provider marks
/// complete — the correction the activity diagrams forced. Three states carry
/// provisional copy where the spec is still open."
///
/// The layout is one column of cards, and which cards appear is a property of
/// the state rather than of a flag the call site passes:
///
/// - the **step bar** is hidden on an ending, not drawn empty
/// - the **pay panel** appears only at `AWAITING_PAYMENT`, and it is the one
///   place on the screen that outranks the status card
/// - the **note card** appears only where the design wrote a caveat
///
/// Every string comes from [BookingState], which is verbatim from the canvas.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/booking.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../components/money_text.dart';

class BookingStatusScreen extends StatelessWidget {
  const BookingStatusScreen({
    super.key,
    required this.state,
    required this.category,
    required this.providerName,
    required this.providerFirstName,
  });

  final BookingState state;
  final CategoryToken category;
  final String providerName;
  final String providerFirstName;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(category: category, brightness: brightness),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                children: [
                  _StatusCard(state: state),
                  if (state.showsPayPanel) ...[
                    const SizedBox(height: Space.x3),
                    _PayPanel(providerFirstName: providerFirstName),
                  ],
                  const SizedBox(height: Space.x3),
                  _ProviderRow(
                    category: category,
                    providerName: providerName,
                    brightness: brightness,
                  ),
                  if (state.note != null) ...[
                    const SizedBox(height: Space.x3),
                    _NoteCard(note: state.note!),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, Space.x4, 18, 22),
              child: _Action(state: state, palette: palette),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back, title, and the category as a filled pill in its own hue.
class _Header extends StatelessWidget {
  const _Header({required this.category, required this.brightness});

  final CategoryToken category;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Row(
        children: [
          // The back control is a raised plate here, not a bare glyph in an
          // AppBar — this screen has no app bar, so the affordance has to
          // carry itself.
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: Radii.iconTileAll,
              boxShadow: palette.shadowRow,
            ),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: Radii.iconTileAll,
                  child: Icon(
                    Icons.arrow_back,
                    size: 21,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Text(
              'Your booking',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: category.inkOf(brightness),
              borderRadius: Radii.pillAll,
            ),
            child: Text(
              category.label,
              style: AppTypography.chipLabel.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Brand.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip, step bar, heading, body — with an accent rule down the left edge in
/// the state's own tone, so the state is legible before a word is read.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final BookingState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final dot = state.tone.dot(palette);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: Radii.cardAll,
        boxShadow: palette.shadowCard,
      ),
      child: ClipRRect(
        borderRadius: Radii.cardAll,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: dot),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Chip(state: state),
                      const SizedBox(height: 14),
                      // Hidden on an ending rather than drawn empty: a bar with
                      // no progress on it reads as progress lost.
                      if (!state.isEnding) ...[
                        BookingStepBar(step: state.step),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        state.head,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (state.body.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          state.body,
                          style: text.bodyMedium?.copyWith(
                            fontSize: 13.5,
                            height: 1.55,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.state});

  final BookingState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: state.tone.background(palette),
        borderRadius: Radii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A hue and a glyph-equivalent: the dot never carries the meaning on
          // its own, the label beside it does.
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: state.tone.dot(palette),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Space.x2),
          Text(
            state.chip,
            style: text.labelLarge?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: state.tone.foreground(palette),
            ),
          ),
        ],
      ),
    );
  }
}

/// Six bars. The one you are on is wide; the ones behind it are filled.
class BookingStepBar extends StatelessWidget {
  const BookingStepBar({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      // `container`, so this forms a node of its own. The bars beneath carry no
      // semantics — they are decoration — and without a container the label has
      // nothing to attach to and is dropped.
      container: true,
      label: 'Step $step of ${BookingState.steps}',
      child: Row(
        children: [
          for (var n = 1; n <= BookingState.steps; n++) ...[
            if (n > 1) const SizedBox(width: 6),
            Container(
              width: n == step ? 22 : 8,
              height: 5,
              decoration: BoxDecoration(
                color: n <= step ? Status.success : palette.divider,
                borderRadius: const BorderRadius.all(Radius.circular(3)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The payment moment, and the only element on this screen allowed to outrank
/// the status card.
///
/// It is a gradient hero because it is the one thing that must not be misread:
/// the money goes to the provider, in person, and Ipelege is not in the
/// transaction. Every other screen near a completed booking says the same thing
/// in plain words — this one says it at full size.
class _PayPanel extends StatelessWidget {
  const _PayPanel({required this.providerFirstName});

  final String providerFirstName;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: palette.entryGradient,
        borderRadius: Radii.cardAll,
        boxShadow: palette.shadowHero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PAY ${providerFirstName.toUpperCase()} DIRECTLY, NOW',
              style: AppTypography.sectionLabel.copyWith(
                fontSize: 10,
                letterSpacing: 1,
                color: Brand.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: Space.x2),
            // The amount the customer hands over, in the mono face at hero
            // size — the same treatment the wallet balance gets, because this
            // is the figure the whole screen exists to state.
            MoneyText(
              Decimal.parse('250.00'),
              size: MoneySize.large,
              onDarkSurface: true,
            ),
            const SizedBox(height: Space.x3),
            Row(
              children: [
                const _PayChip(icon: Icons.payments, label: 'Cash'),
                const SizedBox(width: Space.x2),
                const _PayChip(icon: Icons.smartphone, label: 'Orange Money'),
              ],
            ),
            const SizedBox(height: Space.x3),
            Container(
              padding: const EdgeInsets.only(top: Space.x3),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Brand.white.withValues(alpha: 0.16)),
                ),
              ),
              child: Text(
                'In person, while $providerFirstName is still with you. '
                'Ipelege does not process this payment and never holds your '
                'money.',
                style: text.labelSmall?.copyWith(
                  fontSize: 11.5,
                  height: 1.5,
                  color: Brand.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayChip extends StatelessWidget {
  const _PayChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Brand.white.withValues(alpha: 0.16),
        borderRadius: Radii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Brand.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Brand.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.category,
    required this.providerName,
    required this.brightness,
  });

  final CategoryToken category;
  final String providerName;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: Radii.rowAll,
        boxShadow: palette.shadowRow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: category.plateOf(brightness),
                borderRadius: Radii.iconTileAll,
              ),
              child: Icon(
                category.icon,
                size: 20,
                color: category.inkOf(brightness),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    providerName,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 14,
                        color: palette.verifiedText,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Verified · ${category.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.x2),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.selectedBg,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Icon(Icons.call, size: 18, color: palette.accentText),
            ),
          ],
        ),
      ),
    );
  }
}

/// The design's own caveat, where it wrote one. Deliberately quiet — it is a
/// footnote about the rule, not a warning about the booking.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: palette.sectionAlt,
        borderRadius: Radii.rowAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, size: 18, color: palette.textFaint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              style: text.labelSmall?.copyWith(
                fontSize: 11.5,
                height: 1.5,
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One action, drawn three ways. Never two primaries.
class _Action extends StatelessWidget {
  const _Action({required this.state, required this.palette});

  final BookingState state;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (state.actionKind) {
      BookingActionKind.primary => (Brand.deep, Brand.white, Brand.deep),
      BookingActionKind.outline => (
        Colors.transparent,
        palette.accentText,
        palette.accentText,
      ),
      BookingActionKind.ghost => (
        Colors.transparent,
        palette.textMuted,
        palette.inputBorder,
      ),
    };

    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {},
          borderRadius: Radii.buttonAll,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: Touch.min),
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: Radii.buttonAll,
              border: Border.all(color: border, width: 1.5),
            ),
            child: Text(
              state.action,
              style: AppTypography.buttonLabel.copyWith(
                fontSize: 15,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
