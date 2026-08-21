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
import '../../../core/haptics.dart';
import '../../../core/loop_prompt.dart';
import '../../../theme/dimens.dart';
import '../../../theme/motion.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../components/enter_in_place.dart';
import '../../components/loop_prompt_card.dart';
import '../../components/money_text.dart';
import '../../components/screen_header.dart';

class BookingStatusScreen extends StatefulWidget {
  const BookingStatusScreen({
    super.key,
    required this.state,
    required this.category,
    required this.providerName,
    required this.providerFirstName,
    this.onAction,
    this.loopPrompt,
    this.onLoopPrompt,
  });

  final BookingState state;
  final CategoryToken category;
  final String providerName;
  final String providerFirstName;

  /// What the state's single action does.
  ///
  /// Null where the destination does not exist yet, which is most of them:
  /// messaging has no thread UI, the dispute *flow* is undesigned, and
  /// cancelling has no settled rule. An unwired action is inert rather than
  /// pretending — the one that is wired is `COMPLETED` → rate & review.
  final VoidCallback? onAction;

  /// Stage 7's cross-category prompt, already through
  /// [LoopPrompts.decide] at the call site — a pair here means the four
  /// suppression rules have run and none of them fired.
  ///
  /// **This screen still gates it on `COMPLETED` itself.** The moment the
  /// design names is a *finished* job, and a prompt that could surface while a
  /// plumber is still under the sink would be the cross-sell banner stage 7
  /// exists not to be. Two gates on purpose: the caller decides *whether*,
  /// this screen decides *when*.
  final LoopPair? loopPrompt;

  final VoidCallback? onLoopPrompt;

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

/// State exists here for one reason: **motion must distinguish arriving at a
/// state from being opened at one.**
///
/// The design's per-state table is a table of *transitions* — "step 2 fills",
/// "the provider row rises into place", "one medium haptic". Replaying any of
/// that every time the screen is built would turn an explanation into a
/// decoration, and would buzz a phone for news it delivered an hour ago. So
/// every animation on this screen is gated on [_arrived], and a screen opened
/// at `COMPLETED` is simply complete.
class _BookingStatusScreenState extends State<BookingStatusScreen> {
  /// True once the booking has moved under us — set in [didUpdateWidget] and
  /// never cleared.
  ///
  /// Deliberately a latch rather than `state.key != <the one we opened at>`:
  /// the question every animation here asks is "did something just happen",
  /// and comparing against the opening state answers a different one. The two
  /// only diverge on a booking that returns to a state it has already been in,
  /// which no transition currently does and which a comparison would silently
  /// get wrong the day one does.
  bool _arrived = false;

  /// The one state a prompt may appear on.
  bool get _showsLoopPrompt =>
      widget.loopPrompt != null &&
      widget.onLoopPrompt != null &&
      widget.state.key == 'COMPLETED';

