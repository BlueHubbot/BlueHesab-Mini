// Placeholder core pages (ND-02 core destinations) and ModuleDisabledPage
// (DM-05). Text is copy-catalog keys (CM-10); no styling (tokens are out of
// scope for this spike).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'module_descriptor.dart';
import 'module_registry.dart';

/// A core destination: always on, no switch (ND-02).
@immutable
class CoreDestination {
  /// Creates a core destination.
  const CoreDestination(this.id, this.path);

  /// Destination id.
  final String id;

  /// Route (ND-04).
  final String path;

  /// Copy-catalog key of the title.
  String get titleKey => 'dest.$id';
}

/// The four core destinations (ND-02), in nav order.
const List<CoreDestination> coreDestinations = <CoreDestination>[
  CoreDestination('home', '/home'),
  CoreDestination('accounting', '/accounting'),
  CoreDestination('reports', '/reports'),
  CoreDestination('settings', '/settings'),
];

/// Home: navigation and cards built from the registry (MDC-A4, DM-01).
class HomePage extends ConsumerWidget {
  /// Creates the page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ModuleDescriptor> active = ref.watch(activeModulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('dest.home')),
      body: ListView(
        children: <Widget>[
          for (final CoreDestination d in coreDestinations.skip(1))
            ListTile(
              key: ValueKey<String>('nav-${d.id}'),
              title: Text(d.titleKey),
              onTap: () => context.go(d.path),
            ),
          for (final ModuleDescriptor m in active)
            ListTile(
              key: ValueKey<String>('nav-${m.id}'),
              title: Text(m.titleKey),
              onTap: () => context.go(m.rootPath),
            ),
          for (final ModuleDescriptor m in active)
            for (final HomeContribution c in m.homeWidgets)
              KeyedSubtree(
                key: ValueKey<String>('home-${c.id}'),
                child: Builder(builder: c.builder),
              ),
        ],
      ),
    );
  }
}

/// A plain core page with a title key.
class CorePage extends StatelessWidget {
  /// Creates the page for [destination].
  const CorePage(this.destination, {super.key});

  /// Which core destination this is.
  final CoreDestination destination;

  @override
  Widget build(BuildContext context) => Scaffold(
        key: ValueKey<String>('page-${destination.id}'),
        appBar: AppBar(title: Text(destination.titleKey)),
      );
}

/// DM-05: shown for any route of a disabled module; never in navigation.
class ModuleDisabledPage extends ConsumerWidget {
  /// Creates the page for module [moduleId].
  const ModuleDisabledPage(this.moduleId, {super.key});

  /// The disabled module, from the redirect query.
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ModuleDescriptor? module = ref
        .watch(moduleListProvider)
        .where((ModuleDescriptor m) => m.id == moduleId)
        .firstOrNull;
    return Scaffold(
      key: const ValueKey<String>('page-module-disabled'),
      appBar: AppBar(title: const Text('dmx10.title')),
      body: Column(
        children: <Widget>[
          Text(moduleId, key: const ValueKey<String>('disabled-id')),
          if (module != null)
            TextButton(
              key: const ValueKey<String>('disabled-enable'),
              onPressed: () {
                ref.read(enabledModulesProvider.notifier).enable(module.id);
                context.go(module.rootPath);
              },
              child: const Text('dmx10.enable'),
            ),
          TextButton(
            key: const ValueKey<String>('disabled-home'),
            onPressed: () => context.go('/home'),
            child: const Text('dmx10.home'),
          ),
        ],
      ),
    );
  }
}
