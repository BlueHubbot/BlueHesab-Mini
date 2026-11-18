// Tests of `app_motion` slice 2 (T-039): MotionHandle, MotionRegistry and
// MotionProbe (MX-08), with normal and reduced motion (MX-01, MX-02, RM-02,
// LP-01). Reduced «محو» rows follow RM-02 until ESC-009 is answered.

import 'package:bluehesab_mini/design/app_motion/app_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/motion_probe.dart';

/// A minimal widget that animates one row phase through a MotionHandle.
class _Probed extends StatefulWidget {
  const _Probed({
    super.key,
    required this.id,
    required this.phase,
    this.loop = false,
    this.trackDx = false,
  });

  final MotionId id;
  final MotionPhase phase;
  final bool loop;
  final bool trackDx;

  @override
  State<_Probed> createState() => _ProbedState();
}

class _ProbedState extends State<_Probed> with SingleTickerProviderStateMixin {
  MotionHandle? _handle;
  late Animation<double> _opacity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handle != null) {
      return;
    }
    final MotionHandle handle = MotionHandle(
      context: context,
      vsync: this,
      id: widget.id,
      phase: widget.phase,
      reduced: context.motion.reduced,
    );
    _handle = handle;
    _opacity = handle.track(MotionProperty.opacity, handle.animation);
    if (widget.trackDx) {
      // Movement only when RM-02 allows it.
      handle.track(
        MotionProperty.dx,
        handle.resolved.movesOrScales
            ? Tween<double>(begin: -24, end: 0).animate(handle.animation)
            : const AlwaysStoppedAnimation<double>(0),
      );
    }
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
        opacity: _opacity,
        child: const SizedBox(key: Key('leaf'), width: 10, height: 10),
      );
}

