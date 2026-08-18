/// The category tile and the grid it sits in.
///
/// The tile is the app's front door: nine of them are the first thing a
/// customer sees. Its hue and monogram come from [CategoryToken], so adding a
/// category is a token change, not a widget change.
///
/// Monograms are placeholders until real iconography lands.
///
/// See docs/design-system.md#category-hues.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/motion.dart';
import '../../theme/tokens.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, this.onTap});

  final CategoryToken category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: onTap != null,
      label: category.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardAll,
        child: Ink(
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: Radii.cardAll,
            border: Border.all(color: palette.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.x2,
              vertical: 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: Space.x10,
                  height: Space.x10,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: category.hue,
                    borderRadius: Radii.monogramAll,
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      category.monogram,
                      style: text.labelMedium?.copyWith(color: Brand.white),
                    ),
                  ),
                ),
                const SizedBox(height: Space.x2),
                Text(
                  category.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
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

/// Two columns on a phone, three once there is room — the breakpoint decides,
/// not a separate tablet layout.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    this.categories = Categories.all,
    this.onSelect,
  });

  final List<CategoryToken> categories;
  final void Function(CategoryToken category)? onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Breakpoints.categoryColumns(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(Space.gutter),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: Space.x3,
            crossAxisSpacing: Space.x3,
            // Tall enough for a two-line label at the largest text scale the
            // design supports without the tile clipping.
            mainAxisExtent: 116,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) => CategoryTile(
            category: categories[i],
            onTap: onSelect == null ? null : () => onSelect!(categories[i]),
          ),
        );
      },
    );
  }
}

/// A tile that has just become available — the one place a category animates.
/// It rises [Motion.travel] and fades; it never pulses, and nothing loops.
class CategoryTileEntrance extends StatelessWidget {
  const CategoryTileEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.enter),
      curve: Motion.curve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, Motion.travel * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
