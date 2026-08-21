/// The eleven booking states, and what each one says.
///
/// Every string here is **verbatim from the canvas's `BSTATES` array** — chip,
/// heading, body, action, action kind and note. Nothing is paraphrased and
/// nothing is invented: this is the one screen where copy carries the money
/// rule, and a rewritten sentence is a changed promise.
///
/// Two things the ordering encodes:
///
/// - **Payment is step 4, before "mark complete".** Activity diagram A-2 orders
///   it *service delivered → customer pays the provider directly → provider
///   marks complete → customer confirms → commission posts*. Earlier mockups had
///   the provider marking complete first. [awaitingPayment] sits between
///   [inProgress] and [pendingConfirmation] for that reason, and it is the only
///   state that gets the hero panel.
/// - **Forward progress animates; every ending is instant.** States with
///   [step] `0` are endings — they do not travel across the screen as though
///   something were being achieved. See docs/design-system.md#booking-states.
///
/// Three states carry a [note] the design wrote against itself, flagging copy
/// that is provisional because a product decision has not landed. They ship
/// **with** the note rather than being withheld: a booking that reaches
/// `NO_SHOW` with no screen behind it is worse than one that says what is known
/// and admits what is not.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The five chip tones. `pay` is its own tone because the payment moment is
/// not a status — it is an instruction.
enum BookingTone {
  ok,
  pending,
  bad,
  off,
  pay;

  /// The dot beside the chip label. All three of these convert exactly from
  /// the canvas's OKLCH values: `oklch(0.6 0.13 152)`, `oklch(0.72 0.15 80)`
  /// and `oklch(0.58 0.19 25)`.
  Color dot(AppPalette palette) => switch (this) {
    BookingTone.ok => Status.success,
    BookingTone.pending => Status.warning,
    BookingTone.bad => Status.danger,
    BookingTone.off => palette.navMuted,
    BookingTone.pay => Brand.deep,
  };

  Color background(AppPalette palette) => switch (this) {
    BookingTone.ok => palette.verifiedBg,
    BookingTone.pending => palette.pendingBg,
    BookingTone.bad => palette.dangerBg,
    BookingTone.off => palette.chipNeutralBg,
    BookingTone.pay => palette.infoBg,
  };

  Color foreground(AppPalette palette) => switch (this) {
    BookingTone.ok => palette.verifiedText,
    BookingTone.pending => palette.pendingText,
    BookingTone.bad => palette.dangerText,
    BookingTone.off => palette.chipNeutralText,
    BookingTone.pay => palette.infoTitle,
  };
}

/// How the single action at the foot of the screen is drawn. One primary per
/// state — never two competing.
enum BookingActionKind { primary, outline, ghost }

@immutable
class BookingState {
  const BookingState({
    required this.key,
    required this.chip,
    required this.tone,
    required this.step,
    required this.head,
    required this.body,
    required this.action,
    required this.actionKind,
    this.note,
  });

  /// `REQUESTED`, `AWAITING_PAYMENT` — the server's name for it.
  final String key;

  /// The pill at the top of the status card.
  final String chip;

  final BookingTone tone;

  /// Position on the six-step bar. **Zero means this is an ending** and the
  /// bar is hidden entirely rather than shown empty.
  final int step;

  final String head;

  /// Empty on [awaitingPayment], where the pay panel carries the message
  /// instead and a paragraph above it would compete.
  final String body;

  final String action;
  final BookingActionKind actionKind;

  /// The design's own caveat, shown in an info card. Present on the three
  /// states whose rules are unsettled.
  final String? note;

  bool get isEnding => step == 0;
  bool get showsPayPanel => key == 'AWAITING_PAYMENT';

  /// The six-step bar, in order. Used by the status screen and by nothing else.
  static const steps = 6;

