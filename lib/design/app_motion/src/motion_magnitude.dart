// MT-05 movement sizes and the MT-06 logical direction (T-042).
//
// The three numbers are MT-05's own (section 4-1); they are spec constants,
// not section 4-2 tokens, and are written only here so no widget writes 24
// or 0.96 itself (MX-03, AG-05). A test reads them back from the spec file.
// Surfaces that come from a screen edge (MO-07 side panel, MO-08 Bottom
// Sheet) move by their own size (MT-05), which their components read from
// layout tokens; nothing for them here.

import 'package:flutter/widgets.dart' show TextDirection;

/// Movement sizes of MT-05 and the logical direction of MT-06.
abstract final class MotionMagnitude {
  /// MT-05: page shift of MO-05 (enter) and MO-06 (exit), logical pixels.
  static const double pageShift = 24;

  /// MT-05: Toast shift of MO-10 enter (towards the top), logical pixels.
  static const double toastShift = 16;

  /// MT-05: Dialog scale at the start of MO-09 enter (it ends at 1).
  static const double dialogScaleFrom = 0.96;

  /// MT-06: sign of a horizontal shift towards the `end` side: −1 in RTL
  /// (end is on the left), +1 in LTR.
  static double endSign(TextDirection direction) =>
      direction == TextDirection.rtl ? -1 : 1;

  /// MT-06, MX-04: `dx0 = 24 × (RTL ? −1 : +1)`, where MO-05 enter starts
  /// and MO-06 exit ends.
  static double pageDx0(TextDirection direction) =>
      pageShift * endSign(direction);

  /// MO-10 enter starts this far below its place and moves up to 0
  /// (Flutter's y axis points down). Vertical shifts are not mirrored.
  static const double toastDy0 = toastShift;
}
