// LP-04: one shared loop controller for many descendants (all Skeleton
// plates of a page pulse together), T-044. LP-03: the ticker comes from
// TickerProviderStateMixin (a new ticker each time the loop starts again),
// so `TickerMode(enabled: false)` mutes it while the subtree is not shown.
// LP-02: the loop runs only while the caller says the real wait is on
// ([MotionLoopGroup.running]).
//
// Mapping the 0…1 value to a row's own range (MO-12 opacity 0.6…1.0) is the
// component's job; this group only hands out the curved animation.

import 'package:bluehesab_mini/design/app_motion/src/motion_catalog.dart';
import 'package:bluehesab_mini/design/app_motion/src/motion_handle.dart';
import 'package:bluehesab_mini/design/app_motion/src/motion_scope.dart';
import 'package:flutter/widgets.dart';

/// Owns one [MotionHandle] for the loop phase of row [id] and shares its
/// animation with every descendant (LP-04).
class MotionLoopGroup extends StatefulWidget {
  /// Creates the group.
  ///
  /// [id] must be a table 4-3 row with a loop phase (LP-01); otherwise an
  /// [ArgumentError] is thrown when the loop first starts.
  const MotionLoopGroup({
    super.key,
    required this.id,
    required this.running,
    required this.reverse,
    required this.child,
  });

  /// Table 4-3 row whose loop phase runs (LP-01).
  final MotionId id;

  /// True while the real state behind the loop is on (LP-02). When false no
  /// controller exists and descendants read the start value (0).
  final bool running;

  /// Passed to [MotionHandle.repeat]: true for a back-and-forth pulse. The
  /// component chooses it from its table 4-3 row.
  final bool reverse;

  /// The subtree that reads [of].
  final Widget child;

  /// The shared loop animation of the nearest group, or `null` without one.
  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_MotionLoopScope>()
      ?.animation;

  /// The shared loop animation of the nearest group (LP-04).
  ///
  /// Throws [StateError] when there is no [MotionLoopGroup] above [context].
  static Animation<double> of(BuildContext context) {
    final Animation<double>? animation = maybeOf(context);
    if (animation == null) {
      throw StateError('no MotionLoopGroup above this context (LP-04)');
    }
    return animation;
  }

  @override
  State<MotionLoopGroup> createState() => _MotionLoopGroupState();
}

class _MotionLoopGroupState extends State<MotionLoopGroup>
    with TickerProviderStateMixin {
  MotionHandle? _handle;

  /// What descendants read when no loop runs: the start value.
  static const Animation<double> _stopped = kAlwaysDismissedAnimation;

  void _start() {
    final MotionHandle handle = MotionHandle(
      context: context,
      vsync: this,
      id: widget.id,
      phase: MotionPhase.loop,
      reduced: context.motion.reduced,
    );
    _handle = handle;
    handle.track(MotionProperty.progress, handle.animation);
    handle.repeat(reverse: widget.reverse);
  }

  void _stop() {
    _handle?.dispose();
    _handle = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final MotionHandle? handle = _handle;
    if (handle != null) {
      handle.updateReduced(context.motion.reduced);
    } else if (widget.running) {
      _start();
    }
  }

  @override
  void didUpdateWidget(MotionLoopGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool changed =
        oldWidget.id != widget.id || oldWidget.reverse != widget.reverse;
    if (!widget.running || changed) {
      _stop();
    }
    if (widget.running && _handle == null) {
      _start();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _MotionLoopScope(
        animation: _handle?.animation ?? _stopped,
        child: widget.child,
      );
}

class _MotionLoopScope extends InheritedWidget {
  const _MotionLoopScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_MotionLoopScope oldWidget) =>
      !identical(oldWidget.animation, animation);
}
