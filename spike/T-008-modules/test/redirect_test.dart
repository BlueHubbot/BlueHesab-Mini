// DM-05 / MDC-T4 decision as a pure function.

import 'package:flutter_test/flutter_test.dart';
import 'package:spike_modules/core/app_router.dart';
import 'package:spike_modules/core/module_descriptor.dart';
import 'package:spike_modules/modules/budget/budget_module.dart';

void main() {
  const List<ModuleDescriptor> modules = <ModuleDescriptor>[BudgetModule()];

  test('enabled module routes pass through', () {
    expect(disabledRedirect(modules, <String>{'budget'}, '/budget'), isNull);
    expect(disabledRedirect(modules, <String>{'budget'}, '/budget/limits'),
        isNull);
  });

  test('disabled module routes go to ModuleDisabledPage with the id', () {
    for (final String path in <String>['/budget', '/budget/limits']) {
      expect(disabledRedirect(modules, <String>{}, path),
          '/module-disabled?id=budget');
    }
  });

  test('core paths and look-alike prefixes are not redirected', () {
    for (final String path in <String>[
      '/home',
      '/accounting',
      '/reports',
      '/settings',
      '/budgetx',
      '/module-disabled',
    ]) {
      expect(disabledRedirect(modules, <String>{}, path), isNull,
          reason: path);
    }
  });

  test('root goes to /home (ND-04)', () {
    expect(disabledRedirect(modules, <String>{}, '/'), '/home');
  });

  test('absent modules are not known to the redirect (DM-01)', () {
    expect(disabledRedirect(const <ModuleDescriptor>[], <String>{}, '/budget'),
        isNull);
    expect(disabledRedirect(modules, <String>{}, '/tasks'), isNull);
  });
}
