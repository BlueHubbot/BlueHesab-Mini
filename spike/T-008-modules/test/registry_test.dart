// MDC-A3, MDC-A4, DM-03, DM-04: the registry over Riverpod, no widgets.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spike_modules/core/module_descriptor.dart';
import 'package:spike_modules/core/module_registry.dart';
import 'package:spike_modules/modules/budget/budget_module.dart';

class _Fake implements ModuleDescriptor {
  const _Fake(this.id, {required this.defaultEnabled});

  @override
  final String id;

  @override
  final bool defaultEnabled;

  @override
  String get titleKey => 'dest.$id';

  @override
  String get rootPath => '/$id';

  @override
  List<RouteBase> get routes => const <RouteBase>[];

  @override
  List<HomeContribution> get homeWidgets => const <HomeContribution>[];
}

ProviderContainer _container(List<ModuleDescriptor> modules) {
  final ProviderContainer c = ProviderContainer(
    overrides: [moduleListProvider.overrideWithValue(modules)],
  );
  addTearDown(c.dispose);
  return c;
}

List<String> _active(ProviderContainer c) => <String>[
      for (final ModuleDescriptor m in c.read(activeModulesProvider)) m.id,
    ];

void main() {
  test('core default: no modules, nothing enabled (MDC-A6)', () {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(moduleListProvider), isEmpty);
    expect(c.read(enabledModulesProvider), isEmpty);
    expect(c.read(activeModulesProvider), isEmpty);
  });

  test('first value comes from defaultEnabled, list order kept', () {
    final ProviderContainer c = _container(const <ModuleDescriptor>[
      _Fake('alpha', defaultEnabled: false),
      BudgetModule(),
      _Fake('gamma', defaultEnabled: true),
    ]);
    expect(c.read(enabledModulesProvider), <String>{'budget', 'gamma'});
    expect(_active(c), <String>['budget', 'gamma']);
  });

  test('disable and enable take effect at once (DM-03, DM-04)', () {
    final ProviderContainer c =
        _container(const <ModuleDescriptor>[BudgetModule()]);
    final List<List<String>> seen = <List<String>>[];
    c.listen<List<ModuleDescriptor>>(
      activeModulesProvider,
      (List<ModuleDescriptor>? previous, List<ModuleDescriptor> next) =>
          seen.add(<String>[for (final ModuleDescriptor m in next) m.id]),
      fireImmediately: true,
    );
    final EnabledModules notifier = c.read(enabledModulesProvider.notifier);
    // Each read flushes Riverpod's batched rebuild, so every step is seen.
    notifier.disable('budget');
    c.read(activeModulesProvider);
    notifier.disable('budget'); // idempotent: no new value
    c.read(activeModulesProvider);
    notifier.enable('budget');
    c.read(activeModulesProvider);
    expect(seen, <List<String>>[
      <String>['budget'],
      <String>[],
      <String>['budget'],
    ]);
  });

  test('enabling an id that is not registered does nothing (DM-01)', () {
    final ProviderContainer c =
        _container(const <ModuleDescriptor>[BudgetModule()]);
    c.read(enabledModulesProvider.notifier).enable('tasks');
    expect(c.read(enabledModulesProvider), <String>{'budget'});
    expect(_active(c), <String>['budget']);
  });

  test('budget descriptor owns only /budget paths (MDC-A7, ND-04)', () {
    const BudgetModule budget = BudgetModule();
    expect(budget.rootPath, '/budget');
    for (final RouteBase r in budget.routes) {
      expect(r, isA<GoRoute>());
      expect((r as GoRoute).path, budget.rootPath);
    }
    expect(budget.homeWidgets.map((HomeContribution h) => h.id),
        <String>['budget-progress']);
    expect(budget.homeWidgets.first.builder, isA<WidgetBuilder>());
  });
}
