// Table 4-3 as data (MT-11, T-037).
//
// One entry per MO row. `phases` hold exactly the tokens of the column
// "duration and curve"; `detailPhases`, `stagger` and `delay` hold the
// tokens the column "what moves" names. Adding a row starts in the spec
// (MT-11); the test reads table 4-3 and fails on any drift.

import 'package:bluehesab_mini/design/app_motion/src/motion_tokens.dart';
import 'package:flutter/foundation.dart' show immutable;

/// The registered animations of table 4-3.
enum MotionId {
  /// MO-01 hover, focus and pressed.
  mo01,

  /// MO-02 switch, checkbox and radio.
  mo02,

  /// MO-03 selection indicator.
  mo03,

  /// MO-04 top-level destination change.
  mo04,

  /// MO-05 detail page push.
  mo05,

  /// MO-06 back from a detail page.
  mo06,

  /// MO-07 side panel.
  mo07,

  /// MO-08 bottom sheet.
  mo08,

  /// MO-09 dialog.
  mo09,

  /// MO-10 toast.
  mo10,

  /// MO-11 list row insert or remove.
  mo11,

  /// MO-12 skeleton.
  mo12,

  /// MO-13 button in progress.
  mo13,

  /// MO-14 SummaryCard count.
  mo14,

  /// MO-15 DayRing.
  mo15,

  /// MO-16 chart.
  mo16,

  /// MO-17 PulseDot thinking.
  mo17,

  /// MO-18 PulseDot after a real save.
  mo18,

  /// MO-19 light/dark theme change.
  mo19;

  /// The spec ID, for example `MO-05`.
  String get specId => 'MO-${(index + 1).toString().padLeft(2, '0')}';
}

/// A phase of one row. Rows with one timing use [run].
enum MotionPhase {
  /// The row's only timing.
  run,

  /// Entering (or a list row being inserted, MO-11).
  enter,

  /// Leaving (or a list row being removed, MO-11).
  exit,

  /// First show of the page (MR-01).
  firstShow,

  /// Update caused by the user's own action (MR-01).
  update,

  /// Endless loop (LP-01).
  loop,

  /// Crossfade to content (MO-12).
  crossfade,

  /// Bottom sheet settling after a drag (MO-08).
  settle,

  /// Fresh-row highlight fading out (MO-11).
  highlight,

  /// Toast stay time (MO-10), not an animation.
  hold,

  /// Toast-with-undo stay time (MO-10), not an animation.
  holdUndo,
}

/// The four meanings of MT-01 (column "meaning").
enum MotionMeaning {
  /// Something changed.
  state,

  /// Where something came from or went to.
  place,

  /// The app heard the user.
  feedback,

  /// Something is in progress.
  waiting,
}

/// The four reduced-motion behaviours of RM-02.
enum ReducedBehavior {
  /// Only colour or opacity changes; runs unchanged.
  same,

  /// Movement and scale removed; opacity only, with `exit`.
  fade,

  /// End state at once, with `instant`.
  instant,

  /// Loop stopped; the still view of RM-03.
  still,
}

/// One timing: a duration token and, for animations, a curve token.
@immutable
final class MotionTiming {
  /// Creates a timing.
  const MotionTiming(this.duration, this.curve, {this.curveFromMt03 = false});

  /// Creates a stay time that is not an animation (no curve).
  const MotionTiming.hold(this.duration)
      : curve = null,
        curveFromMt03 = false;

  /// Duration token.
  final MotionToken duration;

  /// Curve token; null for a stay time.
  final CurveToken? curve;

  /// True when table 4-3 gives no curve and the curve is read from MT-03
  /// (curve by direction); listed in the T-037 handoff for Agent 1.
  final bool curveFromMt03;
}

/// One row of table 4-3.
@immutable
final class MotionSpec {
  /// Creates a row.
  const MotionSpec({
    required this.id,
    required this.meaning,
    required this.reduced,
    required this.phases,
    this.detailPhases = const <MotionPhase, MotionTiming>{},
    this.stagger,
    this.delay,
    this.reducedOverrides = const <MotionPhase, ReducedBehavior>{},
    this.reducedHides = const <MotionPhase>{},
  });

  /// Row ID.
  final MotionId id;

  /// Column "meaning".
  final MotionMeaning meaning;

  /// Column "reduced motion" (first word).
  final ReducedBehavior reduced;

  /// Timings named in the column "duration and curve".
  final Map<MotionPhase, MotionTiming> phases;

  /// Timings named in the column "what moves".
  final Map<MotionPhase, MotionTiming> detailPhases;

