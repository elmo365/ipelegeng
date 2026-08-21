/// The rental enquiry → movers handoff.
///
/// The journey map names two placements for stage 7's prompt: "the prompt
/// belongs at the rental enquiry, and again at a completed movers job". The
/// second is a card at the foot of the booking status screen. This is the
/// first, and it is a **sheet** rather than a card for the same reason the
/// auth gate is one: the enquiry has just happened, there is no next screen to
/// put a card on, and a full-page interstitial would read as the app taking
/// the room away to sell a truck.
///
/// "Books a room → *Moving in? Find a truck* → Movers booking" — the design
/// draws that middle step as the one filled chip in the row. It is the
/// handoff, not an aside, which is why it interrupts at all.
///
/// **Not now dismisses to exactly where they were.** Same rule as the gate:
/// refusing must not cost anything. The prompt is offered once, at the moment
/// it makes sense, and never nags — suppression is decided in
/// [LoopPrompts.decide] before this is ever called.
library;

import 'package:flutter/material.dart';

import '../../../core/loop_prompt.dart';
import '../../../theme/dimens.dart';
import '../../../theme/motion.dart';
import '../../../theme/tokens.dart';
import '../../components/actions.dart';

/// Offer the adjacent category. Returns true if they took it.
Future<bool> offerLoopHandoff(
  BuildContext context, {
  required LoopPair pair,
}) async {
  final taken = await showModalBottomSheet<bool>(
    context: context,
    // The root navigator, for the reason auth_gate.dart records: a tab's
    // Navigator has its pages managed declaratively by go_router, and an
    // imperative route pushed onto it makes the router re-sync on pop — which
    // takes the listing underneath down with the sheet.
    useRootNavigator: true,
    isScrollControlled: true,
    sheetAnimationStyle: AnimationStyle(
      duration: Motion.sheet,
      reverseDuration: Motion.sheetOut,
      curve: Motion.curve,
      reverseCurve: Motion.curveOut,
    ),
    barrierColor: Brand.navy.withValues(alpha: 0.45),
    builder: (context) => _LoopHandoffSheet(pair: pair),
  );

  return taken ?? false;
}

class _LoopHandoffSheet extends StatelessWidget {
  const _LoopHandoffSheet({required this.pair});

  final LoopPair pair;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, Space.x2, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The target category's own plate, not a promotional glyph. This is
          // a route into the product, so it wears the product's identity.
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pair.then.plateOf(brightness),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: Icon(
              pair.then.icon,
              size: 24,
              color: pair.then.inkOf(brightness),
            ),
          ),
          const SizedBox(height: Space.x4),
          Text(
            pair.headline,
            style: text.titleLarge?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Space.x2),
          Text(
            pair.body,
            style: text.bodyMedium?.copyWith(
              height: 1.55,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          PrimaryAction(
            label: pair.action,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          // A full-width target with a real label, the same weight the gate
          // gives "Keep looking around". Declining is a choice, not a cancel.
          QuietAction(
            label: 'Not now',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
