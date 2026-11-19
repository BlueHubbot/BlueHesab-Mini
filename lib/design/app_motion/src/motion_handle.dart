// MX-08: MotionHandle (the one way to get a controller for a table 4-3 row
// phase) and MotionRegistry (debug/test record of every live controller with
// the BuildContext that built it), T-039.
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
  MotionHandle._(this.resolved, this.controller, this.animation);

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

  /// What RM-02 allows for this phase.
  final ResolvedMotion resolved;

  /// The controller; driven only through [forward], [reverse] and [repeat].
  final AnimationController controller;

  /// The controller with the phase's curve applied.
  final Animation<double> animation;

  MotionRegistration? _registration;

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
    if (!resolved.animates) {
      controller.value = controller.upperBound;
      return TickerFuture.complete();
    }
    return controller.forward();
  }

  /// Plays back to the start; shows the start state at once when the phase
  /// does not animate.
  TickerFuture reverse() {
    if (!resolved.animates) {
      controller.value = controller.lowerBound;
      return TickerFuture.complete();
    }
    return controller.reverse();
  }

  /// Runs the loop phase (LP-01); with reduced motion (RM-02 still) the
  /// controller stays at the start.
  TickerFuture repeat({bool reverse = false}) {
    assert(resolved.loops || !resolved.animates,
        'repeat is only for a loop phase (LP-01)');
    if (!resolved.loops) {
      controller.value = controller.lowerBound;
      return TickerFuture.complete();
    }
    return controller.repeat(reverse: reverse);
  }

  /// Disposes the controller and leaves the registry.
  void dispose() {
    final MotionRegistration? registration = _registration;
    if (registration != null) {
      MotionRegistry._entries.remove(registration);
      _registration = null;
    }
    controller.dispose();
  }
}
