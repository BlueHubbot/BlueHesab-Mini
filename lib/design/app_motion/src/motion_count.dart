// `app_motion` slice 8 (T-046): the MO-14 count value of SummaryCard in
// `BigInt` (SC-08), kept inside the range from origin to target (MR-02) and
// ending exactly on the real value (MX-05).
//
// Only the value is computed here. The caller formats every frame with the
// central formatter (CA-01) and builds the Semantics label from [MotionCount.
// target] only (CA-05, MR-02): an intermediate number never enters
// Semantics, output or stored data.

import 'package:flutter/animation.dart';

/// SC-08: k runs from 0 to this value (`k = round(curve(t) × 1000)`).
const int motionCountSteps = 1000;

final BigInt _steps = BigInt.from(motionCountSteps);

/// SC-08 / MR-02: the value MO-14 shows at [progress] (the curved fraction,
/// 0…1, clamped) on the way from [from] to [to], in minor units.
///
/// `from + (delta × k) ~/ 1000` with k = round(progress × 1000), computed in
/// `BigInt` only (an `int` product overflows for an 18-digit amount). The
/// intermediate value is rounded to a multiple of [unit] toward the origin
/// (1 for rial, 10 for toman: MN-02; the caller chooses), then clamped into
/// the closed range between [from] and [to] (MR-02 wins over the rounding,
/// D0 T-046). k = 0 gives exactly [from]; k = 1000 gives exactly [to].
BigInt motionCountValue({
  required BigInt from,
  required BigInt to,
  required double progress,
  BigInt? unit,
}) {
  final BigInt step = unit ?? BigInt.one;
  if (step <= BigInt.zero) {
    throw ArgumentError.value(unit, 'unit', 'must be positive');
  }
  final double p = progress.isNaN
      ? 0.0
      : (progress < 0 ? 0.0 : (progress > 1 ? 1.0 : progress));
  final int k = (p * motionCountSteps).round();
  if (k >= motionCountSteps) {
    return to;
  }
  if (k <= 0) {
    return from;
  }
  final BigInt delta = to - from;
  // BigInt `~/` truncates toward zero, so the raw value never passes `to`.
  final BigInt raw = from + (delta * BigInt.from(k)) ~/ _steps;
  final BigInt rounded =
      delta >= BigInt.zero ? _floorTo(raw, step) : _ceilTo(raw, step);
  final BigInt lo = from <= to ? from : to;
  final BigInt hi = from <= to ? to : from;
  if (rounded < lo) {
    return lo;
  }
  if (rounded > hi) {
    return hi;
  }
  return rounded;
}

/// The largest multiple of [step] that is not above [v].
BigInt _floorTo(BigInt v, BigInt step) {
  final BigInt r = v.remainder(step);
  return r < BigInt.zero ? v - r - step : v - r;
}

/// The smallest multiple of [step] that is not below [v].
BigInt _ceilTo(BigInt v, BigInt step) {
  final BigInt r = v.remainder(step);
  return r > BigInt.zero ? v - r + step : v - r;
}

/// MO-14 as an `Animation<BigInt>`: [parent] is the `animation` of a MO-14
/// `MotionHandle` (`max` + `decelerate`; «آنی» under reduced motion, so only
/// the last frame shows — RM-02), and [value] is [motionCountValue] at the
/// parent's value.
class MotionCount extends Animation<BigInt>
    with AnimationWithParentMixin<double> {
  /// Counts from [from] to [to] in multiples of [unit] (default 1).
  MotionCount({
    required this.parent,
    required this.from,
    required this.to,
    BigInt? unit,
  }) : unit = unit ?? BigInt.one {
    if (this.unit <= BigInt.zero) {
      throw ArgumentError.value(unit, 'unit', 'must be positive');
    }
  }

  @override
  final Animation<double> parent;

  /// The value shown before the count (0 on the first show, SC-08).
  final BigInt from;

  /// The real value; the last frame and the Semantics label (MR-02, MX-05).
  final BigInt to;

  /// The display unit in minor units (MN-02).
  final BigInt unit;

  /// The only value a Semantics label, an export or storage may read
  /// (MR-02, CA-05).
  BigInt get target => to;

  @override
  BigInt get value => motionCountValue(
        from: from,
        to: to,
        progress: parent.value,
        unit: unit,
      );
}
