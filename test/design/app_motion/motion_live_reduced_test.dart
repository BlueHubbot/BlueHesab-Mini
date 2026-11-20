// Tests of `app_motion` slice 3 (T-040): a live MotionHandle follows a
// change of the RM-01 setting at once, with no restart (RM-01, RM-02,
// MX-08, LP-01). Reduced «محو» rows keep the RM-02 crossfade
// (ADVISOR_REPLY-009 Decision A).

import 'package:bluehesab_mini/design/app_motion/app_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/motion_probe.dart';

/// A widget that animates one row phase and follows `context.motion`.
class _Live extends StatefulWidget {
  const _Live({required this.id, required this.phase, this.loop = false});

  final MotionId id;
  final MotionPhase phase;
  final bool loop;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> with SingleTickerProviderStateMixin {
  MotionHandle? _handle;

  void _trackDx(MotionHandle handle) => handle.track(
        MotionProperty.dx,
        handle.resolved.movesOrScales
            ? Tween<double>(begin: -24, end: 0).animate(handle.animation)
            : const AlwaysStoppedAnimation<double>(0),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = context.motion.reduced;
    final MotionHandle? existing = _handle;
    if (existing != null) {
      existing.updateReduced(reduced);
      _trackDx(existing);
      return;
    }
    final MotionHandle handle = MotionHandle(
      context: context,
      vsync: this,
      id: widget.id,
      phase: widget.phase,
      reduced: reduced,
    );
    _handle = handle;
    handle.track(MotionProperty.opacity, handle.animation);
    _trackDx(handle);
    if (widget.loop) {
      handle.repeat(reverse: true);
    } else {
      handle.forward();
    }
  }

  @override
  void dispose() {
    _handle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _handle!.animation,
        child: const SizedBox(key: Key('leaf'), width: 10, height: 10),
      );
}

Widget _host(
  Widget child, {
  ReducedMotionSetting setting = ReducedMotionSetting.followSystem,
  bool disableAnimations = false,
}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: AppMotionScope(
        setting: setting,
        child: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );

const MotionProbe _probe = MotionProbe();
final Finder _all = find.byType(Directionality);
final Finder _leaf = find.byKey(const Key('leaf'));
const Duration _halfBase = Duration(milliseconds: 120);

void main() {
  tearDown(() => expect(MotionRegistry.entries, isEmpty));

  testWidgets('setting on mid-run («محو», MO-10 enter): no movement at '
      'once, opacity goes on to the end with exit, count 0 after the change '
      '(RM-01, RM-02, MX-08 per ADVISOR_REPLY-009 A)',
      (WidgetTester tester) async {
    const Widget w = _Live(id: MotionId.mo10, phase: MotionPhase.enter);
    await tester.pumpWidget(_host(w));
    // The ticker starts on the next frame (t = 0), then time moves.
    await tester.pump();
    await tester.pump(_halfBase);
    expect(_probe.activeCount(_all), 1);
    final double before = _probe.value(_leaf, MotionProperty.opacity);
    expect(before, inExclusiveRange(0, 1));
    expect(_probe.value(_leaf, MotionProperty.dx), lessThan(0));

    await tester.pumpWidget(_host(w, setting: ReducedMotionSetting.on));
    // «محو»: dx is at its end value at once; only opacity still changes.
    expect(_probe.value(_leaf, MotionProperty.dx), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), before);
    expect(_probe.activeCount(_all), 1);
    expect(MotionRegistry.entries.single.controller.duration,
        MotionToken.exit.duration);

    // The rest of the crossfade takes at most exit (one frame to start the
    // ticker, then exit, then 1 ms past the end).
    await tester.pump();
    await tester.pump(MotionToken.exit.duration);
    await tester.pump(const Duration(milliseconds: 1));
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 1);
    expect(_probe.value(_leaf, MotionProperty.dx), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('system asks mid-run («آنی», MO-11 enter): end value at once '
      '(RM-01 follow system, MX-02)', (WidgetTester tester) async {
    const Widget w = _Live(id: MotionId.mo11, phase: MotionPhase.enter);
    await tester.pumpWidget(_host(w));
    await tester.pump();
    await tester.pump(_halfBase);
    expect(_probe.activeCount(_all), 1);

    await tester.pumpWidget(_host(w, disableAnimations: true));
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 1);
    expect(MotionRegistry.entries.single.controller.duration,
        MotionToken.instant.duration);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('loop (MO-12): setting on stops it («ایستا»), off starts it '
      'again (LP-01, RM-01)', (WidgetTester tester) async {
    const Widget w =
        _Live(id: MotionId.mo12, phase: MotionPhase.loop, loop: true);
    await tester.pumpWidget(_host(w));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_probe.activeLoopCount(_all), 1);

    await tester.pumpWidget(_host(w, setting: ReducedMotionSetting.on));
    expect(_probe.activeLoopCount(_all), 0);
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 0);

    await tester.pumpWidget(_host(w, setting: ReducedMotionSetting.off));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_probe.activeLoopCount(_all), 1);
    expect(_probe.activeCount(_all), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('setting off over a reduced system: next play has base and '
      'movement (RM-01 «خاموش»)', (WidgetTester tester) async {
    const Widget w = _Live(id: MotionId.mo10, phase: MotionPhase.enter);
    await tester.pumpWidget(_host(w, disableAnimations: true));
    expect(MotionRegistry.entries.single.controller.duration,
        MotionToken.exit.duration);
    expect(_probe.value(_leaf, MotionProperty.dx), 0);

    await tester.pumpWidget(_host(w,
        setting: ReducedMotionSetting.off, disableAnimations: true));
    expect(MotionRegistry.entries.single.controller.duration,
        MotionToken.base.duration);
    // The running crossfade ends as it started; dx now follows the tween.
    expect(_probe.activeCount(_all), 1);
    await tester.pumpAndSettle();
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 1);
    expect(_probe.value(_leaf, MotionProperty.dx), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('same flag again changes nothing: the run goes on',
      (WidgetTester tester) async {
    const Widget w = _Live(id: MotionId.mo10, phase: MotionPhase.enter);
    await tester.pumpWidget(_host(w));
    await tester.pump();
    await tester.pump(_halfBase);
    final double before = _probe.value(_leaf, MotionProperty.opacity);

    // followSystem with no system request and «خاموش» both resolve to false.
    await tester.pumpWidget(_host(w, setting: ReducedMotionSetting.off));
    expect(_probe.activeCount(_all), 1);
    expect(_probe.value(_leaf, MotionProperty.opacity), before);
    expect(MotionRegistry.entries.single.controller.duration,
        MotionToken.base.duration);
    await tester.pumpAndSettle();
    expect(_probe.value(_leaf, MotionProperty.opacity), 1);
    await tester.pumpWidget(const SizedBox());
  });
}
