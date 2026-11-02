import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_fonts/amount_card.dart';
import 'package:spike_fonts/digits.dart';

import 'support.dart';

// T-015 (SP-03, UI spec §3-1): Vazirmatn evaluation with the real font
// loaded. Font facts are recorded as evidence (PASS/FAIL per row) rather
// than asserted, because a FAIL is a valid spike finding; behaviour of the
// spike code and of the engine (bidi order, no overflow) is asserted.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<TypeToken> tokens;
  TypeToken token(String name) => tokens.firstWhere((t) => t.name == name);

  setUpAll(() async {
    tokens = loadTypeTokens();
    await loadFont();
    evidence.add('os=${Platform.operatingSystem} '
        '${Platform.operatingSystemVersion.split('\n').first}');
  });
  tearDownAll(writeEvidence);

  test('the evaluated font is really in use (not the test fallback)', () {
    final body = token('body');
    final real = paint(specimen, body.style());
    final fallback = paint(
      specimen,
      body.style().copyWith(fontFamily: 'FlutterTest', fontVariations: []),
    );
    expect(real.width, isNot(closeTo(fallback.width, 0.5)));
    expect(real.height, greaterThan(0));
    real.dispose();
    fallback.dispose();
  });

  test('vertical metrics: ascent + descent fit every token line height', () {
    final rows = <String>[];
    var allFit = true;
    for (final t in tokens) {
      final natural = paint(specimen, t.style(withLine: false));
      final lm = natural.computeLineMetrics().single;
      final need = lm.ascent + lm.descent;
      final withLine = paint(specimen, t.style());
      final fits = need <= t.line + 1e-6;
      allFit &= fits;
      rows.add('${t.name} ${need.toStringAsFixed(2)}/${t.line.toStringAsFixed(0)}'
          ' box=${withLine.height.toStringAsFixed(2)}${fits ? '' : ' OVER'}');
      // The token line height is what the engine uses (TY-04 sanity).
      expect(withLine.height, closeTo(t.line, 0.5), reason: t.name);
      natural.dispose();
      withLine.dispose();
    }
    evidence.add('vertical=${allFit ? 'PASS' : 'FAIL'} ${rows.join('; ')}');
  });

  test('tabular digits: Persian digits render with one width at body', () {
    final body = token('body');
    final digits = [for (var d = 0; d < 10; d++) String.fromCharCode(0x06F0 + d)];
    Set<String> widths(List<FontFeature>? features) => {
          for (final d in digits)
            () {
              final p = paint(d, body.style(features: features));
              final w = p.width.toStringAsFixed(2);
              p.dispose();
              return w;
            }(),
        };
    final plain = widths(null);
    final tnum = widths(const [FontFeature.tabularFigures()]);
    // Unit digits under each other: two amounts of equal digit count.
    final a = paint('۱۱۱٬۱۱۱', body.style());
    final b = paint('۸۸۸٬۸۸۸', body.style());
    final aligned = (a.width - b.width).abs() < 0.01;
    evidence.add('tabular=${plain.length == 1 || tnum.length == 1 ? 'PASS' : 'FAIL'}'
        ' plain=$plain tnum=$tnum column_aligned=$aligned');
    a.dispose();
    b.dispose();
  });

  test('mixed: an LTR number inside RTL text keeps left-to-right order', () {
    const before = 'مانده ';
    for (final number in ['98,765', '۹۸٬۷۶۵']) {
      final text = '$before$number ریال';
      final p = paint(text, token('body').style());
      final lefts = <double>[];
      for (var i = before.length; i < before.length + number.length; i++) {
        final boxes = p.getBoxesForSelection(
          TextSelection(baseOffset: i, extentOffset: i + 1),
        );
        expect(boxes, hasLength(1), reason: 'char $i of $number');
        expect(boxes.single.direction, TextDirection.ltr, reason: number);
        lefts.add(boxes.single.left);
      }
      for (var i = 1; i < lefts.length; i++) {
        expect(lefts[i], greaterThan(lefts[i - 1]), reason: '$number at $i');
      }
      p.dispose();
    }
    evidence.add('mixed_ltr_in_rtl=PASS (ASCII and Persian digits)');
  });

  testWidgets('Persian digits typed in a number field parse to the exact BigInt',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: token('title').style(),
          ),
        ),
      ),
    ));
    final cases = <String, BigInt>{
      '۱۲۳٬۴۵۶': BigInt.from(123456),
      '۹۹۹۹۹۹۹۹۹۹۹۹۹۹۹۹۹۹': BigInt.parse('999999999999999999'),
      '۰': BigInt.zero,
    };
    for (final entry in cases.entries) {
      await tester.enterText(find.byType(TextField), entry.key);
      await tester.pump();
      expect(controller.text, entry.key);
      expect(parseTypedAmount(controller.text), entry.value);
    }
    expect(tester.takeException(), isNull);
    evidence.add('persian_digit_input=PASS (18 digits exact)');
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('TY-05: amount card at text scale $scale has no overflow and '
        'no ellipsis', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 640),
          textScaler: TextScaler.linear(scale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: AmountCard(
                key: const ValueKey<String>('card'),
                label: 'مانده‌ی حساب جاری',
                amount: '۹۹۹٬۹۹۹٬۹۹۹٬۹۹۹٬۹۹۹٬۹۹۹ ریال',
                labelStyle: token('label').style(),
                amountStyle: token('title').style(),
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byKey(const ValueKey<String>('card')));
      expect(size.width, lessThanOrEqualTo(360));
      for (final p in tester.renderObjectList<RenderParagraph>(find.byType(RichText))) {
        expect(p.didExceedMaxLines, isFalse);
        expect(p.overflow, isNot(TextOverflow.ellipsis));
        expect(p.maxLines, isNull);
      }
      evidence.add('scale_$scale=PASS card=${size.width.toStringAsFixed(0)}x'
          '${size.height.toStringAsFixed(0)}');
    });
  }

  testWidgets('specimen PNG for a human look (not a golden)', (tester) async {
    tester.view.physicalSize = const Size(900, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey<String>('specimen');
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.rtl,
      child: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: const Color(0xFFFFFFFF), // spike artifact background only
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final t in tokens)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x33FF0000)),
                  ),
                  child: Text('${t.name} $specimen 98,765',
                      style: t.style().copyWith(color: const Color(0xFF000000))),
                ),
            ],
          ),
        ),
      ),
    ));
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final path = 'build/specimen-${Platform.operatingSystem}.png';
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
      image.dispose();
    });
    expect(File(path).existsSync(), isTrue);
    evidence.add('specimen=$path');
  });
}
