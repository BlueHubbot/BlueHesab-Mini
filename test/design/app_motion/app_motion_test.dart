// Tests of `app_motion` slice 1 (T-037): token values (section 4-2),
// catalog against table 4-3 of the spec file, LP-01, MT-02, RM-01, RM-02.
//
// The spec and the token JSON are read from the repository, so a drift in
// either fails here (MT-11: a row starts in the spec).

import 'dart:convert';
import 'dart:io';

import 'package:bluehesab_mini/design/app_motion/app_motion.dart';
import 'package:bluehesab_mini/design/tokens/design_tokens.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const String _specPath = 'docs/design/ui-spec/04-motion.md';
const String _tokensPath = 'design/tokens/design_tokens.json';

/// One row of table 4-3 as written in the spec.
final class _SpecRow {
  _SpecRow(this.id, this.whatMoves, this.timing, this.meaning, this.reduced);

  final String id;
  final String whatMoves;
  final String timing;
  final String meaning;
  final String reduced;
}

List<_SpecRow> _readTable() {
  final List<_SpecRow> rows = <_SpecRow>[];
  for (final String line in File(_specPath).readAsLinesSync()) {
    if (!line.startsWith('| `MO-')) {
      continue;
    }
    final List<String> cells =
        line.split('|').map((String c) => c.trim()).toList();
    // ['', id, event, what moves, duration and curve, meaning, reduced, '']
    expect(cells.length, 8, reason: 'table 4-3 layout changed: $line');
    rows.add(_SpecRow(
      cells[1].replaceAll('`', ''),
      cells[3],
      cells[4],
      cells[5],
      cells[6],
    ));
  }
  return rows;
}

final RegExp _backticked = RegExp('`([^`]+)`');

Set<String> _ticks(String cell) =>
    _backticked.allMatches(cell).map((Match m) => m.group(1)!).toSet();

final Set<String> _motionNames = <String>{
  for (final MotionToken t in MotionToken.values) t.specName,
  for (final CurveToken c in CurveToken.values) c.specName,
};

Set<String> _timingNames(Iterable<MotionTiming> timings, {bool mt03 = true}) =>
    <String>{
      for (final MotionTiming t in timings) ...<String>[
        t.duration.specName,
        if (t.curve != null && (mt03 || !t.curveFromMt03)) t.curve!.specName,
      ],
    };

const Map<String, ReducedBehavior> _reducedWords = <String, ReducedBehavior>{
  'همان': ReducedBehavior.same,
  'محو': ReducedBehavior.fade,
  'آنی': ReducedBehavior.instant,
  'ایستا': ReducedBehavior.still,
};

const Map<String, MotionMeaning> _meaningWords = <String, MotionMeaning>{
  'وضعیت': MotionMeaning.state,
  'مکان': MotionMeaning.place,
  'بازخورد': MotionMeaning.feedback,
  'انتظار': MotionMeaning.waiting,
};

Iterable<(MotionSpec, MotionPhase)> _allPhases() sync* {
  for (final MotionSpec spec in motionCatalog.values) {
    for (final MotionPhase p in spec.phases.keys) {
      yield (spec, p);
    }
    for (final MotionPhase p in spec.detailPhases.keys) {
      yield (spec, p);
    }
  }
}

