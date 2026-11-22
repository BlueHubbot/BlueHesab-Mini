// MX-08: MotionHandle (the one way to get a controller for a table 4-3 row
// phase) and MotionRegistry (debug/test record of every live controller with
// the BuildContext that built it), T-039. Slice 3 (T-040): RM-01 "applies
// at once, with no restart" for a live handle ([MotionHandle.updateReduced]).
// Slice 5 (T-043): MR-03 interruption ([MotionHandle.interrupt],
// [MotionHandle.from]). Slice 7 (T-045): the MT-08 page cap
// ([MotionBudgetScope], [MotionBudget]) and the SV-01 priority order
// ([forwardInPriorityOrder]). Slice 9 (T-047): the LP-04 cap of two loops
// in view, counted in the same page budget apart from MT-08.
//
// MX-03 keeps `AnimationController(` inside `app_motion`; widgets elsewhere
// ask for a [MotionHandle] and build their transitions on its [animation].
// The registry is filled only inside `assert`, so release builds keep
// nothing (MX-08: "in debug and test").

import 'package:bluehesab_mini/design/app_motion/src/motion_catalog.dart';
import 'package:bluehesab_mini/design/app_motion/src/motion_resolve.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart'
    show
        BuildContext,
        InheritedWidget,
        State,
        StatefulWidget,
        Widget;

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
    this._budget,
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
      // MT-08 counts non-loop animations, LP-04 loops; both in one budget.
      MotionBudgetScope.maybeOf(context),
    );
    handle._budget?._members.add(handle);
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

  /// The page budget this handle joined (MT-08, LP-04), if any.
  final MotionBudget? _budget;

  /// True while the controller runs and this is not a loop (MT-08).
  bool get _runsNonLoop => phase != MotionPhase.loop && controller.isAnimating;

  /// True while the controller runs and this is a loop (LP-04).
  bool get _runsLoop => phase == MotionPhase.loop && controller.isAnimating;

  /// True for a loop asked for with [repeat] that RM-02 lets run but that
  /// does not run now: it waits for a place under LP-04 (T-047).
  bool get _waitsForPlace =>
      _repeatReverse != null && _resolved.loops && !controller.isAnimating;

  /// MT-08: false when the page already runs its cap of other non-loop
  /// animations, so this play is done at once (SV-01, D0 T-045).
  bool get _admitted => _budget?._admits(this) ?? true;

  /// LP-04: false when the page already runs its cap of other loops, so
  /// this loop waits still at its start (RM-02 «ایستا» look, D0 T-047).
  bool get _loopAdmitted => _budget?._admitsLoop(this) ?? true;

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
      if (_resolved.loops && _loopAdmitted) {
        controller.repeat(reverse: repeatReverse);
      } else {
        controller.value = controller.lowerBound;
        // A loop made still frees its LP-04 place (T-047).
        _budget?._startWaitingLoops();
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

  /// MR-03: cuts this row where it is, without a jump to either end, so the
  /// next row on the same element can continue from the current value
  /// (MT-07). Works for loops too; does nothing when nothing runs. A later
  /// [forward], [reverse] or [repeat] plays again (T-043).
  void interrupt() {
    _repeatReverse = null;
    if (controller.isAnimating) {
      controller.stop(canceled: true);
      if (phase == MotionPhase.loop) {
        // LP-04: the place this loop held goes to a waiting loop (T-047).
        _budget?._startWaitingLoops();
      }
    }
  }

  /// MR-03, MT-07: this row's [animation] mapped from [current] (the value
  /// the element has at the cut) to [end], so the row starts where the
  /// previous one was cut and not from its own start. The row keeps its own
  /// table 4-3 duration and curve (D0, T-043). With RM-02 «آنی» or «ایستا»
  /// [forward] jumps the controller to its end, so the value is [end] at
  /// once.
  Animation<double> from(double current, double end) =>
      Tween<double>(begin: current, end: end).animate(_curved);

  /// Records that [source] drives [property] (MX-08); returns [source].
  Animation<double> track(MotionProperty property, Animation<double> source) {
    assert(() {
      _registration?._tracked[property] = source;
      return true;
    }());
    return source;
  }

  /// Plays to the end; shows the end state at once when the phase does not
  /// animate (RM-02 instant/still) or the page is at its MT-08 cap.
  TickerFuture forward() {
    _repeatReverse = null;
    if (!_resolved.animates || !_admitted) {
      controller.value = controller.upperBound;
      return TickerFuture.complete();
    }
    return controller.forward();
  }

  /// Plays back to the start; shows the start state at once when the phase
  /// does not animate or the page is at its MT-08 cap.
  TickerFuture reverse() {
    _repeatReverse = null;
    if (!_resolved.animates || !_admitted) {
      controller.value = controller.lowerBound;
      return TickerFuture.complete();
    }
    return controller.reverse();
  }

  /// Runs the loop phase (LP-01); with reduced motion (RM-02 still) the
  /// controller stays at the start. When the page already runs two other
  /// loops (LP-04) it also stays at the start and starts by itself once a
  /// place frees (T-047).
  TickerFuture repeat({bool reverse = false}) {
    assert(phase == MotionPhase.loop,
        'repeat is only for a loop phase (LP-01)');
    _repeatReverse = reverse;
    if (!_resolved.loops || !_loopAdmitted) {
      controller.value = controller.lowerBound;
      return TickerFuture.complete();
    }
    return controller.repeat(reverse: reverse);
  }

  /// Disposes the curved animation and the controller and leaves the
  /// registry.
  void dispose() {
    final MotionBudget? budget = _budget;
    final bool heldLoopPlace = _runsLoop;
    _repeatReverse = null;
    budget?._members.remove(this);
    if (heldLoopPlace) {
      budget?._startWaitingLoops();
    }
    final MotionRegistration? registration = _registration;
    if (registration != null) {
      MotionRegistry._entries.remove(registration);
      _registration = null;
    }
    _curved.dispose();
    controller.dispose();
  }
}

