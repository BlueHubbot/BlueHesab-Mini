// T-011 golden harness (SP-06). Run with `--update-goldens` only on the CI
// Linux image (GM-01); the compare job runs it without the flag.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_goldens/toy_card.dart';

/// Compact reference view of DS-01 / GM-04, at device pixel ratio 1.0.
const Size compactView = Size(360, 640);

void main() {
  test('GMX-01 matrix has 8 distinct GM-02 names', () {
    final Set<String> names = <String>{
      for (final GoldenCase c in GoldenCase.all) c.fileStem('default'),
    };
    expect(names, hasLength(8));
    expect(GoldenCase.all.first.fileStem('default'),
        'default__light_rtl_s10');
    expect(names, contains('default__dark_ltr_s20'));
  });

  for (final GoldenCase c in GoldenCase.all) {
    final String stem = c.fileStem('default');
    testWidgets('ToyCard $stem', (WidgetTester tester) async {
      tester.view.physicalSize = compactView;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const Key boundary = ValueKey<String>('golden-boundary');
      await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: ToyHarness(goldenCase: c)),
      );
      // GM-07: the spinner never settles, so one frame at time zero only;
      // pumpAndSettle is never called here.
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundary),
        matchesGoldenFile('goldens/ToyCard/$stem.png'),
      );
    });
  }
}
