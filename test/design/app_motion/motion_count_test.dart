// Tests of `app_motion` slice 8 (T-046): the MO-14 count value of
// SummaryCard in `BigInt` (SC-08), inside the range (MR-02), ending exactly
// on the real value with the Semantics source fixed on it (MX-05).
// Amounts are synthetic minor units (rial).

import 'package:bluehesab_mini/design/app_motion/app_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final BigInt _ten = BigInt.from(10);

/// Every progress step k / 1000 (SC-08 resolution).
Iterable<double> get _progresses sync* {
  for (int k = 0; k <= motionCountSteps; k++) {
    yield k / motionCountSteps;
  }
}

/// MR-02: [v] is inside the closed range between [a] and [b].
bool _inRange(BigInt v, BigInt a, BigInt b) =>
    v >= (a <= b ? a : b) && v <= (a <= b ? b : a);

/// Samples [motionCountValue] over every step and checks range and order.
List<BigInt> _sweep(BigInt from, BigInt to, {BigInt? unit}) {
  final List<BigInt> values = <BigInt>[
    for (final double p in _progresses)
      motionCountValue(from: from, to: to, progress: p, unit: unit),
  ];
  for (int i = 0; i < values.length; i++) {
    expect(_inRange(values[i], from, to), isTrue,
        reason: 'MR-02: step $i value ${values[i]} outside $from…$to');
    if (i > 0) {
      final bool ordered = to >= from
          ? values[i] >= values[i - 1]
          : values[i] <= values[i - 1];
      expect(ordered, isTrue, reason: 'step $i goes back');
    }
  }
  expect(values.first, from);
  expect(values.last, to);
  return values;
}

/// A SummaryCard stand-in: one MO-14 run handle and its count (SC-08).
class _Hero extends StatefulWidget {
  const _Hero({super.key, required this.from, required this.to});

  final BigInt from;
  final BigInt to;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  MotionHandle? _handle;
  late MotionCount count;

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
      id: MotionId.mo14,
      phase: MotionPhase.run,
      reduced: context.motion.reduced,
    );
    _handle = h;
    count = MotionCount(
      parent: h.animation,
      from: widget.from,
      to: widget.to,
      unit: _ten,
    );
    h.forward();
  }

  @override
  void dispose() {
    _handle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 10, height: 10);
}

