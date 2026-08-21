/// The loop — stage 7, and the ecosystem thesis in code.
///
/// "This is the part the journey can't end without. One acquired user is
/// supposed to produce several transactions across several categories — that's
/// the entire argument for launching with [nine]. … Which is why the prompt is
/// a real feature and not a cross-sell banner — it is where the breadth thesis
/// either pays off or doesn't."
///
/// So the interesting part of this file is not the copy. It is the four
/// conditions under which the prompt **does not appear**, which the journey map
/// states outright:
///
/// > adjacent category healthy → show it · adjacent category thin → don't
/// > prompt into an empty room · already booked that category → suppress ·
/// > provider in the adjacent category is the same person → suppress
///
/// Three of those four are refusals, and they are the whole design. A prompt
/// that fires into a category with four providers in it sends someone to an
/// empty room and teaches them the app is padding — on a product where six of
/// nine categories are thin at launch **by plan**, that is not an edge case,
/// it is the common case. [LoopPrompts.decide] returns the reason it declined
/// as well as the prompt, so a suppression is inspectable rather than a silent
/// null.
///
/// **What this file is not.** The design never drew this prompt: the journey
/// map marks *Cross-category prompt* and *Rental enquiry → movers handoff* as
/// `gap`, which tracks design completeness. What it does give is the trigger
/// points, the pairs, the four states, and exactly one line of finished copy.
/// Everything marked [LoopPair.verbatim] is the design's; everything else is
/// derived from its own adjacency sentences and is flagged as such here and in
/// docs/design-deltas.md.
library;

import 'package:flutter/foundation.dart';

import '../theme/tokens.dart';
import '../ui/components/category_tile.dart';

/// Where in the journey a prompt is allowed to fire.
///
/// Two, because the design names two: "the prompt belongs at the rental
/// enquiry, and again at a completed movers job". It is deliberately not "any
/// time we have a spare card" — a prompt that can appear anywhere is the
/// cross-sell banner this is not supposed to be.
enum LoopMoment {
  /// A tenant has just enquired about a room. The one moment the design gives
  /// finished copy for.
  rentalEnquiry,

  /// A booking reached `COMPLETED`. The design's example is a completed movers
  /// job, but the moment generalises to any category with a pair.
  bookingCompleted,
}

/// Why a prompt did not show. Every value but [LoopSuppression.none] is a
/// refusal, and three of them are the design's own.
enum LoopSuppression {
  /// It showed.
  none,

  /// This category feeds nothing. Not a failure — most do not.
  noPair,

  /// There is a pair, but not at this point in the journey.
  wrongMoment,

  /// "Don't prompt into an empty room."
  thinSupply,

  /// "Already booked that category → suppress."
  alreadyBooked,

  /// "Provider in the adjacent category is the same person → suppress."
  sameProvider;

  /// For the doc comment on a decision, and for test failure messages.
  String get explanation => switch (this) {
    LoopSuppression.none => 'shown',
    LoopSuppression.noPair => 'this category feeds nothing',
    LoopSuppression.wrongMoment => 'not this point in the journey',
    LoopSuppression.thinSupply => 'the adjacent category is thin',
    LoopSuppression.alreadyBooked => 'they have already booked that category',
    LoopSuppression.sameProvider =>
      'the provider there is the one they just used',
  };
}

/// One adjacency: after [after], offer [then].
@immutable
class LoopPair {
  const LoopPair({
    required this.after,
    required this.then,
    required this.moment,
    required this.headline,
    required this.body,
    required this.action,
    this.verbatim = false,
  });

  /// The category just transacted in.
  final CategoryToken after;

  /// The category being offered. Never more than one — the design speaks of
  /// "the adjacent category", singular, and a prompt offering three things is
  /// a menu rather than a next step.
  final CategoryToken then;

  final LoopMoment moment;

  /// "Moving in? Find a truck".
  final String headline;

  /// The line under it, saying why this follows from what just happened.
  final String body;

  /// The label on the way through.
  final String action;

  /// True only where the string is the design's own. See the file comment.
  final bool verbatim;
}

/// Everything [LoopPrompts.decide] needs to answer, gathered at the call site.
///
/// It is a parameter object rather than eight arguments because the four
/// suppression rules each need a different fact, and a call that forgets one
/// silently shows a prompt it should have withheld.
@immutable
class LoopContext {
  const LoopContext({
    required this.after,
    required this.moment,
    required this.standings,
    this.bookedCategories = const <String>{},
    this.providerJustUsed,
    this.providersInAdjacent = const <String>{},
  });

  final CategoryToken after;
  final LoopMoment moment;

  /// Supply per category key. A category missing from this map is treated as
  /// [SupplyStanding.thin] — not knowing whether a room is empty is not a
  /// reason to send someone into it.
  final Map<String, SupplyStanding> standings;

  /// Category keys this customer has already booked in.
  final Set<String> bookedCategories;

  /// The provider on the job just finished, if there was one.
  final String? providerJustUsed;

