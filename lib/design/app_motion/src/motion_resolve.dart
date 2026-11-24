// RM-02: what a widget may do for one row phase, with or without reduced
// motion (T-037).

import 'package:bluehesab_mini/design/app_motion/src/motion_catalog.dart';
import 'package:bluehesab_mini/design/app_motion/src/motion_tokens.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show immutable;

/// The outcome of [resolveMotion].
@immutable
final class ResolvedMotion {
  /// Creates an outcome.
  const ResolvedMotion({
    required this.duration,
    required this.curve,
    required this.animates,
    required this.movesOrScales,
    required this.loops,
    required this.shown,
  });

  /// How long; `instant` (0) when the end state shows at once.
  final Duration duration;

  /// Curve; null for a stay time (MO-10 hold).
  final Curve? curve;

  /// False when the end state shows at once (or for a stay time).
  final bool animates;

  /// False when translation and scale must be dropped (RM-02 fade, same,
  /// instant, still); opacity and colour stay allowed.
  final bool movesOrScales;

  /// True only for a running endless loop (LP-01).
  final bool loops;

  /// False when the moving element is not shown at all (RM-03: MO-11
  /// highlight, MO-13 spinner, MO-18 halo).
  final bool shown;

  @override
  bool operator ==(Object other) =>
      other is ResolvedMotion &&
      other.duration == duration &&
      other.curve == curve &&
      other.animates == animates &&
      other.movesOrScales == movesOrScales &&
      other.loops == loops &&
      other.shown == shown;

  @override
  int get hashCode =>
      Object.hash(duration, curve, animates, movesOrScales, loops, shown);

  @override
  String toString() => 'ResolvedMotion(duration: $duration, curve: $curve, '
      'animates: $animates, movesOrScales: $movesOrScales, loops: $loops, '
      'shown: $shown)';
}

/// Resolves [phase] of row [id] (RM-02).
///
/// With [reduced] false the phase runs as catalogued. With [reduced] true
/// the row's behaviour applies: `same` runs unchanged without movement,
/// `fade` keeps opacity only with `exit` and the phase's own curve (MT-03:
/// the curve follows the direction), `instant` and `still` show the end or
/// still state at once. Stay times (MO-10 hold) never change (MT-07).
///
/// Throws [ArgumentError] when the row has no such phase.
ResolvedMotion resolveMotion(
  MotionId id,
  MotionPhase phase, {
  required bool reduced,
}) {
  final MotionSpec spec = motionSpec(id);
  final MotionTiming? timing = spec.timing(phase);
  if (timing == null) {
    throw ArgumentError.value(phase, 'phase', '${id.specId} has no such phase');
  }
  final Duration duration = timing.duration.duration;
  final Curve? curve = timing.curve?.curve;
  final bool isHold = timing.curve == null;
  final bool isLoop = phase == MotionPhase.loop;

  if (isHold) {
    return ResolvedMotion(
      duration: duration,
      curve: null,
      animates: false,
      movesOrScales: false,
      loops: false,
      shown: true,
    );
  }
  if (!reduced) {
    return ResolvedMotion(
      duration: duration,
      curve: curve,
      animates: true,
      movesOrScales: true,
      loops: isLoop,
      shown: true,
    );
  }
  final bool shown = !spec.reducedHides.contains(phase);
  switch (spec.reducedFor(phase)) {
    case ReducedBehavior.same:
      return ResolvedMotion(
        duration: duration,
        curve: curve,
        animates: true,
        movesOrScales: false,
        loops: isLoop,
        shown: shown,
      );
    case ReducedBehavior.fade:
      return ResolvedMotion(
        duration: MotionToken.exit.duration,
        curve: curve,
        animates: true,
        movesOrScales: false,
        loops: false,
        shown: shown,
      );
    case ReducedBehavior.instant:
    case ReducedBehavior.still:
      return ResolvedMotion(
        duration: MotionToken.instant.duration,
        curve: curve,
        animates: false,
        movesOrScales: false,
        loops: false,
        shown: shown,
      );
  }
}

/// `context.motion.resolve(...)`: [resolveMotion] with this context's
/// reduced flag.
extension AppMotionResolve on AppMotion {
  /// Resolves [phase] of row [id] for this context (RM-02).
  ResolvedMotion resolve(MotionId id, MotionPhase phase) =>
      resolveMotion(id, phase, reduced: reduced);
}
