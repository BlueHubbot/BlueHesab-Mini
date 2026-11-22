// Tests of `app_motion` slice 9 (T-047): LP-04 — at most two loops are in
// view on a page; a further loop waits still at its start and starts by
// itself when a place frees (D0, oldest first); a MotionLoopGroup is
// one loop; loops are counted apart from MT-08; RM-02 «ایستا» loops take no
// place.

import 'dart:async';

import 'package:bluehesab_mini/design/app_motion/app_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/motion_probe.dart';

/// A page element that builds handles on demand, all on its own context,
/// and follows RM-01 at once like a real component.
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

  /// A MO-12 loop asked to run (LP-02: the test stands for the real wait).
  MotionHandle loop() {
    final MotionHandle h = make(MotionId.mo12, MotionPhase.loop);
    unawaited(h.repeat(reverse: true));
    return h;
  }

  void drop(MotionHandle h) {
    _handles.remove(h);
    h.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = context.motion.reduced;
    for (final MotionHandle h in _handles) {
      h.updateReduced(reduced);
    }
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

/// A Skeleton plate stand-in that reads the shared loop (LP-04).
class _Plate extends StatelessWidget {
  const _Plate();

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: MotionLoopGroup.of(context),
        child: const SizedBox(width: 10, height: 10),
      );
}

const MotionProbe _probe = MotionProbe();

/// A controller is done only after its duration has passed, so tests pump
/// one millisecond more.
const Duration _ms = Duration(milliseconds: 1);
const Duration _step = Duration(milliseconds: 100);

Finder get _page => find.byType(Directionality);

Widget _app({
  required Key hostKey,
  bool scope = true,
  bool group = false,
  ReducedMotionSetting setting = ReducedMotionSetting.off,
}) {
  final Widget content = Column(
    children: <Widget>[
      if (group)
        const MotionLoopGroup(
          id: MotionId.mo12,
          running: true,
          reverse: true,
          child: Column(
            children: <Widget>[_Plate(), _Plate(), _Plate()],
          ),
        ),
      _Host(key: hostKey),
    ],
  );
  return Directionality(
    textDirection: TextDirection.rtl,
    child: AppMotionScope(
      setting: setting,
      child: scope ? MotionBudgetScope(child: content) : content,
    ),
  );
}

Future<_HostState> _pump(
  WidgetTester tester, {
  bool scope = true,
  bool group = false,
  ReducedMotionSetting setting = ReducedMotionSetting.off,
}) async {
  final GlobalKey<_HostState> key = GlobalKey<_HostState>();
  await tester.pumpWidget(
      _app(hostKey: key, scope: scope, group: group, setting: setting));
  return key.currentState!;
}

void _expectWaiting(MotionHandle h) {
  expect(h.controller.isAnimating, isFalse, reason: 'LP-04: waits');
  expect(h.controller.value, h.controller.lowerBound,
      reason: 'LP-04: still at its start (RM-02 «ایستا» look)');
}

