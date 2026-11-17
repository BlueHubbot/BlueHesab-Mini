// Motion tokens of section 4-2 by their spec names (T-037).
//
// Every value comes from the generated token file (TK-01, AG-05); this file
// only names them. `linear` is not a token: MT-03 allows it for the spinner
// rotation only (MO-13).

import 'package:bluehesab_mini/design/tokens/design_tokens.g.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show immutable;

/// A duration or timing token of section 4-2, by its spec name.
enum MotionToken {
  /// `instant`: show the end state with no animation (reduced motion).
  instant('instant'),

  /// `micro`: colour or opacity of interactive states only (MT-02 exception).
  micro('micro'),

  /// `exit`: exit, simple state change, crossfade.
  exit('exit'),

  /// `base`: in-place movement, small elements entering.
  base('base'),

  /// `enter`: pages and large surfaces entering, first-show drawing.
  enter('enter'),

  /// `max`: absolute ceiling of a non-loop animation; only MO-14 uses it.
  max('max'),

  /// `ring-stagger`: start gap between DayRing arcs (MO-15).
  ringStagger('ring-stagger'),

  /// `spinner-loop`: one turn of the button spinner (MO-13).
  spinnerLoop('spinner-loop'),

  /// `skeleton-loop`: one Skeleton pulse there and back (MO-12).
  skeletonLoop('skeleton-loop'),

  /// `breathe-loop`: one PulseDot breath there and back (MO-17).
  breatheLoop('breathe-loop'),

  /// `skeleton-delay`: a loading indicator shows only after this long.
  skeletonDelay('skeleton-delay'),

  /// `toast-visible`: how long a plain Toast stays.
  toastVisible('toast-visible'),

  /// `toast-undo-visible`: how long a Toast with undo stays.
  toastUndoVisible('toast-undo-visible'),

  /// `tooltip-delay`: hover time before a Tooltip; not changed by reduced
  /// motion (TP-04).
  tooltipDelay('tooltip-delay');

  const MotionToken(this.specName);

  /// The token's name in section 4-2 and in `design_tokens.json`.
  final String specName;

  /// The token's value from the generated token file.
  Duration get duration => switch (this) {
        MotionToken.instant => DesignTokens.durationInstant,
        MotionToken.micro => DesignTokens.durationMicro,
        MotionToken.exit => DesignTokens.durationExit,
        MotionToken.base => DesignTokens.durationBase,
        MotionToken.enter => DesignTokens.durationEnter,
        MotionToken.max => DesignTokens.durationMax,
        MotionToken.ringStagger => DesignTokens.durationRingStagger,
        MotionToken.spinnerLoop => DesignTokens.durationSpinnerLoop,
        MotionToken.skeletonLoop => DesignTokens.durationSkeletonLoop,
        MotionToken.breatheLoop => DesignTokens.durationBreatheLoop,
        MotionToken.skeletonDelay => DesignTokens.timingSkeletonDelay,
        MotionToken.toastVisible => DesignTokens.timingToastVisible,
        MotionToken.toastUndoVisible => DesignTokens.timingToastUndoVisible,
        MotionToken.tooltipDelay => DesignTokens.timingTooltipDelay,
      };
}

/// A curve of section 4-2 (plus `linear`, MT-03), by its spec name.
enum CurveToken {
  /// `standard`: in-place change.
  standard('standard'),

  /// `decelerate`: entering.
  decelerate('decelerate'),

  /// `accelerate`: leaving.
  accelerate('accelerate'),

  /// `linear`: spinner rotation only (MT-03, MO-13).
  linear('linear');

  const CurveToken(this.specName);

  /// The curve's name in section 4-2 and table 4-3.
  final String specName;

  /// The curve value.
  Curve get curve => switch (this) {
        CurveToken.standard => DesignTokens.curveStandard,
        CurveToken.decelerate => DesignTokens.curveDecelerate,
        CurveToken.accelerate => DesignTokens.curveAccelerate,
        CurveToken.linear => Curves.linear,
      };
}

/// The value behind `context.motion` (section 4-2 sample): token values
/// plus whether reduced motion is on (RM-01).
@immutable
final class AppMotion {
  /// Creates the motion values for one context.
  const AppMotion({required this.reduced});

  /// True when reduced motion applies (RM-01).
  final bool reduced;

  /// `instant` (0 ms).
  Duration get instant => MotionToken.instant.duration;

  /// `micro`.
  Duration get micro => MotionToken.micro.duration;

  /// `exit`.
  Duration get exit => MotionToken.exit.duration;

  /// `base`.
  Duration get base => MotionToken.base.duration;

  /// `enter`.
  Duration get enter => MotionToken.enter.duration;

  /// `max`.
  Duration get max => MotionToken.max.duration;

  /// `ring-stagger`.
  Duration get ringStagger => MotionToken.ringStagger.duration;

  /// `spinner-loop`.
  Duration get spinnerLoop => MotionToken.spinnerLoop.duration;

  /// `skeleton-loop`.
  Duration get skeletonLoop => MotionToken.skeletonLoop.duration;

  /// `breathe-loop`.
  Duration get breatheLoop => MotionToken.breatheLoop.duration;

  /// `skeleton-delay`.
  Duration get skeletonDelay => MotionToken.skeletonDelay.duration;

  /// `toast-visible`.
  Duration get toastVisible => MotionToken.toastVisible.duration;

  /// `toast-undo-visible`.
  Duration get toastUndoVisible => MotionToken.toastUndoVisible.duration;

  /// `tooltip-delay`.
  Duration get tooltipDelay => MotionToken.tooltipDelay.duration;

  /// `standard` curve.
  Curve get curveStandard => CurveToken.standard.curve;

  /// `decelerate` curve.
  Curve get curveDecelerate => CurveToken.decelerate.curve;

  /// `accelerate` curve.
  Curve get curveAccelerate => CurveToken.accelerate.curve;

  @override
  bool operator ==(Object other) =>
      other is AppMotion && other.reduced == reduced;

  @override
  int get hashCode => reduced.hashCode;

  @override
  String toString() => 'AppMotion(reduced: $reduced)';
}
