// Tests of `app_motion` slice 5 (T-043): MR-03 / MT-07 — a second row on
// the same element cuts the first and continues from the current value.
// Reduced shapes follow RM-02 (ADVISOR_REPLY-009 A).

import 'dart:async';

import 'package:bluehesab_mini/design/app_motion/app_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/motion_probe.dart';

/// One element (a Toast, a Dialog or a list row) that runs the enter phase
/// of [id] and can be cut by its exit phase (MR-03).
class _Element extends StatefulWidget {
  const _Element({super.key, required this.id});

  final MotionId id;

  @override
  State<_Element> createState() => _ElementState();
}

class _ElementState extends State<_Element> with TickerProviderStateMixin {
  MotionHandle? _enter;
  MotionHandle? _exit;
  late Animation<double> _opacity;
  late Animation<double> _dy;
  late Animation<double> _scale;

  MotionHandle get enter => _enter!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enter != null) {
      return;
    }
    final MotionHandle handle = MotionHandle(
      context: context,
      vsync: this,
      id: widget.id,
      phase: MotionPhase.enter,
      reduced: context.motion.reduced,
    );
    _enter = handle;
    final bool moves = handle.resolved.movesOrScales;
    _opacity = handle.track(MotionProperty.opacity, handle.animation);
    // MO-10 enter: 16px upwards; MO-09 enter: scale 0.96 to 1 (MT-05).
    _dy = handle.track(
      MotionProperty.dy,
      moves && widget.id == MotionId.mo10
          ? Tween<double>(begin: 16, end: 0).animate(handle.animation)
          : const AlwaysStoppedAnimation<double>(0),
    );
    _scale = handle.track(
      MotionProperty.scale,
      moves && widget.id == MotionId.mo09
          ? Tween<double>(begin: 0.96, end: 1).animate(handle.animation)
          : const AlwaysStoppedAnimation<double>(1),
    );
    handle.forward();
  }

  /// MR-03: the exit row cuts enter and continues from the current values.
  /// MO-09/MO-10 exit change only opacity, so dy and scale stay where the
  /// cut left them.
  void cut() {
    final double opacity = _opacity.value;
    final double dy = _dy.value;
    final double scale = _scale.value;
    enter.interrupt();
    final MotionHandle exit = MotionHandle(
      context: context,
      vsync: this,
      id: widget.id,
      phase: MotionPhase.exit,
      reduced: context.motion.reduced,
    );
    _exit = exit;
    _opacity = exit.track(MotionProperty.opacity, exit.from(opacity, 0));
    _dy = exit.track(MotionProperty.dy, AlwaysStoppedAnimation<double>(dy));
    _scale =
        exit.track(MotionProperty.scale, AlwaysStoppedAnimation<double>(scale));
    exit.forward();
    setState(() {});
  }

  @override
  void dispose() {
    _exit?.dispose();
    _enter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: const SizedBox(key: Key('leaf'), width: 10, height: 10),
      );
}

/// A loop (LP-01) on one element, for `interrupt` on a loop.
class _Loop extends StatefulWidget {
  const _Loop({super.key});

  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  MotionHandle? _handle;

  MotionHandle get handle => _handle!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handle != null) {
      return;
    }
    final MotionHandle h = MotionHandle(
      context: context,
      vsync: this,
      id: MotionId.mo12,
      phase: MotionPhase.loop,
      reduced: context.motion.reduced,
    );
    _handle = h;
    h.track(MotionProperty.opacity, h.animation);
    h.repeat(reverse: true);
  }

  @override
  void dispose() {
    _handle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: Key('leaf'), width: 10, height: 10);
}

