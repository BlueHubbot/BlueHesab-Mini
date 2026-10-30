// Shared helpers for the widget tests (not a test file itself).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spike_modules/core/app_router.dart';
import 'package:spike_modules/core/module_descriptor.dart';
import 'package:spike_modules/core/module_registry.dart';
import 'package:spike_modules/core/spike_app.dart';

/// Pumps the app with [modules] and returns its container.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  List<ModuleDescriptor> modules,
) async {
  final ProviderContainer c = ProviderContainer(
    overrides: [moduleListProvider.overrideWithValue(modules)],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SpikeApp()),
  );
  await tester.pumpAndSettle();
  return c;
}

/// Navigates with `go` and settles.
Future<void> goTo(
  WidgetTester tester,
  ProviderContainer c,
  String location,
) async {
  c.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

/// Current location of the router.
String location(ProviderContainer c) {
  final GoRouter router = c.read(routerProvider);
  return router.routerDelegate.currentConfiguration.uri.toString();
}

/// Unmounts the app, then disposes the container.
Future<void> finish(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox.shrink());
  c.dispose();
}

/// Finder for a widget with a `ValueKey<String>`.
Finder byId(String id) => find.byKey(ValueKey<String>(id));
