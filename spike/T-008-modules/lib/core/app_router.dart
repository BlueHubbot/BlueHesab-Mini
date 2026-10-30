// Route table built from the registry (MDC-A4, MDC-A7, ND-04) with the
// DM-05 redirect and the MDC-T4 fallback for unknown paths.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core_pages.dart';
import 'module_descriptor.dart';
import 'module_registry.dart';

/// Path of [ModuleDisabledPage]; not a destination (DM-05).
const String moduleDisabledPath = '/module-disabled';

/// DM-05 decision for [path]: the disabled page for a route owned by a
/// registered but disabled module, otherwise `null` (no redirect). Paths of
/// absent modules have no route at all and fall back to Home (MDC-T4).
String? disabledRedirect(
  List<ModuleDescriptor> modules,
  Set<String> enabled,
  String path,
) {
  if (path == '/') {
    return '/home';
  }
  for (final ModuleDescriptor m in modules) {
    if (path == m.rootPath || path.startsWith('${m.rootPath}/')) {
      return enabled.contains(m.id)
          ? null
          : Uri(path: moduleDisabledPath, queryParameters: <String, String>{
              'id': m.id,
            }).toString();
    }
  }
  return null;
}

class _Refresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// The router. Rebuilt only when the module list changes (never at run
/// time); enable/disable re-runs the redirect through `refreshListenable`.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final List<ModuleDescriptor> modules = ref.watch(moduleListProvider);
  final _Refresh refresh = _Refresh();
  ref.listen<Set<String>>(
    enabledModulesProvider,
    (Set<String>? previous, Set<String> next) => refresh.ping(),
  );
  final GoRouter router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) => disabledRedirect(
      modules,
      ref.read(enabledModulesProvider),
      state.uri.path,
    ),
    onException: (BuildContext context, GoRouterState state, GoRouter r) =>
        r.go('/home'),
    routes: <RouteBase>[
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomePage(),
      ),
      for (final CoreDestination d in coreDestinations.skip(1))
        GoRoute(
          path: d.path,
          builder: (BuildContext context, GoRouterState state) => CorePage(d),
        ),
      GoRoute(
        path: moduleDisabledPath,
        builder: (BuildContext context, GoRouterState state) =>
            ModuleDisabledPage(state.uri.queryParameters['id'] ?? ''),
      ),
      for (final ModuleDescriptor m in modules) ...m.routes,
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