Widget _host(
  Widget child, {
  ReducedMotionSetting setting = ReducedMotionSetting.off,
}) =>
    MediaQuery(
      data: const MediaQueryData(),
      child: AppMotionScope(
        setting: setting,
        child: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );

const Duration _frame = Duration(milliseconds: 16);
const Duration _ms = Duration(milliseconds: 1);

void main() {
  tearDown(() => expect(MotionRegistry.entries, isEmpty));

  group('motionCountValue (SC-08, MR-02)', () {
    test('unit 1 follows from + (delta × k) ~/ 1000 at every step', () {
      final BigInt from = BigInt.from(-123457);
      final BigInt to = BigInt.parse('98765432109');
      final BigInt delta = to - from;
      for (final double p in _progresses) {
        final int k = (p * 1000).round();
        final BigInt expected =
            from + (delta * BigInt.from(k)) ~/ BigInt.from(1000);
        expect(motionCountValue(from: from, to: to, progress: p), expected,
            reason: 'k = $k');
      }
    });

    test('18-digit amounts do not overflow, both ways', () {
      final BigInt big = BigInt.parse('999999999999999999');
      final List<BigInt> up = _sweep(BigInt.zero, big);
      // Halfway is exactly half: proves the BigInt product, not an int one.
      expect(up[500], BigInt.parse('499999999999999999'));
      _sweep(big, BigInt.zero);
      _sweep(-big, big, unit: _ten);
    });

    test('unit 10: intermediate values are multiples of 10 toward origin', () {
      final BigInt from = BigInt.from(1000);
      final BigInt to = BigInt.from(2347);
      final List<BigInt> up = _sweep(from, to, unit: _ten);
      for (int i = 1; i < up.length - 1; i++) {
        expect(up[i].remainder(_ten), BigInt.zero, reason: 'step $i');
        final BigInt raw = motionCountValue(
            from: from, to: to, progress: i / motionCountSteps);
        expect(up[i] <= raw, isTrue, reason: 'up: toward origin, step $i');
      }
      final List<BigInt> down = _sweep(to, from, unit: _ten);
      for (int i = 1; i < down.length - 1; i++) {
        final BigInt raw = motionCountValue(
            from: to, to: from, progress: i / motionCountSteps);
        expect(down[i] >= raw, isTrue, reason: 'down: toward origin, step $i');
        final bool clamped = down[i] == to;
        expect(clamped || down[i].remainder(_ten) == BigInt.zero, isTrue,
            reason: 'step $i');
      }
    });

    test('negative to positive and back stay in range (unit 10)', () {
      _sweep(BigInt.from(-50005), BigInt.from(1237), unit: _ten);
      _sweep(BigInt.from(1237), BigInt.from(-50005), unit: _ten);
      _sweep(BigInt.from(-7), BigInt.from(-3), unit: _ten);
    });

    test('origin not a multiple of the unit: the clamp wins (D0)', () {
      final BigInt from = BigInt.from(15);
      final BigInt to = BigInt.from(100);
      final BigInt early = motionCountValue(
          from: from, to: to, progress: 0.01, unit: _ten);
      expect(early, from);
      _sweep(from, to, unit: _ten);
    });

    test('ends are exact; progress outside 0…1 is clamped', () {
      final BigInt from = BigInt.from(40);
      final BigInt to = BigInt.from(1235);
      expect(motionCountValue(from: from, to: to, progress: 0, unit: _ten),
          from);
      expect(motionCountValue(from: from, to: to, progress: 1, unit: _ten),
          to);
      expect(motionCountValue(from: from, to: to, progress: -0.5), from);
      expect(motionCountValue(from: from, to: to, progress: 1.5), to);
      expect(motionCountValue(from: from, to: to, progress: double.nan),
          from);
      expect(motionCountValue(from: to, to: to, progress: 0.5), to);
    });

    test('a unit that is not positive is rejected', () {
      expect(
        () => motionCountValue(
            from: BigInt.zero,
            to: BigInt.one,
            progress: 0.5,
            unit: BigInt.zero),
        throwsArgumentError,
      );
    });
  });

  group('MotionCount on a MO-14 handle (MX-05, RM-02)', () {
    testWidgets('every frame in range, last frame exact, target fixed',
        (WidgetTester tester) async {
      final BigInt from = BigInt.zero;
      final BigInt to = BigInt.parse('125000000000000007');
      final GlobalKey<_HeroState> key = GlobalKey<_HeroState>();
      await tester.pumpWidget(_host(_Hero(key: key, from: from, to: to)));
      final MotionCount count = key.currentState!.count;
      final Duration total = key.currentState!.handle.resolved.duration;
      expect(total, greaterThan(Duration.zero));
      await tester.pump();
      Duration elapsed = Duration.zero;
      int frames = 0;
      while (elapsed <= total) {
        expect(_inRange(count.value, from, to), isTrue,
            reason: 'frame $frames: ${count.value}');
        expect(count.target, to, reason: 'MX-05 Semantics source');
        await tester.pump(_frame);
        elapsed += _frame;
        frames++;
      }
      await tester.pump(_ms);
      expect(frames, greaterThan(2));
      expect(key.currentState!.handle.controller.isAnimating, isFalse);
      expect(count.value, to);
      expect(count.target, to);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reduced motion «آنی»: the first frame is the real value',
        (WidgetTester tester) async {
      final BigInt from = BigInt.from(5000);
      final BigInt to = BigInt.from(2345);
      final GlobalKey<_HeroState> key = GlobalKey<_HeroState>();
      await tester.pumpWidget(_host(
        _Hero(key: key, from: from, to: to),
        setting: ReducedMotionSetting.on,
      ));
      final MotionCount count = key.currentState!.count;
      expect(key.currentState!.handle.controller.isAnimating, isFalse);
      expect(count.value, to);
      await tester.pump();
      expect(count.value, to);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