  /// Verbatim from `BSTATES`.
  static const all = <BookingState>[
    BookingState(
      key: 'REQUESTED',
      chip: 'Waiting on Kabelo',
      tone: BookingTone.pending,
      step: 1,
      head: 'Request sent',
      body:
          'Kabelo has until 14:00 today to accept. We will text you either '
          'way.',
      action: 'Cancel request',
      actionKind: BookingActionKind.ghost,
    ),
    BookingState(
      key: 'ACCEPTED',
      chip: 'Accepted',
      tone: BookingTone.ok,
      step: 2,
      head: 'Kabelo accepted',
      body: 'Today at 14:00, at Plot 4521, Block 8. Kabelo has your number.',
      action: 'Message Kabelo',
      actionKind: BookingActionKind.outline,
    ),
    BookingState(
      key: 'IN_PROGRESS',
      chip: 'In progress',
      tone: BookingTone.ok,
      step: 3,
      head: 'Job under way',
      body:
          'Started 14:05. Kabelo will mark it done when the work is finished.',
      action: 'Message Kabelo',
      actionKind: BookingActionKind.outline,
    ),
    // Step 4. The correction the whole phase exists to carry.
    BookingState(
      key: 'AWAITING_PAYMENT',
      chip: 'Pay Kabelo now',
      tone: BookingTone.pay,
      step: 4,
      head: 'Work finished — pay Kabelo',
      body: '',
      action: 'I have paid Kabelo',
      actionKind: BookingActionKind.primary,
    ),
    BookingState(
      key: 'PENDING_CONFIRMATION',
      chip: 'Confirm it is done',
      tone: BookingTone.pending,
      step: 5,
      head: 'Kabelo marked this complete',
      body:
          'Confirm the work was done so this booking can close. If something '
          'is wrong, say so instead.',
      action: 'Yes, it is done',
      actionKind: BookingActionKind.primary,
      note: 'Something is wrong',
    ),
    BookingState(
      key: 'COMPLETED',
      chip: 'Completed',
      tone: BookingTone.ok,
      step: 6,
      head: 'Booking closed',
      body:
          'Paid P250.00 directly to Kabelo. Rate the job so the next customer '
          'knows what to expect.',
      action: 'Rate this booking',
      actionKind: BookingActionKind.outline,
    ),
    BookingState(
      key: 'DECLINED',
      chip: 'Declined',
      tone: BookingTone.bad,
      step: 0,
      head: 'Kabelo declined',
      body:
          'No reason given, and none is required. Five other plumbers cover '
          'Block 8.',
      action: 'See other plumbers',
      actionKind: BookingActionKind.primary,
    ),
    BookingState(
      key: 'EXPIRED',
      chip: 'Expired',
      tone: BookingTone.off,
      step: 0,
      head: 'No answer from Kabelo',
      body: 'The request timed out at 14:00. Nothing was charged to anyone.',
      action: 'See other plumbers',
      actionKind: BookingActionKind.primary,
    ),
    BookingState(
      key: 'CANCELLED',
      chip: 'Cancelled',
      tone: BookingTone.off,
      step: 0,
      head: 'You cancelled this',
      body: 'Cancelled at 11:20, before Kabelo started. Kabelo has been told.',
      action: 'Book again',
      actionKind: BookingActionKind.outline,
      note: 'Cancellation rules are not settled — this copy is provisional',
    ),
    BookingState(
      key: 'NO_SHOW',
      chip: 'No-show',
      tone: BookingTone.bad,
      step: 0,
      head: 'Kabelo did not arrive',
      body:
          'Reported at 15:00. Ipelege reviews repeat no-shows against a '
          "provider's verification.",
      action: 'See other plumbers',
      actionKind: BookingActionKind.primary,
      note: 'No fee rule exists yet — provisional copy',
    ),
    BookingState(
      key: 'DISPUTED',
      chip: 'Under review',
      tone: BookingTone.bad,
      step: 0,
      head: 'You raised a problem',
      body:
          'Ipelege has both sides and will contact you. Payment stays between '
          'you and Kabelo.',
      action: 'Add more detail',
      actionKind: BookingActionKind.outline,
      note: 'Dispute handling is undesigned in the spec — provisional',
    ),
  ];

  static BookingState byKey(String key) =>
      all.firstWhere((b) => b.key == key, orElse: () => all.first);
}
