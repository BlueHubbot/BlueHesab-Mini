// Entry point: the only place the module list meets the core (MDC-A3).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/module_list.dart';
import 'core/module_registry.dart';
import 'core/spike_app.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [moduleListProvider.overrideWithValue(moduleList)],
      child: const SpikeApp(),
    ),
  );
}
