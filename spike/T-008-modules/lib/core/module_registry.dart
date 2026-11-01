// ModuleRegistry over Riverpod (MDC-A3, MDC-A4, DM-03, DM-04). The core
// never imports modules or the app (MDC-A2): the app hands the module list
// in by overriding [moduleListProvider].

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'module_descriptor.dart';

/// Every module compiled into the build. The app overrides this with the
/// list from `app/module_list.dart`; the core default is "no modules"
/// (MDC-A6: the core works with every optional module off).
final Provider<List<ModuleDescriptor>> moduleListProvider =
    Provider<List<ModuleDescriptor>>((Ref ref) => const <ModuleDescriptor>[]);

/// Ids of the enabled modules (setting `modules.enabled`, not persisted in
/// this spike). Changes take effect without restart (DM-04).
final NotifierProvider<EnabledModules, Set<String>> enabledModulesProvider =
    NotifierProvider<EnabledModules, Set<String>>(EnabledModules.new);

/// Holds the enabled ids; first value from `defaultEnabled`.
class EnabledModules extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{
        for (final ModuleDescriptor m in ref.watch(moduleListProvider))
          if (m.defaultEnabled) m.id,
      };

  /// DM-03: no data is touched; only the id leaves the set.
  void disable(String id) {
    if (state.contains(id)) {
      state = <String>{...state}..remove(id);
    }
  }

  /// DM-04. An id that is not registered is ignored (DM-01: an absent
  /// module never appears).
  void enable(String id) {
    final bool registered =
        ref.read(moduleListProvider).any((ModuleDescriptor m) => m.id == id);
    if (registered && !state.contains(id)) {
      state = <String>{...state, id};
    }
  }
}

/// Registered modules filtered by enabled state, in list order (MDC-A4).
final Provider<List<ModuleDescriptor>> activeModulesProvider =
    Provider<List<ModuleDescriptor>>((Ref ref) {
  final Set<String> enabled = ref.watch(enabledModulesProvider);
  return <ModuleDescriptor>[
    for (final ModuleDescriptor m in ref.watch(moduleListProvider))
      if (enabled.contains(m.id)) m,
  ];
});
