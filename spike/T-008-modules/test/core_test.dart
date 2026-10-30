// MDC-T7: core behaviour with whatever app/module_list.dart contains. This
// file never names a module, so CI can delete the budget line and run it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_modules/app/module_list.dart';
import 'package:spike_modules/core/core_pages.dart';

import 'support.dart';

void main() {
  testWidgets('core destinations work with the build module list',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(tester, moduleList);
    expect(location(c), '/home');
    for (final CoreDestination d in coreDestinations.skip(1)) {
      expect(byId('nav-${d.id}'), findsOneWidget, reason: d.id);
      await tester.tap(byId('nav-${d.id}'));
      await tester.pumpAndSettle();
      expect(location(c), d.path);
      expect(byId('page-${d.id}'), findsOneWidget);
      await goTo(tester, c, '/home');
    }
    await goTo(tester, c, '/no-such-destination');
    expect(location(c), '/home');
    await finish(tester, c);
  });

  test('every listed module owns its root path (MDC-A3, MDC-A7)', () {
    final Set<String> ids = <String>{};
    for (final m in moduleList) {
      expect(ids.add(m.id), isTrue, reason: 'duplicate id ${m.id}');
      expect(m.rootPath, '/${m.id}');
      expect(
          coreDestinations.any((CoreDestination d) => d.path == m.rootPath),
          isFalse);
    }
  });
}
