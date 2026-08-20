/// Geometry tokens: the 4 px grid, corner radii, touch floor and breakpoints.
///
/// Screens read these rather than carrying their own numbers, so a change to
/// the grid is one edit. See docs/design-system.md#spacing-touch-responsive.
library;

import 'package:flutter/widgets.dart';

/// The 4 px base grid. Nothing between these steps.
abstract final class Space {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;

  /// Horizontal screen gutter.
  static const gutter = x4;
}

/// Corner radii.
///
/// Resynced 2026-08-20 to the design's surface treatment. The old scale was a
/// flat 10–14 px, which the design named as reason 3 of five for why the
/// screens read flat: "10–14px corners and zero shadow. The 2026 idiom is
/// 20–26px corners with a soft blue-tinted shadow, which is what makes a card
/// feel like an object rather than a table row."
///
/// The four surface steps are a hierarchy — hero above card above row above
/// icon tile — and are always paired with the matching [Elevation] shadow.
abstract final class Radii {
  /// The blue gradient hero: provider dashboard header, balance card.
  static const hero = Radius.circular(26);

  /// A card that holds a group: a ledger entry, a listing, a form section.
  static const card = Radius.circular(22);

  /// A row inside a card, and the component containers: category tile,
  /// money row, input group.
  static const row = Radius.circular(18);

  /// The tinted category/status icon plate. 36 dp square in the tile.
  static const iconTile = Radius.circular(13);

  /// Buttons — all of them, including the accept/decline pair.
  static const button = Radius.circular(15);

  /// The input field itself, inside its 18 px container.
  static const input = Radius.circular(13);

  /// The nav sheet's top corners. It is a raised sheet now, not a hairline
  /// strip, so it carries the hero radius.
  static const sheet = Radius.circular(26);

  /// The pill behind the active nav icon: 42 x 30, not a circle.
  static const navPill = Radius.circular(11);

  /// Chips and pills. Large enough to always read as a capsule.
  static const pill = Radius.circular(100);

  static const heroAll = BorderRadius.all(hero);
  static const cardAll = BorderRadius.all(card);
  static const rowAll = BorderRadius.all(row);
  static const iconTileAll = BorderRadius.all(iconTile);
  static const buttonAll = BorderRadius.all(button);
  static const inputAll = BorderRadius.all(input);
  static const navPillAll = BorderRadius.all(navPill);
  static const pillAll = BorderRadius.all(pill);
  static const sheetTop = BorderRadius.vertical(top: sheet);
}

/// Touch and hit-target rules.
abstract final class Touch {
  /// 48 dp minimum, everywhere. A tap target smaller than this is a bug.
  static const min = 48.0;
  static const minSize = Size(min, min);
}

/// Shadow geometry, in blur radius. The colour comes from the palette —
/// shadows are blue-tinted, never grey, and they replace borders entirely.
///
/// Three depths, per the design: 28 on the hero, 20 on cards, 14 on rows.
abstract final class Elevation {
  static const row = 14.0;
  static const card = 20.0;
  static const hero = 28.0;

  /// The nav sheet casts upward, so its offset is negative.
  static const nav = 30.0;

  /// A filled button carries a shadow in its own hue at a much higher alpha
  /// than a surface does — it is an action, not a plane.
  static const button = 20.0;
}

/// Material 3 window size classes. The category grid is the main consumer.
enum WindowClass { compact, medium, expanded }

/// Breakpoints, and the column count each one implies.
abstract final class Breakpoints {
  static const medium = 600.0;
  static const expanded = 840.0;

  /// The widest a single-column form may grow before it centres itself.
  static const formMaxWidth = 560.0;

  static WindowClass of(double width) {
    if (width >= expanded) return WindowClass.expanded;
    if (width >= medium) return WindowClass.medium;
    return WindowClass.compact;
  }

  /// Columns in the category grid: 2 on a phone, 3 once there is room.
  static int categoryColumns(double width) =>
      of(width) == WindowClass.compact ? 2 : 3;
}