  /// Start gap between items (MO-15 `ring-stagger`).
  final MotionToken? stagger;

  /// Show only after this long (MO-12, MO-13 `skeleton-delay`).
  final MotionToken? delay;

  /// Phases whose reduced behaviour differs from [reduced] (the
  /// parenthesis of the column, MO-12 crossfade).
  final Map<MotionPhase, ReducedBehavior> reducedOverrides;

  /// Phases whose moving element is not shown at all with reduced motion
  /// (MO-11 highlight, MO-13 spinner, MO-18 halo; RM-03).
  final Set<MotionPhase> reducedHides;

  /// The timing of [phase], or null when the row has no such phase.
  MotionTiming? timing(MotionPhase phase) =>
      phases[phase] ?? detailPhases[phase];

  /// Reduced behaviour of [phase].
  ReducedBehavior reducedFor(MotionPhase phase) =>
      reducedOverrides[phase] ?? reduced;

  /// True when the row has an endless loop (LP-01).
  bool get loops => phases.containsKey(MotionPhase.loop);
}

const MotionTiming _microStandard =
    MotionTiming(MotionToken.micro, CurveToken.standard);
const MotionTiming _exitStandard =
    MotionTiming(MotionToken.exit, CurveToken.standard);
const MotionTiming _exitAccelerate =
    MotionTiming(MotionToken.exit, CurveToken.accelerate);
const MotionTiming _baseStandard =
    MotionTiming(MotionToken.base, CurveToken.standard);
const MotionTiming _baseDecelerate =
    MotionTiming(MotionToken.base, CurveToken.decelerate);
const MotionTiming _enterDecelerate =
    MotionTiming(MotionToken.enter, CurveToken.decelerate);
const MotionTiming _maxDecelerate =
    MotionTiming(MotionToken.max, CurveToken.decelerate);