  /// Provider ids operating in the adjacent category.
  final Set<String> providersInAdjacent;
}

/// The answer, with its reason attached.
@immutable
class LoopDecision {
  const LoopDecision._(this.pair, this.reason);

  const LoopDecision.shown(LoopPair pair) : this._(pair, LoopSuppression.none);
  const LoopDecision.suppressed(LoopSuppression reason) : this._(null, reason);

  /// Null whenever [reason] is not [LoopSuppression.none].
  final LoopPair? pair;
  final LoopSuppression reason;

  bool get shows => pair != null;
}

abstract final class LoopPrompts {
  /// The pairs, from the journey map's own table:
  ///
  /// > **Room taken** → truck that same week → plumber, water delivery once
  /// > moved in
  /// > **Funeral or wedding** → catering · chairs, tents and sound hire ·
  /// > transport for guests
  /// > **Rides** → the connective tissue …
  ///
  /// Four decisions were taken turning that into this list, all recorded in
  /// docs/design-deltas.md §16:
  ///
  /// 1. **Water delivery is not a launch category**, so `movers → plumbing`
  ///    carries the "once moved in" half of that chain alone.
  /// 2. **The event cluster is three categories and the prompt offers one.**
  ///    Catering offers hire and hire offers catering; transport for guests is
  ///    not offered, because rides is dispatch and has no browse to send
  ///    anyone to.
  /// 3. **Rides is a target, never a source.** The design calls it the
  ///    connective tissue that moves customers *to* other providers — it is
  ///    also the highest-frequency category, and a prompt after every ride is
  ///    precisely the banner this is not.
  /// 4. **Only the rentals pair has the design's copy.** The rest is derived.
  static const pairs = <LoopPair>[
    LoopPair(
      after: Categories.rentals,
      then: Categories.movers,
      moment: LoopMoment.rentalEnquiry,
      // The one finished line the design wrote for this feature.
      headline: 'Moving in? Find a truck',
      body:
          'A room taken this week is a move next week. The same verification '
          'covers both.',
      action: 'See movers in Gaborone',
      verbatim: true,
    ),
    LoopPair(
      after: Categories.movers,
      then: Categories.plumbing,
      moment: LoopMoment.bookingCompleted,
      headline: 'Moved in? Get the water running',
      body:
          'A new tenant needs a plumber before anything else in the yard '
          'works.',
      action: 'See plumbers nearby',
    ),
    LoopPair(
      after: Categories.catering,
      then: Categories.hire,
      moment: LoopMoment.bookingCompleted,
      headline: 'Somewhere for everyone to sit',
      body: 'Tents, chairs and sound, from people who do this every weekend.',
      action: 'See what is for hire',
    ),
    LoopPair(
      after: Categories.hire,
      then: Categories.catering,
      moment: LoopMoment.bookingCompleted,
      headline: 'Still need the food?',
      body: 'Home cooks who cater funerals and weddings across Gaborone.',
      action: 'See caterers nearby',
    ),
  ];

  /// The pair for a category at a moment, or null.
  static LoopPair? pairFor(CategoryToken after, LoopMoment moment) {
    for (final pair in pairs) {
      if (pair.after.key == after.key && pair.moment == moment) return pair;
    }
    return null;
  }

  /// The four states, in the order the journey map lists them.
  ///
  /// Order matters for the *reason*, not the outcome: a category that is both
  /// thin and already booked reports thin, because that is the one the product
  /// most needs to see in a log.
  static LoopDecision decide(LoopContext context) {
    final pair = pairFor(context.after, context.moment);
    if (pair == null) {
      // Distinguish "nothing follows this category" from "not here" — the
      // first is a data question, the second a placement bug.
      final elsewhere = pairs.any((p) => p.after.key == context.after.key);
      return LoopDecision.suppressed(
        elsewhere ? LoopSuppression.wrongMoment : LoopSuppression.noPair,
      );
    }

    // "Adjacent category thin → don't prompt into an empty room."
    final standing = context.standings[pair.then.key] ?? SupplyStanding.thin;
    if (standing != SupplyStanding.ok) {
      return const LoopDecision.suppressed(LoopSuppression.thinSupply);
    }

    // "Already booked that category → suppress."
    if (context.bookedCategories.contains(pair.then.key)) {
      return const LoopDecision.suppressed(LoopSuppression.alreadyBooked);
    }

    // "Provider in the adjacent category is the same person → suppress."
    //
    // Read as: the only person over there is the one they just dealt with, so
    // the prompt would be offering them back to themselves. An adjacent
    // category with nobody in it at all is the same refusal by a shorter
    // route.
    final provider = context.providerJustUsed;
    final others = provider == null
        ? context.providersInAdjacent
        : context.providersInAdjacent.where((id) => id != provider);
    if (others.isEmpty) {
      return const LoopDecision.suppressed(LoopSuppression.sameProvider);
    }

    return LoopDecision.shown(pair);
  }
}
