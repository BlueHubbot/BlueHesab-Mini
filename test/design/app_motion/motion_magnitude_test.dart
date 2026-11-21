// Tests of `app_motion` slice 4 (T-042): MT-05 sizes read back from the
// spec, the MT-06 logical sign, MX-04 (MO-05 direction) and the MX-02
// reduced shape of MO-05 («محو», RM-02, ADVISOR_REPLY-009 A).

import 'dart:io';

import 'package:bluehesab_mini/design/app_motion/app_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/motion_probe.dart';

const String _specPath = 'docs/design/ui-spec/04-motion.md';

/// The spec writes numbers with Persian digits and the Arabic decimal sign.
String _latinDigits(String s) {
  const String persian = '۰۱۲۳۴۵۶۷۸۹';
  final StringBuffer out = StringBuffer();
  for (final int rune in s.runes) {
    final String ch = String.fromCharCode(rune);
    final int i = persian.indexOf(ch);
    out.write(i >= 0 ? '$i' : (ch == '٫' ? '.' : ch));
  }
  return out.toString();
}

List<String> _specLines() => File(_specPath)
    .readAsLinesSync()
    .map(_latinDigits)
    .toList(growable: false);

String _line(List<String> lines, String prefix) => lines.singleWhere(
      (String l) => l.startsWith(prefix),
      orElse: () => throw StateError('no line starts with $prefix'),
    );

List<double> _px(String line) => RegExp(r'(\d+)px')
    .allMatches(line)
    .map((RegExpMatch m) => double.parse(m.group(1)!))
    .toList();

/// An MO-05 enter handle; `dx` comes from MT-06 for this context.
class _PageEnter extends StatefulWidget {
  const _PageEnter();

  @override
  State<_PageEnter> createState() => _PageEnterState();
}

class _PageEnterState extends State<_PageEnter>
    with SingleTickerProviderStateMixin {
  MotionHandle? _handle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handle != null) {
      return;
    }
    final MotionHandle handle = MotionHandle(
      context: context,
      vsync: this,
      id: MotionId.mo05,
      phase: MotionPhase.enter,
      reduced: context.motion.reduced,
    );
    _handle = handle;
    handle.track(MotionProperty.opacity, handle.animation);
    handle.track(
      MotionProperty.dx,
      handle.resolved.movesOrScales
          ? Tween<double>(
              begin: MotionMagnitude.pageDx0(Directionality.of(context)),
              end: 0,
            ).animate(handle.animation)
          : const AlwaysStoppedAnimation<double>(0),
    );
    handle.forward();
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
  TextDirection direction, {
  ReducedMotionSetting setting = ReducedMotionSetting.followSystem,
}) =>
    MediaQuery(
      data: const MediaQueryData(),
      child: AppMotionScope(
        setting: setting,
        child: Directionality(
          textDirection: direction,
          child: const _PageEnter(),
        ),
      ),
    );

const MotionProbe _probe = MotionProbe();
final Finder _all = find.byType(Directionality);
final Finder _leaf = find.byKey(const Key('leaf'));

/// One frame to start the ticker, the whole [d], then 1 ms past the end.
Future<void> _runPast(WidgetTester tester, Duration d) async {
  await tester.pump();
  await tester.pump(d);
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  tearDown(() => expect(MotionRegistry.entries, isEmpty));

  group('MT-05 sizes equal the spec', () {
    final List<String> lines = _specLines();

    test('MT-05 sentence: 24px page, 16px Toast, Dialog from 0.96', () {
      final String mt05 = _line(lines, '- **MT-05');
      expect(_px(mt05), <double>[
        MotionMagnitude.pageShift,
        MotionMagnitude.toastShift,
      ]);
      final List<double> decimals = RegExp(r'\d+\.\d+')
          .allMatches(mt05)
          .map((RegExpMatch m) => double.parse(m.group(0)!))
          .toList();
      expect(decimals, <double>[MotionMagnitude.dialogScaleFrom]);
    });

    test('table 4-3 rows MO-05, MO-06, MO-09, MO-10 use the same sizes', () {
      expect(_px(_line(lines, '| `MO-05`')), <double>[24]);
      expect(_px(_line(lines, '| `MO-06`')), <double>[24]);
      expect(_px(_line(lines, '| `MO-10`')), <double>[16]);
      expect(_line(lines, '| `MO-09`'), contains('0.96'));
      expect(MotionMagnitude.pageShift, 24);
      expect(MotionMagnitude.toastShift, 16);
      expect(MotionMagnitude.dialogScaleFrom, 0.96);
    });
  });

  test('MT-06: dx0 is −24 in RTL and +24 in LTR; Toast dy0 is +16', () {
    expect(MotionMagnitude.endSign(TextDirection.rtl), -1);
    expect(MotionMagnitude.endSign(TextDirection.ltr), 1);
    expect(MotionMagnitude.pageDx0(TextDirection.rtl), -24);
    expect(MotionMagnitude.pageDx0(TextDirection.ltr), 24);
    expect(MotionMagnitude.toastDy0, 16);
  });

  for (final (TextDirection direction, double dx0) in <(TextDirection, double)>[
    (TextDirection.rtl, -24),
    (TextDirection.ltr, 24),
  ]) {
    testWidgets('MX-04: MO-05 enter starts at dx $dx0 under ${direction.name} '
        'and ends at 0 (MT-06, MX-01)', (WidgetTester tester) async {
      await tester.pumpWidget(_host(direction));
      expect(_probe.activeCount(_all), 1);
      expect(_probe.value(_leaf, MotionProperty.dx), dx0);
      expect(_probe.value(_leaf, MotionProperty.opacity), 0);

      await _runPast(tester, MotionToken.enter.duration);
      expect(_probe.activeCount(_all), 0);
      expect(_probe.value(_leaf, MotionProperty.dx), 0);
      expect(_probe.value(_leaf, MotionProperty.opacity), 1);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('MX-02: MO-05 with reduced on has no dx, opacity only, count 0 '
      'after exit (RM-02 «محو», ADVISOR_REPLY-009 A)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        _host(TextDirection.rtl, setting: ReducedMotionSetting.on));
    expect(MotionRegistry.entries.single.controller.duration,
        MotionToken.exit.duration);
    expect(_probe.value(_leaf, MotionProperty.dx), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 0);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_probe.activeCount(_all), 1);
    expect(_probe.value(_leaf, MotionProperty.dx), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), inExclusiveRange(0, 1));

    await tester.pump(MotionToken.exit.duration);
    expect(_probe.activeCount(_all), 0);
    expect(_probe.value(_leaf, MotionProperty.dx), 0);
    expect(_probe.value(_leaf, MotionProperty.opacity), 1);
    await tester.pumpWidget(const SizedBox());
  });
}