/// Table 4-3, in row order.
const Map<MotionId, MotionSpec> motionCatalog = <MotionId, MotionSpec>{
  MotionId.mo01: MotionSpec(
    id: MotionId.mo01,
    meaning: MotionMeaning.feedback,
    reduced: ReducedBehavior.same,
    phases: <MotionPhase, MotionTiming>{MotionPhase.run: _microStandard},
  ),
  MotionId.mo02: MotionSpec(
    id: MotionId.mo02,
    meaning: MotionMeaning.state,
    reduced: ReducedBehavior.instant,
    phases: <MotionPhase, MotionTiming>{MotionPhase.run: _exitStandard},
  ),
  MotionId.mo03: MotionSpec(
    id: MotionId.mo03,
    meaning: MotionMeaning.place,
    reduced: ReducedBehavior.instant,
    phases: <MotionPhase, MotionTiming>{MotionPhase.run: _baseStandard},
  ),
  MotionId.mo04: MotionSpec(
    id: MotionId.mo04,
    meaning: MotionMeaning.place,
    reduced: ReducedBehavior.same,
    phases: <MotionPhase, MotionTiming>{MotionPhase.run: _exitStandard},
  ),
  MotionId.mo05: MotionSpec(
    id: MotionId.mo05,
    meaning: MotionMeaning.place,
    reduced: ReducedBehavior.fade,
    phases: <MotionPhase, MotionTiming>{MotionPhase.enter: _enterDecelerate},
  ),
  MotionId.mo06: MotionSpec(
    id: MotionId.mo06,
    meaning: MotionMeaning.place,
    reduced: ReducedBehavior.fade,
    phases: <MotionPhase, MotionTiming>{MotionPhase.exit: _exitAccelerate},
  ),
  MotionId.mo07: MotionSpec(
    id: MotionId.mo07,
    meaning: MotionMeaning.place,
    reduced: ReducedBehavior.fade,
    phases: <MotionPhase, MotionTiming>{
      MotionPhase.enter: _enterDecelerate,
      MotionPhase.exit: _exitAccelerate,
    },
  ),
  MotionId.mo08: MotionSpec(
    id: MotionId.mo08,
    meaning: MotionMeaning.place,
    reduced: ReducedBehavior.fade,
    phases: <MotionPhase, MotionTiming>{
      MotionPhase.enter: _enterDecelerate,
      MotionPhase.exit: _exitAccelerate,
    },
    detailPhases: <MotionPhase, MotionTiming>{
      MotionPhase.settle: _baseStandard,
    },
  ),
  MotionId.mo09: MotionSpec(
    id: MotionId.mo09,
    meaning: MotionMeaning.state,
    reduced: ReducedBehavior.fade,
    phases: <MotionPhase, MotionTiming>{
      MotionPhase.enter: _baseDecelerate,
      MotionPhase.exit: _exitAccelerate,
    },
  ),
  MotionId.mo10: MotionSpec(
    id: MotionId.mo10,
    meaning: MotionMeaning.feedback,
    reduced: ReducedBehavior.fade,
    phases: <MotionPhase, MotionTiming>{
      MotionPhase.enter: _baseDecelerate,
      MotionPhase.exit: _exitAccelerate,
      MotionPhase.hold: MotionTiming.hold(MotionToken.toastVisible),
      MotionPhase.holdUndo: MotionTiming.hold(MotionToken.toastUndoVisible),
    },
  ),
  MotionId.mo11: MotionSpec(
    id: MotionId.mo11,
    meaning: MotionMeaning.state,
    reduced: ReducedBehavior.instant,
    phases: <MotionPhase, MotionTiming>{
      MotionPhase.enter: _baseDecelerate,
      MotionPhase.exit: _exitAccelerate,
    },
    // The highlight fades "in `enter`"; the table names no curve, so MT-03
    // (in-place change) gives `standard`.
    detailPhases: <MotionPhase, MotionTiming>{
      MotionPhase.highlight: MotionTiming(
        MotionToken.enter,
        CurveToken.standard,
        curveFromMt03: true,
      ),
    },
    reducedHides: <MotionPhase>{MotionPhase.highlight},
  ),
  MotionId.mo12: MotionSpec(
    id: MotionId.mo12,
    meaning: MotionMeaning.waiting,
    reduced: ReducedBehavior.still,
    phases: <MotionPhase, MotionTiming>{
      MotionPhase.loop:
          MotionTiming(MotionToken.skeletonLoop, CurveToken.standard),
      MotionPhase.crossfade: _exitStandard,
    },
    delay: MotionToken.skeletonDelay,
    reducedOverrides: <MotionPhase, ReducedBehavior>{
      MotionPhase.crossfade: ReducedBehavior.same,
    },
  ),
  MotionId.mo13: MotionSpec(
    id: MotionId.mo13,
    meaning: MotionMeaning.waiting,
    reduced: ReducedBehavior.still,
    phases: <MotionPhase, MotionTiming>{
      MotionPhase.run: _microStandard,
      MotionPhase.loop: MotionTiming(MotionToken.spinnerLoop, CurveToken.linear),
    },
    delay: MotionToken.skeletonDelay,
    reducedHides: <MotionPhase>{MotionPhase.loop},
  ),
  MotionId.mo14: MotionSpec(
    id: MotionId.mo14,
    meaning: MotionMeaning.state,
    reduced: ReducedBehavior.instant,
    phases: <MotionPhase, MotionTiming>{MotionPhase.run: _maxDecelerate},
  ),
  MotionId.mo15: MotionSpec(
    id: MotionId.mo15,
    meaning: MotionMeaning.state,
    reduced: ReducedBehavior.instant,
    phases: <MotionPhase, MotionTiming>{
      MotionPhase.firstShow: _enterDecelerate,
      MotionPhase.update: _baseStandard,
    },
    stagger: MotionToken.ringStagger,
  ),
  MotionId.mo16: MotionSpec(
    id: MotionId.mo16,
    meaning: MotionMeaning.state,
    reduced: ReducedBehavior.instant,
    phases: <MotionPhase, MotionTiming>{
      MotionPhase.firstShow: _enterDecelerate,
    },
  ),
  MotionId.mo17: MotionSpec(
    id: MotionId.mo17,
    meaning: MotionMeaning.waiting,
    reduced: ReducedBehavior.still,
    phases: <MotionPhase, MotionTiming>{
      MotionPhase.loop:
          MotionTiming(MotionToken.breatheLoop, CurveToken.standard),
    },
  ),
  MotionId.mo18: MotionSpec(
    id: MotionId.mo18,
    meaning: MotionMeaning.feedback,
    reduced: ReducedBehavior.instant,
    phases: <MotionPhase, MotionTiming>{MotionPhase.run: _enterDecelerate},
    reducedHides: <MotionPhase>{MotionPhase.run},
  ),
  MotionId.mo19: MotionSpec(
    id: MotionId.mo19,
    meaning: MotionMeaning.state,
    reduced: ReducedBehavior.instant,
    phases: <MotionPhase, MotionTiming>{MotionPhase.run: _exitStandard},
  ),
};

/// The row of [id].
MotionSpec motionSpec(MotionId id) => motionCatalog[id]!;