/// MT-08: "at most three non-loop animations run at once on each page; each
/// `CustomPainter` counts as one" (one [MotionHandle] per painter).
const int motionPageCap = 3;

/// LP-04: "at any moment at most two loops are in view" (one
/// `MotionLoopGroup` owns one handle, so a group counts as one loop).
const int motionLoopCap = 2;

/// SV-01: who gets a place first when the third row of the success sequence
/// starts together (MO-14 ← MO-15 ← MO-11 ← MO-18).
const List<MotionId> sv01Priority = <MotionId>[
  MotionId.mo14,
  MotionId.mo15,
  MotionId.mo11,
  MotionId.mo18,
];

/// The MT-08 and LP-04 counts of one page. Only [MotionHandle] joins it; it
/// lives in a [MotionBudgetScope].
final class MotionBudget {
  MotionBudget._();

  final Set<MotionHandle> _members = <MotionHandle>{};

  /// Non-loop animations of this page running now (MT-08).
  int get running =>
      _members.where((MotionHandle h) => h._runsNonLoop).length;

  /// A handle already running keeps its place (MR-03 continues it); a new
  /// play gets one only below [motionPageCap]. The count is read from the
  /// controllers, so a finished, cut, «آنی» or disposed row frees its place
  /// at once.
  bool _admits(MotionHandle handle) =>
      handle._runsNonLoop ||
      _members
              .where((MotionHandle h) => !identical(h, handle) && h._runsNonLoop)
              .length <
          motionPageCap;

  /// Loops of this page running now (LP-04).
  int get runningLoops =>
      _members.where((MotionHandle h) => h._runsLoop).length;

  /// Loops of this page asked for with `repeat` that wait for a place.
  int get waitingLoops =>
      _members.where((MotionHandle h) => h._waitsForPlace).length;

  /// LP-04: a running loop keeps its place; a new one gets one only below
  /// [motionLoopCap].
  bool _admitsLoop(MotionHandle handle) =>
      handle._runsLoop ||
      _members
              .where((MotionHandle h) => !identical(h, handle) && h._runsLoop)
              .length <
          motionLoopCap;

  /// LP-04, LP-02: a waiting loop still has its real state behind it, so it
  /// starts as soon as a place frees; the oldest member (the handle built
  /// first) starts first, since members keep the order they joined in
  /// (D0 T-047).
  void _startWaitingLoops() {
    for (final MotionHandle h in _members.toList()) {
      if (runningLoops >= motionLoopCap) {
        return;
      }
      if (h._waitsForPlace) {
        h.controller.repeat(reverse: h._repeatReverse!);
      }
    }
  }
}

/// One MT-08 budget for the page under it (T-045). Page shells put it at the
/// page root; a [MotionHandle] built outside any scope is not capped.
class MotionBudgetScope extends StatefulWidget {
  /// Creates the scope.
  const MotionBudgetScope({super.key, required this.child});

  /// The page.
  final Widget child;

  /// The budget of the nearest scope, or `null` without one. Reading it does
  /// not make [context] depend on the scope (the budget never changes).
  static MotionBudget? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MotionBudgetMarker>()?.budget;

  @override
  State<MotionBudgetScope> createState() => _MotionBudgetScopeState();
}

class _MotionBudgetScopeState extends State<MotionBudgetScope> {
  final MotionBudget _budget = MotionBudget._();

  @override
  Widget build(BuildContext context) =>
      _MotionBudgetMarker(budget: _budget, child: widget.child);
}

class _MotionBudgetMarker extends InheritedWidget {
  const _MotionBudgetMarker({required this.budget, required super.child});

  final MotionBudget budget;

  @override
  bool updateShouldNotify(_MotionBudgetMarker oldWidget) =>
      !identical(oldWidget.budget, budget);
}

/// SV-01: plays [handles] that start in the same frame in the order of
/// [sv01Priority]; rows not in SV-01 follow in the given order. With a page
/// budget the lowest-priority rows are the ones done at once (MT-08).
void forwardInPriorityOrder(Iterable<MotionHandle> handles) {
  int rank(MotionHandle h) {
    final int i = sv01Priority.indexOf(h.id);
    return i < 0 ? sv01Priority.length : i;
  }

  final List<MotionHandle> given = handles.toList();
  final List<MotionHandle> ordered = List<MotionHandle>.of(given)
    ..sort((MotionHandle a, MotionHandle b) {
      final int byRank = rank(a).compareTo(rank(b));
      // List.sort is not stable; keep the given order inside one rank.
      return byRank != 0 ? byRank : given.indexOf(a).compareTo(given.indexOf(b));
    });
  for (final MotionHandle h in ordered) {
    h.forward();
  }
}
