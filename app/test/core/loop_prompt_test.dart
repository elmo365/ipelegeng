import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/loop_prompt.dart';
import 'package:ipelege/theme/tokens.dart';
import 'package:ipelege/ui/components/category_tile.dart';

/// Stage 7's four states, as tests.
///
/// Three of the four are refusals, and they are the point. Six of nine
/// categories are thin at launch **by plan**, so a prompt that does not check
/// supply would fire into an empty room most of the time — which teaches a
/// customer the app is padding, on the one feature that exists to prove the
/// breadth thesis.
void main() {
  /// Every category healthy, so a test that is about one rule is not silently
  /// passing on a different one.
  const healthy = <String, SupplyStanding>{
    'rides': SupplyStanding.ok,
    'movers': SupplyStanding.ok,
    'rentals': SupplyStanding.ok,
    'beauty': SupplyStanding.ok,
    'plumbing': SupplyStanding.ok,
    'electrical': SupplyStanding.ok,
    'tiling': SupplyStanding.ok,
    'catering': SupplyStanding.ok,
    'hire': SupplyStanding.ok,
  };

  LoopDecision decide({
    CategoryToken after = Categories.rentals,
    LoopMoment moment = LoopMoment.rentalEnquiry,
    Map<String, SupplyStanding> standings = healthy,
    Set<String> booked = const <String>{},
    String? providerJustUsed,
    Set<String> providersInAdjacent = const {'P-1', 'P-2'},
  }) => LoopPrompts.decide(
    LoopContext(
      after: after,
      moment: moment,
      standings: standings,
      bookedCategories: booked,
      providerJustUsed: providerJustUsed,
      providersInAdjacent: providersInAdjacent,
    ),
  );

  group('the pairs are the design\'s, and only its copy is claimed as its', () {
    test(
      'the rental handoff carries the one finished line the design wrote',
      () {
        final pair = LoopPrompts.pairFor(
          Categories.rentals,
          LoopMoment.rentalEnquiry,
        )!;

        expect(pair.then, Categories.movers);
        expect(pair.headline, 'Moving in? Find a truck');
        expect(
          pair.verbatim,
          isTrue,
          reason: 'this is the design\'s own copy and is marked as such',
        );
      },
    );

    test('every other pair is flagged as derived, not passed off as read', () {
      final derived = LoopPrompts.pairs.where((p) => !p.verbatim);
      expect(derived, isNotEmpty);
      for (final pair in derived) {
        expect(
          pair.after.key == 'rentals' &&
              pair.moment == LoopMoment.rentalEnquiry,
          isFalse,
          reason: 'the one verbatim pair is marked derived',
        );
      }
    });

    test('a category offers at most one thing at a time', () {
      // "The adjacent category", singular. A prompt offering three things is a
      // menu, and a menu at the end of a job is a banner.
      final seen = <String>{};
      for (final pair in LoopPrompts.pairs) {
        final slot = '${pair.after.key}@${pair.moment.name}';
        expect(
          seen.add(slot),
          isTrue,
          reason: '$slot has more than one prompt competing for it',
        );
      }
    });

    test('the pairs are exactly the four docs/categories.md lists', () {
      // That table and this list are one statement in two places, the same way
      // docs/build-order.md and build_order_test.dart are. The duplication is
      // what makes drift visible: adding a pair without documenting it fails
      // here, and documenting one without building it fails on the next read.
      expect(
        LoopPrompts.pairs
            .map((p) => '${p.after.key}→${p.then.key}@${p.moment.name}')
            .toList(),
        [
          'rentals→movers@rentalEnquiry',
          'movers→plumbing@bookingCompleted',
          'catering→hire@bookingCompleted',
          'hire→catering@bookingCompleted',
        ],
      );
    });

    test('rides is a target and never a source', () {
      // The connective tissue that moves customers *to* other providers, and
      // the highest-frequency category. A prompt after every ride is exactly
      // the cross-sell banner this is not.
      expect(
        LoopPrompts.pairs.any((p) => p.after.key == Categories.rides.key),
        isFalse,
      );
    });

    test('no pair points a customer at a category that cannot be browsed', () {
      // Rides is dispatch: it has no browse and no listing detail, so a prompt
      // into it has nowhere to land.
      for (final pair in LoopPrompts.pairs) {
        expect(
          pair.then.shape,
          isNot(JourneyShape.dispatch),
          reason: '${pair.after.key} points at a category with no browse',
        );
      }
    });
  });

  group('adjacent category healthy → show it', () {
    test('the rental enquiry offers movers', () {
      final decision = decide();

      expect(decision.shows, isTrue);
      expect(decision.reason, LoopSuppression.none);
      expect(decision.pair!.then, Categories.movers);
    });

    test('a completed movers job offers a plumber', () {
      final decision = decide(
        after: Categories.movers,
        moment: LoopMoment.bookingCompleted,
      );

      expect(decision.shows, isTrue);
      expect(decision.pair!.then, Categories.plumbing);
    });
  });

  group('adjacent category thin → don\'t prompt into an empty room', () {
    test('a thin target suppresses the prompt', () {
      final decision = decide(
        standings: {...healthy, 'movers': SupplyStanding.thin},
      );

      expect(decision.shows, isFalse);
      expect(decision.reason, LoopSuppression.thinSupply);
    });

    test('an unknown target is treated as thin, not as healthy', () {
      // Not knowing whether a room is empty is not a reason to send someone
      // into it. The default has to fail closed.
      final decision = decide(standings: const {});

      expect(decision.shows, isFalse);
      expect(decision.reason, LoopSuppression.thinSupply);
    });
  });

  group('already booked that category → suppress', () {
    test('a customer who has used movers is not sold movers', () {
      final decision = decide(booked: const {'movers'});

      expect(decision.shows, isFalse);
      expect(decision.reason, LoopSuppression.alreadyBooked);
    });

    test('having booked something else does not suppress it', () {
      final decision = decide(booked: const {'beauty', 'catering'});
      expect(decision.shows, isTrue);
    });
  });

  group('provider in the adjacent category is the same person → suppress', () {
    test('the prompt never offers someone back to themselves', () {
      final decision = decide(
        providerJustUsed: 'P-1',
        providersInAdjacent: const {'P-1'},
      );

      expect(decision.shows, isFalse);
      expect(decision.reason, LoopSuppression.sameProvider);
    });

    test('another provider being there is enough to show it', () {
      final decision = decide(
        providerJustUsed: 'P-1',
        providersInAdjacent: const {'P-1', 'P-9'},
      );

      expect(decision.shows, isTrue);
    });

    test('nobody there at all is the same refusal by a shorter route', () {
      final decision = decide(providersInAdjacent: const {});

      expect(decision.shows, isFalse);
      expect(decision.reason, LoopSuppression.sameProvider);
    });
  });

  group('a prompt only fires where the design puts it', () {
    test('the rental handoff does not fire on a completed booking', () {
      final decision = decide(moment: LoopMoment.bookingCompleted);

      expect(decision.shows, isFalse);
      expect(
        decision.reason,
        LoopSuppression.wrongMoment,
        reason: 'rentals has a pair, just not at this moment',
      );
    });

    test('a category that feeds nothing says so distinctly', () {
      // A different reason from wrongMoment on purpose: one is a data
      // question, the other a placement bug, and they are debugged
      // differently.
      final decision = decide(
        after: Categories.beauty,
        moment: LoopMoment.bookingCompleted,
      );

      expect(decision.shows, isFalse);
      expect(decision.reason, LoopSuppression.noPair);
    });
  });

  group('every refusal can say why', () {
    test('each suppression has an explanation fit for a log line', () {
      for (final reason in LoopSuppression.values) {
        expect(reason.explanation, isNotEmpty);
      }
    });
  });
}
