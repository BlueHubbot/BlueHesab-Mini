// MDC-A4, DM-01, DM-03…DM-05, MDC-T4, ND-04 and RTL back navigation with
// the budget module registered (and, for DM-01, with no module at all).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spike_modules/core/app_router.dart';
import 'package:spike_modules/core/module_descriptor.dart';
import 'package:spike_modules/core/module_registry.dart';
import 'package:spike_modules/modules/budget/budget_module.dart';

import 'support.dart';

const List<ModuleDescriptor> _withBudget = <ModuleDescriptor>[BudgetModule()];

void main() {
  testWidgets('Home nav and cards come from enabled modules (MDC-A4)',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(tester, _withBudget);
    expect(location(c), '/home');
    expect(byId('nav-budget'), findsOneWidget);
    expect(byId('home-budget-progress'), findsOneWidget);
    await tester.tap(byId('nav-budget'));
    await tester.pumpAndSettle();
    expect(location(c), '/budget');
    expect(byId('page-budget'), findsOneWidget);
    await finish(tester, c);
  });

  testWidgets('disable and enable without restart (DM-03, DM-04)',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(tester, _withBudget);
    final GoRouter routerBefore = c.read(routerProvider);
    c.read(enabledModulesProvider.notifier).disable('budget');
    await tester.pumpAndSettle();
    expect(byId('nav-budget'), findsNothing);
    expect(byId('home-budget-progress'), findsNothing);
    c.read(enabledModulesProvider.notifier).enable('budget');
    await tester.pumpAndSettle();
    expect(byId('nav-budget'), findsOneWidget);
    expect(byId('home-budget-progress'), findsOneWidget);
    expect(identical(c.read(routerProvider), routerBefore), isTrue,
        reason: 'the router is not rebuilt on enable/disable');
    await finish(tester, c);
  });

  testWidgets('current page of a module that gets disabled (DM-05)',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(tester, _withBudget);
    await goTo(tester, c, '/budget');
    c.read(enabledModulesProvider.notifier).disable('budget');
    await tester.pumpAndSettle();
    expect(location(c), '/module-disabled?id=budget');
    expect(byId('page-module-disabled'), findsOneWidget);
    expect(find.text('budget'), findsOneWidget);
    await tester.tap(byId('disabled-enable'));
    await tester.pumpAndSettle();
    expect(location(c), '/budget');
    expect(c.read(enabledModulesProvider), <String>{'budget'});
    await finish(tester, c);
  });

  testWidgets('deep link to a disabled module (DM-05)',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(tester, _withBudget);
    c.read(enabledModulesProvider.notifier).disable('budget');
    await tester.pumpAndSettle();
    await goTo(tester, c, '/budget/limits');
    expect(location(c), '/module-disabled?id=budget');
    await tester.tap(byId('disabled-home'));
    await tester.pumpAndSettle();
    expect(location(c), '/home');
    expect(byId('nav-budget'), findsNothing);
    await finish(tester, c);
  });

  testWidgets('unknown path falls back to Home (MDC-T4)',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(tester, _withBudget);
    for (final String path in <String>['/tasks', '/budget/nope', '/']) {
      await goTo(tester, c, '/settings');
      await goTo(tester, c, path);
      expect(location(c), '/home', reason: path);
    }
    expect(tester.takeException(), isNull);
    await finish(tester, c);
  });

  testWidgets('deep link, RTL back button and system back (ND-04)',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(tester, _withBudget);
    await goTo(tester, c, '/budget/limits');
    expect(byId('page-budget-limits'), findsOneWidget);
    final BuildContext pageContext = tester.element(byId('page-budget-limits'));
    expect(Directionality.of(pageContext), TextDirection.rtl);
    final Finder back = find.byType(BackButton);
    expect(back, findsOneWidget);
    // Under RTL the leading back button sits right of the title.
    final Finder title = find.text('budget.limits');
    expect(tester.getCenter(back).dx, greaterThan(tester.getCenter(title).dx));
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(location(c), '/budget');

    await tester.tap(byId('budget-open-limits'));
    await tester.pumpAndSettle();
    expect(location(c), '/budget/limits');
    final bool handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(location(c), '/budget');
    await finish(tester, c);
  });

  testWidgets('no module registered: no budget trace (DM-01, MDC-T2)',
      (WidgetTester tester) async {
    final ProviderContainer c =
        await pumpApp(tester, const <ModuleDescriptor>[]);
    expect(byId('nav-budget'), findsNothing);
    expect(byId('home-budget-progress'), findsNothing);
    final List<String> paths = <String>[
      for (final RouteBase r in c.read(routerProvider).configuration.routes)
        if (r is GoRoute) r.path,
    ];
    expect(paths.where((String p) => p.startsWith('/budget')), isEmpty);
    c.read(enabledModulesProvider.notifier).enable('budget');
    await tester.pumpAndSettle();
    expect(c.read(enabledModulesProvider), isEmpty);
    await goTo(tester, c, '/budget');
    expect(location(c), '/home');
    await finish(tester, c);
  });
}