void main() {
  tearDown(() => expect(MotionRegistry.entries, isEmpty));

  testWidgets('LP-04: a third MO-12 loop waits still at its start',
      (WidgetTester tester) async {
    final _HostState s = await _pump(tester);
    final MotionHandle a = s.loop();
    final MotionHandle b = s.loop();
    final MotionHandle c = s.loop();
    await tester.pump(_step);

    expect(_probe.activeLoopCount(_page), motionLoopCap);
    final MotionBudget budget = MotionBudgetScope.maybeOf(s.context)!;
    expect(budget.runningLoops, 2);
    expect(budget.waitingLoops, 1);
    expect(a.controller.isAnimating, isTrue);
    expect(b.controller.isAnimating, isTrue);
    _expectWaiting(c);
    await tester.pump(_step);
    _expectWaiting(c);
  });

  testWidgets('LP-04, MR-03: a waiting loop starts when one is cut or goes; '
      'oldest first; a cut loop does not restart', (WidgetTester tester) async {
    final _HostState s = await _pump(tester);
    final MotionHandle a = s.loop();
    final MotionHandle b = s.loop();
    final MotionHandle c = s.loop();
    final MotionHandle d = s.loop();
    await tester.pump(_step);
    _expectWaiting(c);
    _expectWaiting(d);

    // Cut (MR-03): its place goes to the oldest waiting loop.
    a.interrupt();
    await tester.pump(_step);
    expect(a.controller.isAnimating, isFalse);
    expect(c.controller.isAnimating, isTrue);
    _expectWaiting(d);
    expect(_probe.activeLoopCount(_page), 2);

    // Disposed: its place goes to the next one.
    s.drop(b);
    await tester.pump(_step);
    expect(d.controller.isAnimating, isTrue);
    expect(_probe.activeLoopCount(_page), 2);

    // Nothing waits now; the cut loop stays cut.
    s.drop(c);
    await tester.pump(_step);
    expect(a.controller.isAnimating, isFalse);
    expect(_probe.activeLoopCount(_page), 1);
    expect(MotionBudgetScope.maybeOf(s.context)!.waitingLoops, 0);
  });

  testWidgets('LP-04: a MotionLoopGroup of three plates is one loop',
      (WidgetTester tester) async {
    final _HostState s = await _pump(tester, group: true);
    await tester.pump(_step);
    expect(_probe.activeLoopCount(_page), 1);

    final MotionHandle second = s.loop();
    final MotionHandle third = s.loop();
    await tester.pump(_step);
    expect(second.controller.isAnimating, isTrue);
    _expectWaiting(third);
    expect(_probe.activeLoopCount(_page), 2);
  });

  testWidgets('LP-04 and MT-08 count apart: two loops, three MO-11 rows',
      (WidgetTester tester) async {
    final _HostState s = await _pump(tester);
    s.loop();
    s.loop();
    final List<MotionHandle> rows = <MotionHandle>[
      for (int i = 0; i < 3; i++) s.make(MotionId.mo11, MotionPhase.enter),
    ];
    for (final MotionHandle h in rows) {
      unawaited(h.forward());
    }
    final MotionHandle third = s.loop();
    await tester.pump();

    expect(_probe.activeCount(_page), motionPageCap);
    expect(_probe.activeLoopCount(_page), motionLoopCap);
    for (final MotionHandle h in rows) {
      expect(h.controller.isAnimating, isTrue);
    }
    _expectWaiting(third);

    // The rows end; the loops keep their places and the third still waits.
    await tester.pump(MotionToken.base.duration + _ms);
    expect(_probe.activeCount(_page), 0);
    expect(_probe.activeLoopCount(_page), 2);
    _expectWaiting(third);
  });

  testWidgets('RM-02: reduced «روشن» runs no loop; «خاموش» restarts at most '
      'two, oldest first', (WidgetTester tester) async {
    final GlobalKey<_HostState> key = GlobalKey<_HostState>();
    await tester.pumpWidget(
        _app(hostKey: key, setting: ReducedMotionSetting.on));
    final _HostState s = key.currentState!;
    final MotionHandle a = s.loop();
    final MotionHandle b = s.loop();
    final MotionHandle c = s.loop();
    await tester.pump(_step);
    expect(_probe.activeLoopCount(_page), 0);
    for (final MotionHandle h in <MotionHandle>[a, b, c]) {
      expect(h.controller.value, h.controller.lowerBound);
    }
    expect(MotionBudgetScope.maybeOf(s.context)!.waitingLoops, 0);

    await tester.pumpWidget(_app(hostKey: key));
    await tester.pump(_step);
    expect(a.controller.isAnimating, isTrue);
    expect(b.controller.isAnimating, isTrue);
    _expectWaiting(c);
    expect(_probe.activeLoopCount(_page), 2);

    // Reduced on again: every loop is still and none waits (RM-02).
    await tester.pumpWidget(
        _app(hostKey: key, setting: ReducedMotionSetting.on));
    await tester.pump(_step);
    expect(_probe.activeLoopCount(_page), 0);
    expect(MotionBudgetScope.maybeOf(s.context)!.waitingLoops, 0);
  });

  testWidgets('without a MotionBudgetScope three loops all run',
      (WidgetTester tester) async {
    final _HostState s = await _pump(tester, scope: false);
    expect(MotionBudgetScope.maybeOf(s.context), isNull);
    s.loop();
    s.loop();
    s.loop();
    await tester.pump(_step);
    expect(_probe.activeLoopCount(_page), 3);
  });
}