Widget _host(
  Widget child, {
  ReducedMotionSetting setting = ReducedMotionSetting.followSystem,
}) =>
    MediaQuery(
      data: const MediaQueryData(),
      child: AppMotionScope(
        setting: setting,
        child: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );

const MotionProbe _probe = MotionProbe();
final Finder _all = find.byType(Directionality);
final Finder _leaf = find.byKey(const Key('leaf'));
const Duration _frame = Duration(milliseconds: 16);
const Duration _ms = Duration(milliseconds: 1);

/// Starts the ticker (t = 0), then moves time by [d].
Future<void> _startAndRun(WidgetTester tester, Duration d) async {
  await tester.pump();
  await tester.pump(d);
}

Duration _half(Duration d) => Duration(microseconds: d.inMicroseconds ~/ 2);

void main() {
  tearDown(() => expect(MotionRegistry.entries, isEmpty));

  group('MotionHandle.interrupt (MR-03)', () {
    testWidgets('a running non-loop stops where it is; count drops by one',
        (WidgetTester tester) async {
      final GlobalKey<_ElementState> key = GlobalKey<_ElementState>();
      await tester.pumpWidget(_host(_Element(key: key, id: MotionId.mo10)));
      await _startAndRun(tester, _half(MotionToken.base.duration));
      expect(_probe.activeCount(_all), 1);
      final double at = key.currentState!.enter.controller.value;
      expect(at, inExclusiveRange(0, 1));

      key.currentState!.enter.interrupt();
      await tester.pump(_frame);
      expect(key.currentState!.enter.controller.value, at);
      expect(_probe.activeCount(_all), 0);
      await tester.pump(MotionToken.base.duration);
      expect(key.currentState!.enter.controller.value, at);

      // Idempotent on a stopped handle.
      key.currentState!.enter.interrupt();
      expect(key.currentState!.enter.controller.value, at);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a running loop stops; activeLoopCount 0 (LP-01)',
        (WidgetTester tester) async {
      final GlobalKey<_LoopState> key = GlobalKey<_LoopState>();
      await tester.pumpWidget(_host(_Loop(key: key)));
      await _startAndRun(tester, const Duration(milliseconds: 100));
      expect(_probe.activeLoopCount(_all), 1);
      final double at = key.currentState!.handle.controller.value;

      key.currentState!.handle.interrupt();
      await tester.pump(_frame);
      expect(_probe.activeLoopCount(_all), 0);
      expect(key.currentState!.handle.controller.value, at);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('MotionHandle.from: current at the first frame, end after the '
      "row's duration, the row's curve between (MT-07)",
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(const SizedBox(key: Key('leaf'))));
    final MotionHandle handle = MotionHandle(
      context: tester.element(_leaf),
      vsync: tester,
      id: MotionId.mo10,
      phase: MotionPhase.enter,
      reduced: false,
    );
    final Animation<double> value = handle.from(0.3, 1);
    expect(value.value, closeTo(0.3, 1e-9));

    unawaited(handle.forward());
    final Duration d = handle.resolved.duration;
    await tester.pump();
    await tester.pump(_half(d));
    final Curve curve = handle.resolved.curve!;
    expect(value.value, closeTo(0.3 + 0.7 * curve.transform(0.5), 1e-6));

    await tester.pump(_half(d) + _ms);
    expect(value.value, closeTo(1, 1e-9));
    expect(handle.controller.isAnimating, isFalse);
    handle.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('MO-10 enter cut by exit at half base: no jump, dy stays, one '
      'active animation, opacity 0 after exit (MR-03, MR-05)',
      (WidgetTester tester) async {
    final GlobalKey<_ElementState> key = GlobalKey<_ElementState>();
    await tester.pumpWidget(_host(_Element(key: key, id: MotionId.mo10)));
    await _startAndRun(tester, _half(MotionToken.base.duration));
    final double opacity = _probe.value(_leaf, MotionProperty.opacity);
    final double dy = _probe.value(_leaf, MotionProperty.dy);
    expect(opacity, inExclusiveRange(0, 1));
    expect(dy, inExclusiveRange(0, 16));

    key.currentState!.cut();
    await tester.pump();
    expect(_probe.value(_leaf, MotionProperty.opacity), closeTo(opacity, 1e-9));
    expect(_probe.value(_leaf, MotionProperty.dy), dy);
    expect(_probe.activeCount(_all), 1);
    expect(key.currentState!.enter.controller.isAnimating, isFalse);

    await tester.pump(_half(MotionToken.exit.duration));
    final double mid = _probe.value(_leaf, MotionProperty.opacity);
    expect(mid, inExclusiveRange(0, opacity));
    expect(_probe.value(_leaf, MotionProperty.dy), dy);

    await tester.pump(_half(MotionToken.exit.duration) + _ms);
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 0);
    expect(_probe.value(_leaf, MotionProperty.dy), dy);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('MO-09 enter cut by exit: scale frozen, opacity from its cut '
      'value to 0 (MR-03, MO-09)', (WidgetTester tester) async {
    final GlobalKey<_ElementState> key = GlobalKey<_ElementState>();
    await tester.pumpWidget(_host(_Element(key: key, id: MotionId.mo09)));
    await _startAndRun(tester, _half(MotionToken.base.duration));
    final double opacity = _probe.value(_leaf, MotionProperty.opacity);
    final double scale = _probe.value(_leaf, MotionProperty.scale);
    expect(scale, inExclusiveRange(0.96, 1));

    key.currentState!.cut();
    await tester.pump();
    expect(_probe.value(_leaf, MotionProperty.opacity), closeTo(opacity, 1e-9));
    expect(_probe.value(_leaf, MotionProperty.scale), scale);
    expect(_probe.activeCount(_all), 1);

    await tester.pump(MotionToken.exit.duration + _ms);
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 0);
    expect(_probe.value(_leaf, MotionProperty.scale), scale);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced on, MO-10 («محو»): the exit crossfade goes on from the '
      'current opacity with exit, no movement (RM-02, ADVISOR_REPLY-009 A)',
      (WidgetTester tester) async {
    final GlobalKey<_ElementState> key = GlobalKey<_ElementState>();
    await tester.pumpWidget(_host(_Element(key: key, id: MotionId.mo10),
        setting: ReducedMotionSetting.on));
    await _startAndRun(tester, _half(MotionToken.exit.duration));
    final double opacity = _probe.value(_leaf, MotionProperty.opacity);
    expect(opacity, inExclusiveRange(0, 1));
    expect(_probe.value(_leaf, MotionProperty.dy), 0);

    key.currentState!.cut();
    await tester.pump();
    expect(_probe.value(_leaf, MotionProperty.opacity), closeTo(opacity, 1e-9));
    expect(_probe.activeCount(_all), 1);
    expect(MotionRegistry.entries.last.controller.duration,
        MotionToken.exit.duration);

    await tester.pump(MotionToken.exit.duration + _ms);
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 0);
    expect(_probe.value(_leaf, MotionProperty.dy), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced on, MO-11 («آنی»): exit shows the end value in the '
      'first frame, count 0 (RM-02, MX-02)', (WidgetTester tester) async {
    final GlobalKey<_ElementState> key = GlobalKey<_ElementState>();
    await tester.pumpWidget(_host(_Element(key: key, id: MotionId.mo11),
        setting: ReducedMotionSetting.on));
    // «آنی»: enter is already at its end value.
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 1);

    key.currentState!.cut();
    await tester.pump();
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 0);
    await tester.pumpWidget(const SizedBox());
  });
}
