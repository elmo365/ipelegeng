/// Booking request — screen 5, the step between a listing and a status.
///
/// "Direction is a radio card set; the payment moment gets the hero treatment
/// because it is the one thing that must not be misread." The hero belongs to
/// the *status* screen, at `AWAITING_PAYMENT`. What this screen owes the same
/// promise is a plain sentence, said before anything is sent: **nothing is
/// charged now**, the provider quotes back, and the money never passes through
/// Ipelege.
///
/// Three things the layout encodes rather than merely displays:
///
/// - **Direction is a decision, not a filter.** It is a radio card set with a
///   line of explanation under each label, because it changes what the provider
///   is agreeing to — and, one card down, whether a location is asked for at
///   all.
/// - **The location card is conditional on that choice.** `needsLocation` in
///   the canvas: asking a customer for their address when they are the one
///   travelling is a question with no purpose, and an address collected with no
///   purpose is a DPA problem rather than a UX one.
/// - **No price is stated as a total.** The listing's figure is a starting
///   point and it stays labelled as one. A number that looks like a total here
///   is the misreading the whole flow is built to avoid.
///
/// Sending is a **replace**, not a push: the request has been made, and back
/// must not re-enter a form that would send a second one.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../components/actions.dart';
import '../../components/screen_header.dart';
import '../../components/surface.dart';
import 'category_browse_screen.dart';

@immutable
class BookingRequestData {
  const BookingRequestData({
    required this.bookingId,
    required this.providerName,
    required this.providerFirstName,
    required this.category,
    required this.fromPrice,
    required this.offered,
    required this.customerLocation,
    required this.when,
    this.verified = true,
  });

  /// The booking this request becomes. Without a backend it is fixed, which is
  /// also why sending can go straight to a status screen.
  final String bookingId;

  final String providerName;

  /// "Kabelo". The sentence about payment names a person, not a trading name.
  final String providerFirstName;

  final CategoryToken category;

  /// The listing's starting figure. Shown as `from`, never as a total.
  final Decimal fromPrice;

  /// What the *listing* offers. Decides which option starts selected.
  ///
  /// The canvas draws both radio cards unconditionally, even on a listing its
  /// own browse card labels "Comes to you · Block 8". That is an inconsistency
  /// in the design rather than a rule, and it is left as the design has it:
  /// both options render, and narrowing them to what a provider actually
  /// offers is a decision for when listings carry real direction data.
  final ServiceDirection offered;

  /// Sent with the request when the provider is the one travelling. Never
  /// collected otherwise.
  final String customerLocation;

  /// `Today, 14:00`. A string, because the canvas draws no picker — scheduling
  /// granularity per category is still open (docs/booking.md).
  final String when;

  final bool verified;

  /// Where the radio set starts. A listing offering `either` has no preference
  /// to honour, so it opens on the common case.
  ServiceDirection get initialDirection => offered == ServiceDirection.either
      ? ServiceDirection.comesToYou
      : offered;
}

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key, required this.data});

  final BookingRequestData data;

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  late ServiceDirection _direction = widget.data.initialDirection;

  /// The canvas's `needsLocation`.
  bool get _needsLocation => _direction == ServiceDirection.comesToYou;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Request booking', category: data.category),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                children: [
                  _ProviderRow(data: data),
                  const SizedBox(height: 11),
                  _DirectionCard(
                    selected: _direction,
                    onChanged: (d) => setState(() => _direction = d),
                  ),
                  if (_needsLocation) ...[
                    const SizedBox(height: 11),
                    _DetailCard(
                      label: 'YOUR LOCATION',
                      icon: Icons.location_on,
                      value: data.customerLocation,
                    ),
                  ],
                  const SizedBox(height: 11),
                  _DetailCard(
                    label: 'WHEN',
                    icon: Icons.schedule,
                    value: data.when,
                  ),
                  const SizedBox(height: 11),
                  _NothingChargedNote(
                    providerFirstName: data.providerFirstName,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, Space.x4, 18, 22),
              child: PrimaryAction(
                label: 'Send booking request',
                // Replace. The request exists now, and a back gesture that
                // re-entered this form could send a second one.
                onPressed: () =>
                    context.goReplacing(Routes.bookingOf(data.bookingId)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Who this is for, and what their listing said the work starts at.
class _ProviderRow extends StatelessWidget {
  const _ProviderRow({required this.data});

  final BookingRequestData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return AppRow(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconPlate.category(data.category, brightness, size: 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.providerName,
                  style: text.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  data.verified
                      ? 'Verified · from ${Money.format(data.fromPrice)}'
                      : 'From ${Money.format(data.fromPrice)}',
                  style: text.labelSmall?.copyWith(
                    fontSize: 11,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The radio card set. Raised above the cards under it, because it is the one
/// thing on this screen the customer actually decides.
class _DirectionCard extends StatelessWidget {
  const _DirectionCard({required this.selected, required this.onChanged});

  final ServiceDirection selected;
  final ValueChanged<ServiceDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SERVICE DIRECTION',
            style: AppTypography.sectionLabel.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          for (final option in ServiceDirection.choices) ...[
            if (option != ServiceDirection.choices.first)
              const SizedBox(height: Space.x2),
            _DirectionOption(
              option: option,
              selected: option == selected,
              onTap: () => onChanged(option),
            ),
          ],
        ],
      ),
    );
  }
}

class _DirectionOption extends StatelessWidget {
  const _DirectionOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ServiceDirection option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Semantics(
      // A radio, not a checkbox and not a button: picking one un-picks the
      // other, and a screen reader should say so rather than announcing two
      // independent controls.
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: '${option.label}. ${option.sub}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.buttonAll,
          child: Container(
            constraints: const BoxConstraints(minHeight: Touch.min),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: selected ? palette.selectedBg : palette.cardBg,
              borderRadius: Radii.buttonAll,
              border: Border.all(
                color: selected ? palette.accentText : palette.inputBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                _Dot(selected: selected),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          option.label,
                          style: text.bodyMedium?.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? palette.accentText
                                : palette.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      ExcludeSemantics(
                        child: Text(
                          option.sub,
                          style: text.labelSmall?.copyWith(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 18 dp ring. Filled brand when set, a hairline ring when not — the same
/// shape either way, so the card does not shift as the choice moves.
class _Dot extends StatelessWidget {
  const _Dot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: selected ? palette.accentText : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? palette.accentText : palette.inputBorder,
          width: 2,
        ),
      ),
    );
  }
}

/// A stated fact about the request: where, or when. Read-only by design — the
/// canvas draws no picker on either, and scheduling granularity per category
/// is still an open question.
class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return AppRow(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.sectionLabel.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            constraints: const BoxConstraints(minHeight: Touch.min),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: Radii.inputAll,
              border: Border.all(color: palette.inputBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: palette.accentText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The sentence the whole screen is accountable to.
///
/// Verbatim from the canvas but for one word: it writes "you pay **him**
/// directly", of a provider named Kabelo. This is a template rendered for
/// every provider on the platform, so the pronoun is `them`. Recorded in
/// docs/design-deltas.md.
class _NothingChargedNote extends StatelessWidget {
  const _NothingChargedNote({required this.providerFirstName});

  final String providerFirstName;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: palette.selectedBg,
        borderRadius: Radii.rowAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.payments, size: 18, color: palette.accentText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$providerFirstName quotes you back. Nothing is charged now, '
              'and you pay them directly.',
              style: text.labelSmall?.copyWith(
                fontSize: 11.5,
                height: 1.5,
                color: palette.accentText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