void main() {
  group('token values (section 4-2)', () {
    final Map<String, dynamic> motion =
        (jsonDecode(File(_tokensPath).readAsStringSync())
            as Map<String, dynamic>)['motion'] as Map<String, dynamic>;
    final Map<String, dynamic> jsonDurations = <String, dynamic>{
      ...motion['duration'] as Map<String, dynamic>,
      ...motion['timing'] as Map<String, dynamic>,
    };

    test('every JSON duration and timing token has exactly one MotionToken',
        () {
      expect(
        MotionToken.values.map((MotionToken t) => t.specName).toSet(),
        jsonDurations.keys.toSet(),
      );
      expect(MotionToken.values.length, jsonDurations.length);
    });

    test('MotionToken values equal design_tokens.json', () {
      for (final MotionToken t in MotionToken.values) {
        expect(t.duration.inMilliseconds, jsonDurations[t.specName],
            reason: t.specName);
      }
    });

    test('curves equal design_tokens.json; linear is Curves.linear', () {
      final Map<String, dynamic> curves =
          motion['curve'] as Map<String, dynamic>;
      expect(curves.keys.toSet(), <String>{'standard', 'decelerate', 'accelerate'});
      for (final CurveToken c in CurveToken.values) {
        if (c == CurveToken.linear) {
          expect(c.curve, same(Curves.linear));
          continue;
        }
        final Cubic cubic = c.curve as Cubic;
        final List<num> expected =
            (curves[c.specName] as List<dynamic>).cast<num>();
        expect(<double>[cubic.a, cubic.b, cubic.c, cubic.d],
            expected.map((num n) => n.toDouble()).toList(),
            reason: c.specName);
      }
    });

    test('AppMotion getters (section 4-2 sample) read DesignTokens', () {
      const AppMotion m = AppMotion(reduced: false);
      expect(m.instant, DesignTokens.durationInstant);
      expect(m.micro, DesignTokens.durationMicro);
      expect(m.exit, DesignTokens.durationExit);
      expect(m.base, DesignTokens.durationBase);
      expect(m.enter, DesignTokens.durationEnter);
      expect(m.max, DesignTokens.durationMax);
      expect(m.ringStagger, DesignTokens.durationRingStagger);
      expect(m.spinnerLoop, DesignTokens.durationSpinnerLoop);
      expect(m.skeletonLoop, DesignTokens.durationSkeletonLoop);
      expect(m.breatheLoop, DesignTokens.durationBreatheLoop);
      expect(m.skeletonDelay, DesignTokens.timingSkeletonDelay);
      expect(m.toastVisible, DesignTokens.timingToastVisible);
      expect(m.toastUndoVisible, DesignTokens.timingToastUndoVisible);
      expect(m.tooltipDelay, DesignTokens.timingTooltipDelay);
      expect(m.curveStandard, DesignTokens.curveStandard);
      expect(m.curveDecelerate, DesignTokens.curveDecelerate);
      expect(m.curveAccelerate, DesignTokens.curveAccelerate);
    });
  });

  group('catalog against table 4-3', () {
    final List<_SpecRow> table = _readTable();

    test('exactly MO-01 … MO-19, in order', () {
      expect(table.map((_SpecRow r) => r.id).toList(),
          MotionId.values.map((MotionId id) => id.specId).toList());
      expect(motionCatalog.keys.toList(), MotionId.values);
      for (final MapEntry<MotionId, MotionSpec> e in motionCatalog.entries) {
        expect(e.value.id, e.key);
      }
    });

    test('column "duration and curve" = the phase tokens of each row', () {
      for (final _SpecRow row in table) {
        final MotionSpec spec = motionSpec(
            MotionId.values.firstWhere((MotionId id) => id.specId == row.id));
        expect(_timingNames(spec.phases.values), _ticks(row.timing),
            reason: row.id);
      }
    });

    test('column "what moves" = detail phases, stagger and delay', () {
      for (final _SpecRow row in table) {
        final MotionSpec spec = motionSpec(
            MotionId.values.firstWhere((MotionId id) => id.specId == row.id));
        final Set<String> expected =
            _ticks(row.whatMoves).intersection(_motionNames);
        final Set<String> actual = <String>{
          ..._timingNames(spec.detailPhases.values, mt03: false),
          if (spec.stagger != null) spec.stagger!.specName,
          if (spec.delay != null) spec.delay!.specName,
        };
        expect(actual, expected, reason: row.id);
      }
    });

    test('only MO-11 highlight takes its curve from MT-03', () {
      final List<String> fromMt03 = <String>[
        for (final (MotionSpec s, MotionPhase p) in _allPhases())
          if (s.timing(p)!.curveFromMt03) '${s.id.specId} ${p.name}',
      ];
      expect(fromMt03, <String>['MO-11 highlight']);
    });

    test('column "meaning" (MT-01)', () {
      for (final _SpecRow row in table) {
        final MotionSpec spec = motionSpec(
            MotionId.values.firstWhere((MotionId id) => id.specId == row.id));
        expect(spec.meaning, _meaningWords[row.meaning], reason: row.id);
      }
    });

    test('column "reduced motion": first word; MO-12 crossfade keeps «همان»',
        () {
      for (final _SpecRow row in table) {
        final MotionSpec spec = motionSpec(
            MotionId.values.firstWhere((MotionId id) => id.specId == row.id));
        final String first = row.reduced.split(RegExp(r'\s+')).first;
        expect(spec.reduced, _reducedWords[first], reason: row.id);
      }
      final _SpecRow mo12 = table.firstWhere((_SpecRow r) => r.id == 'MO-12');
      expect(mo12.reduced, contains('crossfade همان'));
      expect(motionSpec(MotionId.mo12).reducedFor(MotionPhase.crossfade),
          ReducedBehavior.same);
      expect(motionSpec(MotionId.mo12).reducedFor(MotionPhase.loop),
          ReducedBehavior.still);
    });

    test('LP-01: only MO-12, MO-13 and MO-17 loop', () {
      expect(
        motionCatalog.values
            .where((MotionSpec s) => s.loops)
            .map((MotionSpec s) => s.id)
            .toList(),
        <MotionId>[MotionId.mo12, MotionId.mo13, MotionId.mo17],
      );
    });

    test('MT-02: non-loop animations last 200–350 ms; micro only MO-01, MO-13',
        () {
      for (final (MotionSpec s, MotionPhase p) in _allPhases()) {
        final MotionTiming t = s.timing(p)!;
        if (p == MotionPhase.loop || t.curve == null) {
          continue;
        }
        final int ms = t.duration.duration.inMilliseconds;
        if (t.duration == MotionToken.micro) {
          expect(<MotionId>[MotionId.mo01, MotionId.mo13], contains(s.id),
              reason: '${s.id.specId} ${p.name}');
          continue;
        }
        expect(ms, inInclusiveRange(200, 350),
            reason: '${s.id.specId} ${p.name}');
      }
    });
  });

  group('RM-01', () {
    test('truth table', () {
      for (final bool system in <bool>[false, true]) {
        expect(
            resolveReduced(ReducedMotionSetting.on,
                systemDisableAnimations: system),
            isTrue);
        expect(
            resolveReduced(ReducedMotionSetting.off,
                systemDisableAnimations: system),
            isFalse);
        expect(
            resolveReduced(ReducedMotionSetting.followSystem,
                systemDisableAnimations: system),
            system);
      }
    });

    testWidgets('context.motion follows scope and system, changes at once',
        (WidgetTester tester) async {
      late AppMotion seen;
      Widget app({ReducedMotionSetting? setting, required bool system}) {
        final Widget probe = Builder(builder: (BuildContext context) {
          seen = context.motion;
          return const SizedBox();
        });
        return MediaQuery(
          data: MediaQueryData(disableAnimations: system),
          child: setting == null
              ? probe
              : AppMotionScope(setting: setting, child: probe),
        );
      }

      // No scope: RM-01 default is followSystem.
      await tester.pumpWidget(app(system: true));
      expect(seen.reduced, isTrue);
      await tester.pumpWidget(app(system: false));
      expect(seen.reduced, isFalse);

      for (final ReducedMotionSetting s in ReducedMotionSetting.values) {
        for (final bool system in <bool>[false, true]) {
          await tester.pumpWidget(app(setting: s, system: system));
          expect(seen.reduced,
              resolveReduced(s, systemDisableAnimations: system),
              reason: '$s system=$system');
        }
      }
    });
  });

  group('RM-02 resolve', () {
    test('reduced off: every phase as catalogued', () {
      for (final (MotionSpec s, MotionPhase p) in _allPhases()) {
        final MotionTiming t = s.timing(p)!;
        final ResolvedMotion r = resolveMotion(s.id, p, reduced: false);
        final String why = '${s.id.specId} ${p.name}';
        expect(r.duration, t.duration.duration, reason: why);
        expect(r.curve, t.curve?.curve, reason: why);
        expect(r.shown, isTrue, reason: why);
        expect(r.loops, p == MotionPhase.loop, reason: why);
        expect(r.animates, t.curve != null, reason: why);
      }
    });

    test('reduced on: same / fade / instant / still', () {
      for (final (MotionSpec s, MotionPhase p) in _allPhases()) {
        final MotionTiming t = s.timing(p)!;
        final ResolvedMotion r = resolveMotion(s.id, p, reduced: true);
        final String why = '${s.id.specId} ${p.name}';
        expect(r.loops, isFalse, reason: why);
        if (t.curve == null) {
          // Stay time (MO-10 hold): unchanged (MT-07, RM-04).
          expect(r.duration, t.duration.duration, reason: why);
          expect(r.animates, isFalse, reason: why);
          continue;
        }
        expect(r.movesOrScales, isFalse, reason: why);
        switch (s.reducedFor(p)) {
          case ReducedBehavior.same:
            expect(r.duration, t.duration.duration, reason: why);
            expect(r.curve, t.curve!.curve, reason: why);
            expect(r.animates, isTrue, reason: why);
          case ReducedBehavior.fade:
            expect(r.duration, DesignTokens.durationExit, reason: why);
            expect(r.curve, t.curve!.curve, reason: why);
            expect(r.animates, isTrue, reason: why);
          case ReducedBehavior.instant:
          case ReducedBehavior.still:
            expect(r.duration, DesignTokens.durationInstant, reason: why);
            expect(r.animates, isFalse, reason: why);
        }
        expect(r.shown, !s.reducedHides.contains(p), reason: why);
      }
    });

    test('RM-03 hidden elements: MO-11 highlight, MO-13 spinner, MO-18 halo',
        () {
      expect(resolveMotion(MotionId.mo11, MotionPhase.highlight, reduced: true).shown,
          isFalse);
      expect(resolveMotion(MotionId.mo13, MotionPhase.loop, reduced: true).shown,
          isFalse);
      expect(resolveMotion(MotionId.mo18, MotionPhase.run, reduced: true).shown,
          isFalse);
      // The still views that stay visible: Skeleton tiles, PulseDot core.
      expect(resolveMotion(MotionId.mo12, MotionPhase.loop, reduced: true).shown,
          isTrue);
      expect(resolveMotion(MotionId.mo17, MotionPhase.loop, reduced: true).shown,
          isTrue);
    });

    test('a phase the row lacks is an error', () {
      expect(() => resolveMotion(MotionId.mo01, MotionPhase.loop, reduced: false),
          throwsArgumentError);
    });

    test('context.motion.resolve uses its reduced flag', () {
      expect(const AppMotion(reduced: true).resolve(MotionId.mo05, MotionPhase.enter),
          resolveMotion(MotionId.mo05, MotionPhase.enter, reduced: true));
      expect(const AppMotion(reduced: false).resolve(MotionId.mo05, MotionPhase.enter),
          resolveMotion(MotionId.mo05, MotionPhase.enter, reduced: false));
    });
  });
}
