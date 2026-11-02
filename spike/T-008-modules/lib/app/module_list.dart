// MDC-A3: the one place that lists the modules of this build. Adding a
// module = one import + one line; removing `budget` = deleting the two
// lines marked `module:budget` (CI does that for MDC-T7).

import '../core/module_descriptor.dart';
import '../modules/budget/budget_module.dart'; // module:budget

/// Modules compiled into this build.
const List<ModuleDescriptor> moduleList = <ModuleDescriptor>[
  BudgetModule(), // module:budget
];
