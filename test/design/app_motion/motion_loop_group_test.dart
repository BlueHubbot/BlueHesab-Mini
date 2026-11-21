// Tests of `app_motion` slice 6 (T-044): MotionLoopGroup shares one loop
// controller with many descendants (LP-04), runs only while its real state
// is on (LP-02), stops ticking under TickerMode (LP-03) and follows RM-01
// at once (RM-02 «ایستا» for the MO-12 loop).

import 'package:bluehesab_mini/design/app_motion/app_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/motion_probe.dart';

/// A plate that fades with the shared loop (the Skeleton maps the range).
class _Plate extends StatelessWidget {
  const _Plate(this.index);

  final int index;

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: MotionLoopGroup.of(context),
        child: SizedBox(key: Key('plate$index'), width: 10, height: 10),
      );
}

Widget _host({
  required bool running,
  MotionId id = MotionId.mo12,
  bool tickers = true,
  ReducedMotionSetting setting = ReducedMotionSetting.followSystem,
}) =>
    MediaQuery(
      data: const MediaQueryData(),
      child: AppMotionScope(
        setting: setting,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: TickerMode(
            enabled: tickers,
            child: MotionLoopGroup(
              id: id,
              running: running,
              reverse: true,
              child: const Column(
                children: <Widget>[
                  _Plate(0),
                  _Plate(1),
                  _Plate(2),
                  _Plate(3),
                  _Plate(4),
                ],
              ),
            ),
          ),
        ),
      ),
    );

const MotionProbe _probe = MotionProbe();
final Finder _all = find.byType(Directionality);
const Duration _step = Duration(milliseconds: 100);

List<Animation<double>> _plateAnimations(WidgetTester tester) => tester
    .widgetList<FadeTransition>(find.byType(FadeTransition))
    .map((FadeTransition f) => f.opacity)
    .toList();

double _value(WidgetTester tester) => _plateAnimations(tester).first.value;

void main() {
  tearDown(() => expect(MotionRegistry.entries, isEmpty));

  testWidgets('five plates share one controller: one running loop and no '
      'other controller (LP-04, MX-08)', (WidgetTester tester) async {
    await tester.pumpWidget(_host(running: true));
    await tester.pump(_step);
    final List<Animation<double>> animations = _plateAnimations(tester);
    expect(animations, hasLength(5));
    for (final Animation<double> a in animations) {
      expect(identical(a, animations.first), isTrue);
    }
    expect(MotionRegistry.entries, hasLength(1));
    expect(MotionRegistry.entries.single.id, MotionId.mo12);
    expect(MotionRegistry.entries.single.phase, MotionPhase.loop);
    expect(_probe.activeLoopCount(_all), 1);
    expect(_probe.activeCount(_all), 0);
    expect(_value(tester), inExclusiveRange(0, 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('running false: no controller, start value; true starts the '
      'loop, false stops it (LP-02)', (WidgetTester tester) async {
    await tester.pumpWidget(_host(running: false));
    await tester.pump(_step);
    expect(MotionRegistry.entries, isEmpty);
    expect(_value(tester), 0);

    await tester.pumpWidget(_host(running: true));
    await tester.pump(_step);
    expect(_probe.activeLoopCount(_all), 1);
    expect(_value(tester), greaterThan(0));

    await tester.pumpWidget(_host(running: false));
    expect(MotionRegistry.entries, isEmpty);
    expect(_value(tester), 0);
    await tester.pump(_step);
    expect(_value(tester), 0);

    // It can start again (a new ticker each time).
    await tester.pumpWidget(_host(running: true));
    await tester.pump(_step);
    expect(_probe.activeLoopCount(_all), 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TickerMode off: the value stops; on again: it moves (LP-03)',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(running: true));
    await tester.pump(_step);
    final double running = _value(tester);
    expect(running, inExclusiveRange(0, 1));

    await tester.pumpWidget(_host(running: true, tickers: false));
    final double muted = _value(tester);
    await tester.pump(_step);
    await tester.pump(_step);
    expect(_value(tester), muted);

    await tester.pumpWidget(_host(running: true));
    await tester.pump(_step);
    final double a = _value(tester);
    await tester.pump(_step);
    expect(_value(tester), isNot(a));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced on while running: still at the start (RM-02 «ایستا»); '
      'off again: the loop runs (RM-01, LP-01)', (WidgetTester tester) async {
    await tester.pumpWidget(_host(running: true));
    await tester.pump(_step);
    expect(_probe.activeLoopCount(_all), 1);

    await tester.pumpWidget(
        _host(running: true, setting: ReducedMotionSetting.on));
    expect(_probe.activeLoopCount(_all), 0);
    expect(_probe.activeCount(_all), 0);
    expect(_value(tester), 0);
    await tester.pump(_step);
    expect(_value(tester), 0);

    await tester.pumpWidget(
        _host(running: true, setting: ReducedMotionSetting.off));
    await tester.pump(_step);
    expect(_probe.activeLoopCount(_all), 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced from the start: the loop never moves (RM-02 «ایستا»)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        _host(running: true, setting: ReducedMotionSetting.on));
    await tester.pump(_step);
    expect(_probe.activeLoopCount(_all), 0);
    expect(_value(tester), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a row with no loop phase is refused (LP-01)',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(running: true, id: MotionId.mo10));
    expect(tester.takeException(), isArgumentError);
    expect(MotionRegistry.entries, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('of without a group throws a StateError; maybeOf is null',
      (WidgetTester tester) async {
    Animation<double>? found;
    await tester.pumpWidget(Builder(builder: (BuildContext context) {
      found = MotionLoopGroup.maybeOf(context);
      return const SizedBox();
    }));
    expect(found, isNull);

    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.rtl,
      child: _Plate(0),
    ));
    expect(tester.takeException(), isStateError);
    await tester.pumpWidget(const SizedBox());
  });
}