  @override
  void didUpdateWidget(covariant BookingStatusScreen old) {
    super.didUpdateWidget(old);
    if (old.state.key == widget.state.key) return;
    _arrived = true;

    // The design marks exactly two states with a haptic — `ACCEPTED` and
    // `COMPLETED` — and calls both "medium". There is no medium: [Haptics]
    // names three uses and no strengths, deliberately, because "a phone that
    // buzzes at everything gets muted". `decision()` is the one it means:
    // its own doc covers "accepting a request; confirming a booking is done",
    // which is these two moments under their other name. Recorded as a
    // vocabulary mismatch in docs/design-deltas.md §17 rather than resolved by
    // adding a fourth haptic the design forbids.
    if (widget.state.key == 'ACCEPTED' || widget.state.key == 'COMPLETED') {
      Haptics.decision();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final brightness = Theme.of(context).brightness;
    final state = widget.state;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Your booking', category: widget.category),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                children: [
                  _StatusCard(state: state, animate: _arrived),
                  if (state.showsPayPanel) ...[
                    const SizedBox(height: Space.x3),
                    // "The pay panel slides up 12 dp" — the highest-attention
                    // moment in the flow, and the only card that arrives.
                    EnterInPlace(
                      key: ValueKey('pay-${state.key}'),
                      enabled: _arrived,
                      child: _PayPanel(
                        providerFirstName: widget.providerFirstName,
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.x3),
                  // "Provider row rises 12 dp into place" — on `ACCEPTED` and
                  // nowhere else. The row is on screen in every state; what
                  // changes at acceptance is that it now names someone who
                  // agreed, and that is the arrival worth marking.
                  EnterInPlace(
                    key: ValueKey('provider-${state.key}'),
                    enabled: _arrived && state.key == 'ACCEPTED',
                    child: _ProviderRow(
                      category: widget.category,
                      providerName: widget.providerName,
                      brightness: brightness,
                    ),
                  ),
                  if (state.note != null) ...[
                    const SizedBox(height: Space.x3),
                    _NoteCard(note: state.note!),
                  ],
                  // Last, and only on a closed booking: everything above is
                  // about this job, and this is the next one.
                  if (_showsLoopPrompt) ...[
                    const SizedBox(height: Space.x4),
                    LoopPromptCard(
                      pair: widget.loopPrompt!,
                      onTap: widget.onLoopPrompt!,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, Space.x4, 18, 22),
              child: _ActionSwitcher(
                state: state,
                palette: palette,
                onPressed: widget.onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip, step bar, heading, body — with an accent rule down the left edge in
/// the state's own tone, so the state is legible before a word is read.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state, required this.animate});

  final BookingState state;

  /// False on the screen's first build — see [_BookingStatusScreenState].
  final bool animate;

  /// **One duration, shared by the chip and the bar.**
  ///
  /// The design does not ask for two 300 ms animations, it asks for the chip
  /// colour and the step bar to animate *together* "so the change reads as one
  /// event" — and two durations, however equal in number, are two events the
  /// moment either one is edited. Passing the value down is the enforcement.
  ///
  /// An ending is instant. "Forward progress animates; every ending is
  /// instant" — a state that reverses or fails must not travel across the
  /// screen as though something were being achieved.
  Duration _change(BuildContext context) => Motion.of(
    context,
    animate && !state.isEnding ? Motion.stateChange : Motion.none,
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final dot = state.tone.dot(palette);
    final change = _change(context);

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
              // The accent rule is the state's tone at full height, so it
              // moves with the chip rather than after it.
              AnimatedContainer(
                duration: change,
                curve: Motion.curve,
                width: 4,
                color: dot,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Chip(state: state, duration: change),
                      const SizedBox(height: 14),
                      // Hidden on an ending rather than drawn empty: a bar with
                      // no progress on it reads as progress lost.
                      if (!state.isEnding) ...[
                        BookingStepBar(step: state.step, duration: change),
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
  const _Chip({required this.state, required this.duration});

  final BookingState state;

  /// Shared with the step bar by [_StatusCard]. See there for why it is passed
  /// rather than looked up.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: duration,
      curve: Motion.curve,
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
          AnimatedContainer(
            duration: duration,
            curve: Motion.curve,
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: state.tone.dot(palette),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Space.x2),
          // "Chip crossfades pending → ok" — `pending` and `ok` are
          // [BookingTone]s, so what the design asks to crossfade is the
          // **tone**: plate, dot and label ink together, on the one clock the
          // step bar is also on. The word itself changes with the frame. It
          // was briefly built as an [AnimatedSwitcher] over the label, which
          // reads as the chip dissolving rather than re-toning — and which
          // does not survive the duration flipping from zero, because the
          // outgoing entry keeps the controller it was created with.
          AnimatedDefaultTextStyle(
            duration: duration,
            curve: Motion.curve,
            style: (text.labelLarge ?? const TextStyle()).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: state.tone.foreground(palette),
            ),
            child: Text(state.chip),
          ),
        ],
      ),
    );
  }
}

/// Six bars. The one you are on is wide; the ones behind it are filled.
class BookingStepBar extends StatelessWidget {
  const BookingStepBar({
    super.key,
    required this.step,
    this.duration = Duration.zero,
  });

  final int step;

  /// How long a step takes to fill. Defaults to instant, so a bar rendered
  /// outside a state change never animates by accident; [_StatusCard] passes
  /// the chip's own duration so the two move as one event.
  final Duration duration;

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
            AnimatedContainer(
              duration: duration,
              curve: Motion.curve,
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

/// The action swaps rather than cutting, and on one state it swaps **late**.
///
/// Two rows of the design's table live here. `PENDING_CONFIRMATION` "swaps to
/// the confirm pair", which is a crossfade. `COMPLETED` is sequenced: the bar
/// completes, *then* the rating action fades in [_ratingDelay] later — two
/// events in that order, not one longer one, because the booking closing and
/// the request to rate it are different things being said.
///
/// Every ending swaps instantly. There is nothing being achieved to animate,
/// and an action that fades in after a decline reads as a consolation.
class _ActionSwitcher extends StatelessWidget {
  const _ActionSwitcher({
    required this.state,
    required this.palette,
    required this.onPressed,
  });

  final BookingState state;
  final AppPalette palette;
  final VoidCallback? onPressed;

  /// The design's own figure. Held as a delay in front of the transition
  /// rather than folded into a longer duration, so the gap survives anyone
  /// later retuning [Motion.enter].
  static const _ratingDelay = Duration(milliseconds: 120);

  @override
  Widget build(BuildContext context) {
    // An ending returns the bare action, which **unmounts the switcher** —
    // and unmounting it is what makes the swap instant. Gating on a zero
    // duration instead would not: an [AnimatedSwitcher]'s outgoing entry
    // animates on the controller it was built with, so a duration that
    // changes between builds applies to the wrong half of the crossfade.
    //
    // There is no first-build guard here for the same structural reason there
    // does not need to be: a switcher never animates its first child.
    if (state.isEnding) {
      return _Action(state: state, palette: palette, onPressed: onPressed);
    }

    final sequenced = state.key == 'COMPLETED';
    final total = sequenced ? Motion.enter + _ratingDelay : Motion.enter;

    return AnimatedSwitcher(
      duration: Motion.of(context, total),
      // The interval is computed from the constant, never from the reduced
      // duration: reduce-motion sends that to zero and a fraction of zero is
      // not a number.
      switchInCurve: sequenced
          ? Interval(
              _ratingDelay.inMilliseconds / total.inMilliseconds,
              1,
              curve: Motion.curve,
            )
          : Motion.curve,
      switchOutCurve: Motion.curveOut,
      child: _Action(
        key: ValueKey(state.key),
        state: state,
        palette: palette,
        onPressed: onPressed,
      ),
    );
  }
}

/// One action, drawn three ways. Never two primaries.
class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.state,
    required this.palette,
    required this.onPressed,
  });

  final BookingState state;
  final AppPalette palette;

  /// Null where the state's destination is not built yet. The label still
  /// says what the action would be — the design wrote one per state and
  /// hiding it would leave the screen a dead end.
  final VoidCallback? onPressed;

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
          onTap: onPressed,
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
