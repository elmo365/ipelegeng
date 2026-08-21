/// The cross-category prompt — stage 7's one piece of UI.
///
/// "Which is why the prompt is a real feature and not a cross-sell banner — it
/// is where the breadth thesis either pays off or doesn't."
///
/// That sentence is a constraint on how this is drawn, and the design never
/// drew it (the journey map marks it `gap`). So this is assembled from the
/// vocabulary the app already has rather than from a new one:
///
/// - **The target category's own plate and ink**, exactly as a category tile
///   or a booking row carries them. The prompt is a route into the product,
///   so it wears the product's identity rather than a promotional treatment.
/// - **An accent rule down the left edge**, the same device the booking status
///   card uses to make a state legible before a word is read. Here it marks
///   this as a step rather than an aside — the design's own journey map draws
///   the prompt as the one *filled* chip in a row of pale ones.
/// - **No dismiss control**, because the design specifies suppression as a
///   set of rules evaluated before the prompt is built, not as something the
///   customer has to swat away. If it should not be here,
///   [LoopPrompts.decide] should not have returned it.
///
/// See docs/design-deltas.md §16.
library;

import 'package:flutter/material.dart';

import '../../core/loop_prompt.dart';
import '../../theme/dimens.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

class LoopPromptCard extends StatelessWidget {
  const LoopPromptCard({super.key, required this.pair, required this.onTap});

  final LoopPair pair;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final ink = pair.then.inkOf(brightness);

    return Semantics(
      button: true,
      label: '${pair.headline}. ${pair.body}. ${pair.action}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: Radii.cardAll,
          boxShadow: palette.shadowCard,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: Radii.cardAll,
            child: ClipRRect(
              borderRadius: Radii.cardAll,
              // IntrinsicHeight for the same reason ConsentCard needs it: a
              // stretched Row inside a ListView gets an unbounded cross-axis
              // constraint and will not lay out at all.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: ink),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(Space.x4),
                        child: ExcludeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: pair.then.plateOf(brightness),
                                      borderRadius: Radii.iconTileAll,
                                    ),
                                    child: Icon(
                                      pair.then.icon,
                                      size: 20,
                                      color: ink,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          pair.headline,
                                          style: text.titleMedium?.copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          pair.body,
                                          style: text.bodySmall?.copyWith(
                                            fontSize: 12.5,
                                            height: 1.5,
                                            color: palette.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Space.x3),
                              Row(
                                children: [
                                  Text(
                                    pair.action,
                                    style: AppTypography.buttonLabel.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: palette.accentText,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: palette.accentText,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
