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

/// Corner radii, per the component table.
abstract final class Radii {
  static const button = Radius.circular(12);
  static const input = Radius.circular(10);
  static const card = Radius.circular(14);
  static const monogram = Radius.circular(11);
  static const sheet = Radius.circular(20);

  /// Chips and pills. Large enough to always read as a capsule.
  static const pill = Radius.circular(100);

  static const buttonAll = BorderRadius.all(button);
  static const inputAll = BorderRadius.all(input);
  static const cardAll = BorderRadius.all(card);
  static const monogramAll = BorderRadius.all(monogram);
  static const pillAll = BorderRadius.all(pill);
  static const sheetTop = BorderRadius.vertical(top: sheet);
}

/// Touch and hit-target rules.
abstract final class Touch {
  /// 48 dp minimum, everywhere. A tap target smaller than this is a bug.
  static const min = 48.0;
  static const minSize = Size(min, min);
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
