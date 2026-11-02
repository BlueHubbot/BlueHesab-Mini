// MODULE_CONTRACT §3, reduced to what SP-12 needs: identity, default state,
// the module's own route subtree (MDC-A7) and its Home contributions
// (MDC-A4). Titles are copy-catalog keys, never display text (CM-10).

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// One card a module adds to Home. Pure description (MODULE_CONTRACT §3).
@immutable
class HomeContribution {
  /// Creates a contribution identified by [id].
  const HomeContribution({required this.id, required this.builder});

  /// Stable id, used as the widget key `home-<id>`.
  final String id;

  /// Builds the card. Must not hold mutable global state.
  final WidgetBuilder builder;
}

/// What a module tells the core about itself (MDC-A3).
abstract interface class ModuleDescriptor {
  /// Destination id (one of the optional destinations, ND-02).
  String get id;

  /// Enabled on first run (MVP: budget = true).
  bool get defaultEnabled;

  /// Copy-catalog key of the destination title (CM-10).
  String get titleKey;

  /// Top-level path the module owns (ND-04), e.g. `/budget`.
  String get rootPath;

  /// The module's route subtree; every path is [rootPath] or below it.
  List<RouteBase> get routes;

  /// Home cards; may be empty.
  List<HomeContribution> get homeWidgets;
}
