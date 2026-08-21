/// Rate & review — screen 8, the last thing the customer journey asks for.
///
/// "Stars are Material glyphs on the booking card itself, and the copy says why
/// the rating matters for a provider with no history."
///
/// That subtitle is the whole argument of the screen, and it is the same
/// argument the listing detail makes from the other side: **a new provider has
/// no review history, and the product refuses to fabricate one.** Listing
/// detail states the zero rather than inventing a rating; this screen explains
/// why the customer's one rating is worth giving. Ratings working *too well* —
/// zero-review providers never getting a first booking — is one of the failures
/// this product is built against, so the ask is made plainly and the refusal is
/// made easy.
///
/// Three rules the screen holds:
///
/// - **Nothing is pre-selected.** The canvas artboard sits at four stars, the
///   way its booking artboard sits at `REQUESTED` — that is the demo's state,
///   not a default. Submitting a rating the customer never chose would be
///   worse than collecting none, so **Submit review** stays dead until a star
///   is tapped.
/// - **The comment is optional and labelled optional**, in the canvas's own
///   words: `COMMENT · OPTIONAL`.
/// - **Skip is a full-width target**, not fine print. Same treatment the
///   enrolment screen gives "Not now": declining is a real choice.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../components/actions.dart';
import '../../components/surface.dart';

@immutable
class RateReviewData {
  const RateReviewData({
    required this.providerName,
    required this.category,
    required this.completed,
    required this.amountPaid,
  });

  final String providerName;
  final CategoryToken category;

  /// `Completed today`. The design states when, not a timestamp — this is a
  /// reminder of which job, not a receipt.
  final String completed;

  /// What was handed over, directly. Restated here because the rating is being
  /// asked for against a specific amount of work.
  final Decimal amountPaid;
}

/// What the screen returns when it is popped: the rating and the comment, or
/// null if it was skipped.
@immutable
class Review {
  const Review({required this.stars, this.comment});

  /// 1–5. Never 0 — a zero-star review is a skipped one, and this object is
  /// not constructed for it.
  final int stars;

  /// Null or empty when the customer left it blank. An empty review body is
  /// not a review of nothing, it is a rating without words.
  final String? comment;
}

class RateReviewScreen extends StatefulWidget {
  const RateReviewScreen({super.key, required this.data});

  final RateReviewData data;

  /// The full set. Five, not a configurable scale — the aggregate has to mean
  /// the same thing on every listing.
  static const stars = 5;

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  final _comment = TextEditingController();

  /// Zero means nothing chosen yet, which is why it is not a valid [Review].
  int _rating = 0;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _comment.text.trim();
    Navigator.of(
      context,
    ).pop(Review(stars: _rating, comment: text.isEmpty ? null : text));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final data = widget.data;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                children: [
                  Text(
                    'How did it go?',
                    style: text.titleLarge?.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your rating is the only signal a new provider has.',
                    style: text.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _JobRow(data: data),
                        const SizedBox(height: Space.x4),
                        _Stars(
                          rating: _rating,
                          onChanged: (n) => setState(() => _rating = n),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.x3),
                  _CommentCard(controller: _comment),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, Space.x4, 22, 22),
              child: Column(
                children: [
                  PrimaryAction(
                    label: 'Submit review',
                    // Dead until a star is tapped. Nothing here pre-selects a
                    // rating on the customer's behalf.
                    onPressed: _rating == 0 ? null : _submit,
                  ),
                  const SizedBox(height: 10),
                  QuietAction(
                    label: 'Skip',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Which job is being rated, and what it cost. The stars sit directly under it
/// on the same card, so the rating is visibly attached to the work rather than
/// floating on the page.
class _JobRow extends StatelessWidget {
  const _JobRow({required this.data});

  final RateReviewData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return Row(
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
                '${data.completed} · ${Money.format(data.amountPaid)}',
                style: text.labelSmall?.copyWith(
                  fontSize: 11,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Five 36 dp glyphs, centred.
///
/// The canvas fills a chosen star with the literal `#145A8D` rather than with
/// `pal.accentText`. In light mode those are the same colour; in dark mode the
/// literal would put deep navy on a dark card and the rating would be close to
/// invisible. This reads the palette instead — identical to the canvas in
/// light, legible in dark. Recorded in docs/design-deltas.md.
///
/// **The empty star had the same problem and nobody had looked at it.** It was
/// drawn in `pal.divider`, a hairline token, which put the screen's only
/// control at 1.4:1 against the card in dark and barely better in light — five
/// stars you cannot see are not a rating input. It is [AppPalette.controlOutline]
/// now, and `test/theme/contrast_test.dart` keeps it legible. §18.
class _Stars extends StatelessWidget {
  const _Stars({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var n = 1; n <= RateReviewScreen.stars; n++) ...[
          if (n > 1) const SizedBox(width: 10),
          Semantics(
            button: true,
            selected: n <= rating,
            label: '$n of ${RateReviewScreen.stars} stars',
            child: Material(
              type: MaterialType.transparency,
              child: InkResponse(
                onTap: () => onChanged(n),
                radius: 26,
                child: Padding(
                  // The glyph is 36 dp; the padding is what takes the target
                  // to the 48 dp floor without spacing the row out.
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Icon(
                    Icons.star,
                    size: 36,
                    color: n <= rating ? palette.accentText : palette.controlOutline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The comment box. Labelled optional in the canvas's own words, and the
/// placeholder is the canvas's too.
class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.controller});

  final TextEditingController controller;

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
            'COMMENT · OPTIONAL',
            style: AppTypography.sectionLabel.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            height: 86,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: Radii.inputAll,
              border: Border.all(color: palette.inputBorder, width: 1.5),
            ),
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              cursorColor: palette.accentText,
              style: text.bodyMedium?.copyWith(
                fontSize: 13,
                color: palette.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'On time, good work...',
                hintStyle: text.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: palette.textFaint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
