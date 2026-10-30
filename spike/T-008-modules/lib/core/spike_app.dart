// The app widget. RTL is forced here for the spike (the product sets the
// `fa` locale with flutter_localizations; out of scope for SP-12).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';

/// Root widget; needs a ProviderScope above it.
class SpikeApp extends ConsumerWidget {
  /// Creates the app.
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        routerConfig: ref.watch(routerProvider),
        builder: (BuildContext context, Widget? child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
      );
}
