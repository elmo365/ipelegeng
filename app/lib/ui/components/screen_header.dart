/// The header the booking pair uses instead of an [AppBar].
///
/// The canvas draws booking request and booking status as a plain column from
/// the top of the page — no app bar, no elevation, no title row. That works on
/// an artboard, where a segmented `Request / Status` tab strip occupies the top
/// and nothing has to go back anywhere. In the app the two are separate routes
/// and each needs a way out, so the affordance has to carry itself: a raised
/// plate rather than a bare glyph floating on a tinted page.
///
/// Both booking screens use this one object, so the request step and the status
/// it leads to read as one flow rather than as two screens that happen to be
/// adjacent.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.category,
    this.onBack,
  });

  final String title;

  /// Drawn as a filled pill in the category's own ink. Null on a screen that
  /// is not about one category.
  final CategoryToken? category;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Row(
        children: [
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
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  borderRadius: Radii.iconTileAll,
                  child: Semantics(
                    button: true,
                    label: 'Back',
                    child: Icon(
                      Icons.arrow_back,
                      size: 21,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Text(
              title,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: category!.inkOf(brightness),
                borderRadius: Radii.pillAll,
              ),
              child: Text(
                category!.label,
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
