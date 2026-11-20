// MX-08: MotionHandle (the one way to get a controller for a table 4-3 row
// phase) and MotionRegistry (debug/test record of every live controller with
// the BuildContext that built it), T-039. Slice 3 (T-040): RM-01 "applies
// at once, with no restart" for a live handle ([MotionHandle.updateReduced]).
//
// MX-03 keeps `AnimationController(` inside `app_motion`; widgets elsewhere
// ask for a [MotionHandle] and build their transitions on its [animation].
// The registry is filled only inside `assert`, so release builds keep
// nothing (MX-08: "in debug and test").

import 'package:bluehesab_mini/design/app_motion/src/motion_catalog.dart';
import 'package:bluehesab_mini/design/app_motion/src/motion_resolve.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

/// The values MotionProbe can read (MX-08).
enum MotionProperty {
  /// Opacity, 0 to 1.
  opacity,

  /// Horizontal offset.
  dx,

  /// Vertical offset.
  dy,

  /// Scale factor.
  scale,

  /// Drawn progress of a `CustomPainter` (ring arc, chart path, count).
  progress,
}

/// One live controller in the [MotionRegistry].
final class MotionRegistration {
  MotionRegistration._(this.context, this.id, this.phase, this.controller);

  /// The context of the widget that built the controller.
  final BuildContext context;

  /// Table 4-3 row.
  final MotionId id;

  /// Row phase.
  final MotionPhase phase;

  /// The controller.
  final AnimationController controller;

  final Map<MotionProperty, Animation<double>> _tracked =
      <MotionProperty, Animation<double>>{};

  /// True for the loop phase of a row (LP-01).
  bool get isLoop => phase == MotionPhase.loop;

  /// True while the controller runs in the last frame.
  bool get isActive => controller.isAnimating;

  /// The animation that drives [property] of this widget, if tracked.
  Animation<double>? tracked(MotionProperty property) => _tracked[property];
}

/// Debug/test record of live controllers (MX-08). Only [MotionHandle]
/// writes it; MotionProbe reads it.
abstract final class MotionRegistry {
  static final List<MotionRegistration> _entries = <MotionRegistration>[];

  /// Live registrations, oldest first; always empty in release builds.
  static List<MotionRegistration> get entries =>
      List<MotionRegistration>.unmodifiable(_entries);
}

/// A controller for one row phase, resolved with RM-02 (T-037).
///
/// Create it in `didChangeDependencies` (or later) so [reduced] can come
/// from `context.motion.reduced`, and [dispose] it with the widget.
final class MotionHandle {
  MotionHandle._(
    this.id,
    this.phase,
    this._reduced,
    this._resolved,
    this.controller,
    this._curved,
  );

  /// Creates the controller for [phase] of row [id].
  ///
  /// Throws [ArgumentError] when the row has no such phase or the phase is a
  /// stay time (MO-10 hold), which is a timer, not an animation (MT-07).
  factory MotionHandle({
    required BuildContext context,
    required TickerProvider vsync,
    required MotionId id,
    required MotionPhase phase,
    required bool reduced,
  }) {
    final ResolvedMotion resolved = resolveMotion(id, phase, reduced: reduced);
    final Curve? curve = resolved.curve;
    if (curve == null) {
      throw ArgumentError.value(
          phase, 'phase', '${id.specId} $phase is a stay time');
    }
    final AnimationController controller =
        AnimationController(vsync: vsync, duration: resolved.duration);
    final MotionHandle handle = MotionHandle._(
      id,
      phase,
      reduced,
      resolved,
      controller,
      CurvedAnimation(parent: controller, curve: curve),
    );
    assert(() {
      final MotionRegistration registration =
          MotionRegistration._(context, id, phase, controller);
      handle._registration = registration;
      MotionRegistry._entries.add(registration);
      return true;
    }());
    return handle;
  }

  /// Table 4-3 row.
  final MotionId id;

  /// Row phase.
  final MotionPhase phase;

  bool _reduced;
  ResolvedMotion _resolved;

  /// The reduced flag the handle is resolved for (RM-01).
  bool get reduced => _reduced;

  /// What RM-02 allows for this phase with [reduced].
  ResolvedMotion get resolved => _resolved;

