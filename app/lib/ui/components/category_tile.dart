/// The category tile and the grid it sits in.
///
/// The tile is the app's front door: nine of them are the first thing a
/// customer sees. Its icon, hue and tinted plate come from [CategoryToken], so
/// adding a category is a token change, not a widget change.
///
/// Resynced 2026-08-20: the grey monogram on a solid plate is gone, replaced
/// by a Material Symbol on a tinted plate of the category hue, on a white card
/// that carries a shadow instead of a border.
///
/// See docs/design-system.md#category-hues.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';
import 'enter_in_place.dart';

/// How a category is doing, per city — as the customer sees it.
///
/// **Two states, not three.** The back office grades supply `HEALTHY` / `THIN`
/// / `CRITICAL` because an operator needs to know where to go recruiting; the
/// app deliberately collapses that to `ok` / `thin`, because the customer-facing
/// job is different. A category with two providers and a category with four are
/// the same thing to someone deciding whether to tap: new.
///
/// That is the whole point of the supply copy — a thin category has to read as
/// **new rather than broken**. So the label is "New in Gaborone · 2 providers",
/// not "2 nearby", which reads as a failing category rather than a young one.
///
/// See docs/design-system.md#category-hues and
/// docs/admin-design.md#a6--key-statistics for the operator's scale.
enum SupplyStanding {
  ok,
  thin;

  /// Spoken behind the dot, which is colour alone.
  String get description => switch (this) {
    SupplyStanding.ok => 'available now',
    SupplyStanding.thin => 'new in this city',
  };
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    this.supplyLabel,
    this.standing,
    this.onTap,
  });

  final CategoryToken category;

  /// Colours the supply dot. Null while the count is loading.
  final SupplyStanding? standing;

  /// The honest supply count — "62 nearby", "4 nearby", "34 rooms".
  ///
  /// One of the five decisions the system is built around: a home screen that
  /// hides low supply looks broken when the customer taps in, so every tile
  /// shows a real, specific count rather than pretending. Null only while the
  /// count is still loading; it is never omitted to flatter a thin category.
  final String? supplyLabel;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return Semantics(
      button: onTap != null,
      // The dot is colour alone, so the standing is spoken rather than left
      // to a hue a screen-reader user never sees.
      label: [
        category.label,
        if (supplyLabel != null) supplyLabel,
        if (standing != null) standing!.description,
      ].join(', '),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: Radii.rowAll,
          // `shadowRow`, because the canvas gives this tile `pal.shCard` and
          // that name maps to *our* shadowRow — see the mapping table in
          // tokens.dart. The two vocabularies invert, which is exactly the
          // trap: reading the canvas name as ours makes the tile a step too
          // deep.
          boxShadow: palette.shadowRow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: Radii.rowAll,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
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
                  const SizedBox(height: 9),
                  Text(
                    category.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  if (supplyLabel != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (standing != null) ...[
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              // Straight from the canvas:
                              //   supplyDotColor: supply === 'ok'
                              //     ? 'oklch(0.6 0.13 152)' : pal.navMuted
                              //
                              // oklch(0.6 0.13 152) is #359658 — Status.success.
                              // Thin is `navMuted`, a muted grey-blue, and NOT
                              // Status.warning: amber says "caution", and the
                              // whole point of the supply copy is that a young
                              // category is new rather than faulty. An amber
                              // dot argues against the words beside it.
                              color: switch (standing!) {
                                SupplyStanding.ok => Status.success,
                                SupplyStanding.thin => palette.navMuted,
                              },
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            supplyLabel!,
                            // Two lines, because one truncates. "New in
                            // Gaborone · 6 plumbers" does not fit a 132 dp
                            // column, and an ellipsis there hides exactly the
                            // number the tile exists to state. The canvas lets
                            // this text wrap and sets no clamp at all.
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall?.copyWith(
                              fontSize: 10.5,
                              color: palette.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
    this.supplyLabels = const {},
    this.standings = const {},
    this.onSelect,
  });

  final List<CategoryToken> categories;

  /// Supply count per category key. A category missing from the map renders
  /// without a count, which is the loading state — not a way to hide a zero.
  final Map<String, String> supplyLabels;

  /// Standing per category key, colouring the supply dot.
  final Map<String, SupplyStanding> standings;

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
            // Tall enough for a two-line label plus a two-line supply count
            // at the largest text scale the design supports without the tile
            // clipping. Raised from 124 when the count was allowed to wrap.
            mainAxisExtent: 136,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) => CategoryTile(
            category: categories[i],
            supplyLabel: supplyLabels[categories[i].key],
            standing: standings[categories[i].key],
            onTap: onSelect == null ? null : () => onSelect!(categories[i]),
          ),
        );
      },
    );
  }
}

/// A tile that has just become available — the one place a category animates.
///
/// A name for the moment rather than for the mechanism: the rise-and-fade
/// itself is [EnterInPlace], shared with the booking screen's provider row and
/// pay panel, because "anything entering in place" is a token-level rule and
/// three screens should not each own a copy of it.
class CategoryTileEntrance extends StatelessWidget {
  const CategoryTileEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => EnterInPlace(child: child);
}
