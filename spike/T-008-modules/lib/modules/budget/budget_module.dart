// The budget module descriptor (MODULE_CONTRACT §6, reduced): routes under
// /budget (MDC-A7, ND-04) and one Home card. Imports only core (MDC-A2).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/module_descriptor.dart';

/// Budget descriptor. Default ON in the MVP.
class BudgetModule implements ModuleDescriptor {
  /// Creates the descriptor.
  const BudgetModule();

  @override
  String get id => 'budget';

  @override
  bool get defaultEnabled => true;

  @override
  String get titleKey => 'dest.budget';

  @override
  String get rootPath => '/budget';

  @override
  List<RouteBase> get routes => <RouteBase>[
        GoRoute(
          path: rootPath,
          builder: (BuildContext context, GoRouterState state) => Scaffold(
            key: const ValueKey<String>('page-budget'),
            appBar: AppBar(title: const Text('dest.budget')),
            body: TextButton(
              key: const ValueKey<String>('budget-open-limits'),
              onPressed: () => context.go('$rootPath/limits'),
              child: const Text('budget.limits'),
            ),
          ),
          routes: <RouteBase>[
            GoRoute(
              path: 'limits',
              builder: (BuildContext context, GoRouterState state) =>
                  Scaffold(
                key: const ValueKey<String>('page-budget-limits'),
                appBar: AppBar(title: const Text('budget.limits')),
              ),
            ),
          ],
        ),
      ];

  @override
  List<HomeContribution> get homeWidgets => <HomeContribution>[
        HomeContribution(
          id: 'budget-progress',
          builder: (BuildContext context) => const Card(
            child: ListTile(title: Text('home.budget_progress')),
          ),
        ),
      ];
}