  /// The controller; driven only through [forward], [reverse] and [repeat].
  final AnimationController controller;

  final CurvedAnimation _curved;

  /// The controller with the phase's curve applied. RM-02 keeps the phase's
  /// curve in every case, so [updateReduced] never replaces it.
  Animation<double> get animation => _curved;

  MotionRegistration? _registration;

  /// The last [repeat] request (its `reverse` argument), so a loop can start
  /// again when reduced motion is turned off; null when no loop was asked.
  bool? _repeatReverse;

  /// Applies a new RM-01 reduced flag at once, with no restart (RM-01).
  ///
  /// Call it from `didChangeDependencies` with `context.motion.reduced`; it
  /// does nothing when the flag is unchanged. The next play uses the new
  /// RM-02 duration. What runs now (D0, T-040):
  /// - reduced turned on: a running non-loop whose phase RM-02 makes «آنی»
  ///   or «ایستا» jumps to the value it was heading for (end of [forward],
  ///   start of [reverse]), so MotionProbe counts it 0 and reads the end
  ///   value (MX-08); a running «محو» or «همان» phase goes on from where it
  ///   is towards the same end with the new RM-02 duration, and the widget
  ///   re-tracks `dx`/`dy`/`scale` at their end values, so only opacity
  ///   (or colour) changes and the count is 0 once that change ends
  ///   (ADVISOR_REPLY-009 Decision A, Action 3); a loop that RM-02 stops
  ///   («ایستا») goes to its start.
  /// - reduced turned off: a running crossfade («محو», «همان») ends as it
  ///   started; a loop asked for with [repeat] starts again (LP-01).
  ///
  /// The widget re-tracks properties whose source depends on
  /// [ResolvedMotion.movesOrScales] (MX-08).
  void updateReduced(bool reduced) {
    if (reduced == _reduced) {
      return;
    }
    _reduced = reduced;
    _resolved = resolveMotion(id, phase, reduced: reduced);
    controller.duration = _resolved.duration;
    final bool? repeatReverse = _repeatReverse;
    if (repeatReverse != null) {
      if (_resolved.loops) {
        controller.repeat(reverse: repeatReverse);
      } else {
        controller.value = controller.lowerBound;
      }
      return;
    }
    if (reduced && controller.isAnimating) {
      final bool backwards = controller.status == AnimationStatus.reverse;
      if (_resolved.animates) {
        // «محو» / «همان»: continue the crossfade from the current value; the
        // controller scales the new duration by the distance left.
        if (backwards) {
          controller.reverse();
        } else {
          controller.forward();
        }
      } else {
        controller.value =
            backwards ? controller.lowerBound : controller.upperBound;
      }
    }
  }

  /// Records that [source] drives [property] (MX-08); returns [source].
  Animation<double> track(MotionProperty property, Animation<double> source) {
    assert(() {
      _registration?._tracked[property] = source;
      return true;
    }());
    return source;
  }

  /// Plays to the end; shows the end state at once when the phase does not
  /// animate (RM-02 instant/still).
  TickerFuture forward() {
    _repeatReverse = null;
    if (!_resolved.animates) {
      controller.value = controller.upperBound;
      return TickerFuture.complete();
    }
    return controller.forward();
  }

  /// Plays back to the start; shows the start state at once when the phase
  /// does not animate.
  TickerFuture reverse() {
    _repeatReverse = null;
    if (!_resolved.animates) {
      controller.value = controller.lowerBound;
      return TickerFuture.complete();
    }
    return controller.reverse();
  }

  /// Runs the loop phase (LP-01); with reduced motion (RM-02 still) the
  /// controller stays at the start.
  TickerFuture repeat({bool reverse = false}) {
    assert(phase == MotionPhase.loop,
        'repeat is only for a loop phase (LP-01)');
    _repeatReverse = reverse;
    if (!_resolved.loops) {
      controller.value = controller.lowerBound;
      return TickerFuture.complete();
    }
    return controller.repeat(reverse: reverse);
  }

  /// Disposes the curved animation and the controller and leaves the
  /// registry.
  void dispose() {
    final MotionRegistration? registration = _registration;
    if (registration != null) {
      MotionRegistry._entries.remove(registration);
      _registration = null;
    }
    _curved.dispose();
    controller.dispose();
  }
}
