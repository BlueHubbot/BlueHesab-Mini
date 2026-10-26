// T-001 smoke test (SP-01): the app starts and the root page is RTL.
import 'package:bluehesab_mini/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts with an empty right-to-left page', (tester) async {
    await tester.pumpWidget(const BlueHesabApp());

    final page = find.byKey(const Key('empty-rtl-page'));
    expect(page, findsOneWidget);
    expect(Directionality.of(tester.element(page)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
