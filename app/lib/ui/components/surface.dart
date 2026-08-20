/// The three surface depths, and the tinted icon plate.
///
/// The design carries depth in blue-tinted shadow rather than in grey borders,
/// and it does it at exactly three levels — hero above card above row. Every
/// screen is assembled from these rather than from bare [Container]s, so the
/// hierarchy stays a rule instead of a habit.
///
/// A surface takes a shadow **or** a border, never both. If you find yourself
/// adding `Border.all` to one of these, the design has changed and the token
/// should change with it.
///
/// See docs/design-system.md#surface-treatment.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';

/// The deepest surface: a real blue gradient carrying its own actions.
///
/// "Blue as a field, not as trim" — the provider dashboard header and the
/// balance card are the same object at two sizes. Content on it is always
/// light, so this supplies a white-on-blue [IconTheme] and text colour rather
/// than making every child restate it.
class HeroSurface extends StatelessWidget {
  const HeroSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.x5),
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Defaults to the palette's hero gradient. The balance card passes the
  /// darker radial one instead — it stays the darkest surface on screen in
  /// both themes, which is one of the three things the design holds constant
  /// across the light/dark swap.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient ?? palette.heroGradient,
        borderRadius: Radii.heroAll,
        boxShadow: palette.shadowHero,
      ),
      child: Padding(
        padding: padding,
        child: IconTheme(
          data: const IconThemeData(color: Brand.white, size: 24),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Brand.white),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A card that holds a group: a ledger entry, a listing, a form section.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.x4),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return _Tappable(
      onTap: onTap,
      borderRadius: Radii.cardAll,
      decoration: BoxDecoration(
        color: color ?? palette.cardBg,
        borderRadius: Radii.cardAll,
        boxShadow: palette.shadowCard,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A row inside a card, and the component containers — category tile, money
/// row, input group. The shallowest of the three.
class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(13),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return _Tappable(
      onTap: onTap,
      borderRadius: Radii.rowAll,
      decoration: BoxDecoration(
        color: color ?? palette.cardBg,
        borderRadius: Radii.rowAll,
        boxShadow: palette.shadowRow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The tinted plate an icon sits on: 36 dp square, radius 13.
///
/// Category identity lives here. The plate is the category hue at
/// `oklch(0.95 0.035 h)` and the glyph is the same hue at `oklch(0.5 0.13 h)`,
/// so the pair always agrees — see [CategoryToken].
class IconPlate extends StatelessWidget {
  const IconPlate({
    super.key,
    required this.icon,
    required this.plate,
    required this.ink,
    this.size = 36,
    this.iconSize = 20,
  });

  /// The plate for a launch category, taking both colours from its token.
  IconPlate.category(
    CategoryToken category,
    Brightness brightness, {
    super.key,
    this.size = 36,
    this.iconSize = 20,
  }) : icon = category.icon,
       plate = category.plateOf(brightness),
       ink = category.inkOf(brightness);

  final IconData icon;
  final Color plate;
  final Color ink;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: plate, borderRadius: Radii.iconTileAll),
      child: Icon(icon, size: iconSize, color: ink),
    );
  }
}

/// Shared plumbing: keeps the ink splash clipped to the surface's own radius,
/// and keeps a non-interactive surface free of a [Material] it does not need.
class _Tappable extends StatelessWidget {
  const _Tappable({
    required this.child,
    required this.decoration,
    required this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final BoxDecoration decoration;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = DecoratedBox(decoration: decoration, child: child);
    if (onTap == null) return surface;

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: borderRadius, child: child),
      ),
    );
  }
}
