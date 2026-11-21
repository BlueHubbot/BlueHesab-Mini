// Tests of `app_motion` slice 7 (T-045): MT-08 — at most three non-loop
// animations run at once on a page; a fourth is done at once (SV-01, D0) —
// and the SV-01 priority order MO-14 ← MO-15 ← MO-11 ← MO-18.

import 'dart:async';

import 'package:bluehesab_mini/design/app_motion/app_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/motion_probe.dart';

/// A page element that builds handles on demand, all on its own context.
class _Host extends StatefulWidget {
  const _Host({super.key});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with TickerProviderStateMixin {
  final List<MotionHandle> _handles = <MotionHandle>[];

  MotionHandle make(MotionId id, MotionPhase phase) {
    final MotionHandle h = MotionHandle(
      context: context,
      vsync: this,
      id: id,
      phase: phase,
      reduced: context.motion.reduced,
    );
    h.track(MotionProperty.progress, h.animation);
    _handles.add(h);
    return h;
  }

  void drop(MotionHandle h) {
    _handles.remove(h);
    h.dispose();
  }

  @override
  void dispose() {
    for (final MotionHandle h in _handles) {
      h.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: Key('leaf'), width: 10, height: 10);
}

const MotionProbe _probe = MotionProbe();

Finder get _host => find.byType(_Host);

Future<_HostState> _pumpHost(
  WidgetTester tester, {
  bool scope = true,
  ReducedMotionSetting setting = ReducedMotionSetting.off,
}) async {
  final GlobalKey<_HostState> key = GlobalKey<_HostState>();
  final Widget host = _Host(key: key);
  await tester.pumpWidget(AppMotionScope(
    setting: setting,
    child: scope ? MotionBudgetScope(child: host) : host,
  ));
  return key.currentState!;
}

/// Plays [h] forward without awaiting (the test moves time itself).
void _play(MotionHandle h) => unawaited(h.forward());

void main() {
  testWidgets('MT-08: a fourth MO-11 is done at once; the count ends at 0',
      (WidgetTester tester) async {
    final _HostState s = await _pumpHost(tester);
    final List<MotionHandle> hs = <MotionHandle>[
      for (int i = 0; i < 4; i++) s.make(MotionId.mo11, MotionPhase.enter),
    ];
    hs.forEach(_play);
    await tester.pump();

    expect(_probe.activeCount(_host), motionPageCap);
    expect(MotionBudgetScope.maybeOf(s.context)!.running, 3);
    for (final MotionHandle h in hs.take(3)) {
      expect(h.controller.isAnimating, isTrue);
      expect(h.controller.value, lessThan(1));
    }
    expect(hs[3].controller.isAnimating, isFalse);
    expect(hs[3].controller.value, 1);

    // reverse() is capped the same way: start value at once.
    unawaited(hs[3].reverse());
    await tester.pump();
    expect(hs[3].controller.isAnimating, isFalse);
    expect(hs[3].controller.value, 0);
    expect(_probe.activeCount(_host), 3);

    await tester.pump(MotionToken.base.duration);
    expect(_probe.activeCount(_host), 0);
    for (final MotionHandle h in hs.take(3)) {
      expect(h.controller.value, 1);
    }
  });

  testWidgets('MT-08, MR-03: a place frees when a row ends, is cut or goes',
      (WidgetTester tester) async {
    final _HostState s = await _pumpHost(tester);
    final List<MotionHandle> hs = <MotionHandle>[
      for (int i = 0; i < 3; i++) s.make(MotionId.mo11, MotionPhase.enter),
    ];
    hs.forEach(_play);
    await tester.pump();
    expect(_probe.activeCount(_host), 3);

    final MotionHandle blocked = s.make(MotionId.mo11, MotionPhase.enter);
    _play(blocked);
    await tester.pump();
    expect(blocked.controller.isAnimating, isFalse);

    // Cut (MR-03): the cut row no longer runs, so a new one gets its place.
    hs[0].interrupt();
    final MotionHandle afterCut = s.make(MotionId.mo11, MotionPhase.enter);
    _play(afterCut);
    await tester.pump();
    expect(afterCut.controller.isAnimating, isTrue);
    expect(_probe.activeCount(_host), 3);

    // Disposed: leaves the budget.
    s.drop(hs[1]);
    final MotionHandle afterDrop = s.make(MotionId.mo11, MotionPhase.enter);
    _play(afterDrop);
    await tester.pump();
    expect(afterDrop.controller.isAnimating, isTrue);
    expect(_probe.activeCount(_host), 3);

    // Ended: after the row's time every place is free again.
    await tester.pump(MotionToken.base.duration);
    expect(_probe.activeCount(_host), 0);
    final List<MotionHandle> next = <MotionHandle>[
      for (int i = 0; i < 3; i++) s.make(MotionId.mo11, MotionPhase.enter),
    ];
    next.forEach(_play);
    await tester.pump();
    expect(_probe.activeCount(_host), 3);
    await tester.pump(MotionToken.base.duration);
  });

  testWidgets('MT-08: a running loop (MO-12) takes no place',
      (WidgetTester tester) async {
    final _HostState s = await _pumpHost(tester);
    final MotionHandle loop = s.make(MotionId.mo12, MotionPhase.loop);
    unawaited(loop.repeat(reverse: true));
    final List<MotionHandle> hs = <MotionHandle>[
      for (int i = 0; i < 4; i++) s.make(MotionId.mo11, MotionPhase.enter),
    ];
    hs.forEach(_play);
    await tester.pump();

    expect(_probe.activeLoopCount(_host), 1);
    expect(_probe.activeCount(_host), 3);
    expect(hs[3].controller.isAnimating, isFalse);
    expect(hs[3].controller.value, 1);
    await tester.pump(MotionToken.base.duration);
    expect(_probe.activeCount(_host), 0);
    expect(_probe.activeLoopCount(_host), 1);
  });

  testWidgets('SV-01: MO-14, MO-15, MO-11 animate; MO-18 is done at once',
      (WidgetTester tester) async {
    final _HostState s = await _pumpHost(tester);
    final MotionHandle mo18 = s.make(MotionId.mo18, MotionPhase.run);
    final MotionHandle mo11 = s.make(MotionId.mo11, MotionPhase.enter);
    final MotionHandle mo15 = s.make(MotionId.mo15, MotionPhase.update);
    final MotionHandle mo14 = s.make(MotionId.mo14, MotionPhase.run);
    forwardInPriorityOrder(<MotionHandle>[mo18, mo11, mo15, mo14]);
    await tester.pump();

    expect(mo14.controller.isAnimating, isTrue);
    expect(mo15.controller.isAnimating, isTrue);
    expect(mo11.controller.isAnimating, isTrue);
    expect(mo18.controller.isAnimating, isFalse);
    expect(mo18.controller.value, 1);
    expect(_probe.activeCount(_host), 3);
    await tester.pump(MotionToken.max.duration);
    expect(_probe.activeCount(_host), 0);
  });

  testWidgets('SV-01: rows outside SV-01 follow, in the given order',
      (WidgetTester tester) async {
    final _HostState s = await _pumpHost(tester);
    final MotionHandle a = s.make(MotionId.mo10, MotionPhase.enter);
    final MotionHandle b = s.make(MotionId.mo09, MotionPhase.enter);
    final MotionHandle c = s.make(MotionId.mo14, MotionPhase.run);
    final MotionHandle d = s.make(MotionId.mo10, MotionPhase.enter);
    forwardInPriorityOrder(<MotionHandle>[a, b, c, d]);
    await tester.pump();

    expect(c.controller.isAnimating, isTrue);
    expect(a.controller.isAnimating, isTrue);
    expect(b.controller.isAnimating, isTrue);
    expect(d.controller.isAnimating, isFalse);
    expect(d.controller.value, 1);
    await tester.pump(MotionToken.max.duration);
  });

  testWidgets('RM-02: «آنی» takes no place; «محو» crossfades count',
      (WidgetTester tester) async {
    final _HostState s =
        await _pumpHost(tester, setting: ReducedMotionSetting.on);
    final List<MotionHandle> instant = <MotionHandle>[
      for (int i = 0; i < 3; i++) s.make(MotionId.mo11, MotionPhase.enter),
    ];
    instant.forEach(_play);
    await tester.pump();
    for (final MotionHandle h in instant) {
      expect(h.controller.isAnimating, isFalse);
      expect(h.controller.value, 1);
    }
    expect(_probe.activeCount(_host), 0);

    final List<MotionHandle> fades = <MotionHandle>[
      for (int i = 0; i < 4; i++) s.make(MotionId.mo10, MotionPhase.enter),
    ];
    for (final MotionHandle h in fades) {
      expect(h.resolved.animates, isTrue);
      expect(h.resolved.movesOrScales, isFalse);
    }
    fades.forEach(_play);
    await tester.pump();
    expect(_probe.activeCount(_host), 3);
    expect(fades[3].controller.isAnimating, isFalse);
    expect(fades[3].controller.value, 1);
    await tester.pump(MotionToken.exit.duration);
    expect(_probe.activeCount(_host), 0);
  });

  testWidgets('without a MotionBudgetScope nothing is capped',
      (WidgetTester tester) async {
    final _HostState s = await _pumpHost(tester, scope: false);
    expect(MotionBudgetScope.maybeOf(s.context), isNull);
    final List<MotionHandle> hs = <MotionHandle>[
      for (int i = 0; i < 4; i++) s.make(MotionId.mo11, MotionPhase.enter),
    ];
    hs.forEach(_play);
    await tester.pump();
    expect(_probe.activeCount(_host), 4);
    await tester.pump(MotionToken.base.duration);
    expect(_probe.activeCount(_host), 0);
  });
}