Widget _host(Widget child, {bool disableAnimations = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(textDirection: TextDirection.rtl, child: child),
    );

const MotionProbe _probe = MotionProbe();
final Finder _all = find.byType(Directionality);

void main() {
  tearDown(() => expect(MotionRegistry.entries, isEmpty));

  testWidgets('handle duration is the RM-02 duration; hold is rejected',
      (WidgetTester tester) async {
    final Key k = UniqueKey();
    await tester.pumpWidget(
        _host(_Probed(key: k, id: MotionId.mo10, phase: MotionPhase.enter)));
    final MotionRegistration r = MotionRegistry.entries.single;
    expect(r.id, MotionId.mo10);
    expect(r.phase, MotionPhase.enter);
    expect(r.controller.duration, MotionToken.base.duration);
    expect(identical(r.context, tester.element(find.byKey(k))), isTrue);

    await tester.pumpWidget(
        _host(const _Probed(id: MotionId.mo10, phase: MotionPhase.hold)));
    expect(tester.takeException(), isArgumentError);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('normal: MO-10 enter runs from 0 to 1 in base (MX-01)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        _host(const _Probed(id: MotionId.mo10, phase: MotionPhase.enter)));
    expect(_probe.activeCount(_all), 1);
    expect(_probe.activeLoopCount(_all), 0);
    expect(_probe.value(find.byKey(const Key('leaf')), MotionProperty.opacity),
        0);

    // The ticker starts on the next frame (t = 0), then time moves.
    await tester.pump();
    await tester.pump(MotionToken.base.duration);
    expect(_probe.value(find.byKey(const Key('leaf')), MotionProperty.opacity),
        1);
    // At t = duration the end value shows; the controller reports done on
    // the next frame (the simulation ends once t passes the duration).
    await tester.pump(const Duration(milliseconds: 1));
    expect(_probe.activeCount(_all), 0);
    await tester.pumpAndSettle();
    expect(_probe.activeCount(_all), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced «آنی» row (MO-11 enter): no animation, end value '
      'from the first frame (MX-02, MX-08)', (WidgetTester tester) async {
    await tester.pumpWidget(_host(
        const _Probed(id: MotionId.mo11, phase: MotionPhase.enter),
        disableAnimations: true));
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(find.byKey(const Key('leaf')), MotionProperty.opacity),
        1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('loops count apart; reduced «ایستا» stops them (LP-01)',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(const _Probed(
        id: MotionId.mo12, phase: MotionPhase.loop, loop: true)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_probe.activeLoopCount(_all), 1);
    expect(_probe.activeCount(_all), 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_host(
        const _Probed(id: MotionId.mo12, phase: MotionPhase.loop, loop: true),
        disableAnimations: true));
    expect(_probe.activeLoopCount(_all), 0);
    expect(_probe.activeCount(_all), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('subtrees are counted apart; dispose leaves the registry',
      (WidgetTester tester) async {
    const Key a = Key('a');
    const Key b = Key('b');
    await tester.pumpWidget(_host(const Column(children: <Widget>[
      KeyedSubtree(
          key: a, child: _Probed(id: MotionId.mo10, phase: MotionPhase.enter)),
      KeyedSubtree(
          key: b, child: _Probed(id: MotionId.mo10, phase: MotionPhase.exit)),
    ])));
    expect(MotionRegistry.entries, hasLength(2));
    expect(_probe.activeCount(find.byKey(a)), 1);
    expect(_probe.activeCount(find.byKey(b)), 1);
    expect(_probe.activeCount(_all), 2);

    // MO-10 exit (`exit`, 200 ms) ends before enter (`base`, 240 ms).
    // The ticker starts on the next frame (t = 0), then time moves.
    await tester.pump();
    await tester.pump(MotionToken.exit.duration);
    // At t = duration the end value shows; the controller reports done on
    // the next frame (the simulation ends once t passes the duration).
    await tester.pump(const Duration(milliseconds: 1));
    expect(_probe.activeCount(find.byKey(a)), 1);
    expect(_probe.activeCount(find.byKey(b)), 0);

    await tester.pumpWidget(_host(const KeyedSubtree(
        key: a, child: _Probed(id: MotionId.mo10, phase: MotionPhase.enter))));
    expect(MotionRegistry.entries, hasLength(1));
    await tester.pumpWidget(const SizedBox());
    expect(MotionRegistry.entries, isEmpty);
  });

  testWidgets('value: nearest tracked property; untracked throws',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(const _Probed(
        id: MotionId.mo05, phase: MotionPhase.enter, trackDx: true)));
    final Finder leaf = find.byKey(const Key('leaf'));
    expect(_probe.value(leaf, MotionProperty.dx), -24);
    expect(_probe.value(leaf, MotionProperty.opacity), 0);
    expect(() => _probe.value(leaf, MotionProperty.scale), throwsStateError);
    expect(() => _probe.value(find.byType(Directionality),
        MotionProperty.opacity), throwsStateError);
    // The ticker starts on the next frame (t = 0), then time moves.
    await tester.pump();
    await tester.pump(MotionToken.enter.duration);
    expect(_probe.value(leaf, MotionProperty.dx), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced «محو» row (MO-10 enter): crossfade of exit, no '
      'movement (RM-02 default while ESC-009 is open)',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(
        const _Probed(id: MotionId.mo10, phase: MotionPhase.enter, trackDx: true),
        disableAnimations: true));
    final Finder leaf = find.byKey(const Key('leaf'));
    final MotionRegistration r = MotionRegistry.entries.single;
    expect(r.controller.duration, MotionToken.exit.duration);
    expect(_probe.activeCount(_all), 1);
    expect(_probe.value(leaf, MotionProperty.dx), 0);
    // The ticker starts on the next frame (t = 0), then time moves.
    await tester.pump();
    await tester.pump(MotionToken.exit.duration);
    expect(_probe.value(leaf, MotionProperty.opacity), 1);
    // At t = duration the end value shows; the controller reports done on
    // the next frame (the simulation ends once t passes the duration).
    await tester.pump(const Duration(milliseconds: 1));
    expect(_probe.activeCount(_all), 0);
    await tester.pumpWidget(const SizedBox());
  });
}
