// The MVP build manifest and the `--profile` switch (ADR-UI-009 §1).
//
// `design/mvp_manifest.json` lists what exists in the build. With
// `--profile=mvp` every catalogue item that is not in the manifest is
// reported as NOT_IN_BUILD (neither pass nor fail). With `--profile=full`
// any such exemption is a failure (ADR-UI-009 acceptance test 4).
// The token stage itself is never reduced (ADR-UI-009 §2).

import 'dart:convert';

import 'sha256.dart';

/// Repository path of the manifest.
const String manifestPath = 'design/mvp_manifest.json';

/// Components of table 7-0, in table order (`7-00-intro-and-component-table`).
const List<String> componentCatalog = <String>[
  'Button',
  'IconButton',
  'TextField',
  'NumberField',
  'FieldMessage',
  'CurrencyAmount',
  'SummaryCard',
  'ListCard',
  'ListRow',
  'DayRing',
  'PulseDot',
  'Chip',
  'Tabs',
  'BottomSheet',
  'Dialog',
  'Popover',
  'QuickAdd',
  'EmptyState',
  'ErrorState',
  'Skeleton',
  'Toast',
  'OfflineBanner',
  'SyncStatus',
  'PageHeader',
  'ResponsiveList',
  'Checkbox',
  'Switch',
  'SwitchRow',
  'Select',
  'DatePicker',
  'Badge',
  'Divider',
  'Tooltip',
  'NumericCell',
  'BidiText',
  'PercentageChange',
  'NumericColumnMetrics',
  'FilterBar',
  'ChartContainer',
  'ChartDataTable',
  'AIActionCard',
];

/// Destinations of table 5-1 in table order.
const List<String> destinationCatalog = <String>[
  'home',
  'accounting',
  'budget',
  'tasks',
  'health',
  'car',
  'markets',
  'assistant',
  'reports',
  'settings',
];

/// Destinations that are always on (ND-02); a manifest without them is
/// invalid at any profile.
const List<String> coreDestinations = <String>[
  'home',
  'accounting',
  'reports',
  'settings',
];

/// QuickAdd types of QT-01.
const List<String> quickAddTypeCatalog = <String>[
  'expense',
  'income',
  'transfer',
  'task',
];

/// The profiles the tool accepts (ADR-UI-009 §1).
enum Profile { mvp, full }

/// Parses `mvp` or `full`; null otherwise.
Profile? parseProfile(String value) {
  for (final Profile p in Profile.values) {
    if (p.name == value) {
      return p;
    }
  }
  return null;
}

/// Result of reading the manifest.
final class ManifestResult {
  ManifestResult({
    required this.hash,
    required this.errors,
    required this.notInBuild,
  });

  /// sha256 of the manifest bytes, for the VR-05 report.
  final String hash;

  /// Problems with the manifest itself, each starting with a rule ID.
  final List<String> errors;

  /// Catalogue items missing from the manifest, by kind
  /// (`components`, `destinations`, `quickAddTypes`).
  final Map<String, List<String>> notInBuild;

  /// Number of exemptions (all NOT_IN_BUILD items).
  int get exemptionCount =>
      notInBuild.values.fold(0, (int sum, List<String> l) => sum + l.length);
}

const String _rule = 'ADR-UI-009';

Object? _decode(List<int> bytes) {
  try {
    return jsonDecode(utf8.decode(bytes));
  } on FormatException {
    return null;
  }
}

/// Reads the manifest [bytes] and compares it with the catalogues.
ManifestResult readManifest(List<int> bytes) {
  final String hash = sha256Hex(bytes);
  final List<String> errors = <String>[];
  final Map<String, List<String>> notInBuild = <String, List<String>>{};

  final Object? decoded = _decode(bytes);
  if (decoded is! Map<String, Object?>) {
    errors.add('$_rule manifest must be a readable JSON object');
    return ManifestResult(hash: hash, errors: errors, notInBuild: notInBuild);
  }
  final Map<String, Object?> doc = decoded;

  const List<String> keys = <String>[
    'profile',
    'components',
    'destinations',
    'pages',
    'quickAddTypes',
  ];
  for (final String k in doc.keys) {
    if (!keys.contains(k)) {
      errors.add('$_rule unknown manifest key "$k" (exemptions change only '
          'through the ADR, VR-03)');
    }
  }
  if (doc['profile'] != 'mvp') {
    errors.add('$_rule manifest "profile" must be "mvp"');
  }

  List<String> list(String key) {
    final Object? v = doc[key];
    if (v is! List<Object?> || v.any((Object? e) => e is! String)) {
      errors.add('$_rule manifest "$key" must be a list of strings');
      return <String>[];
    }
    final List<String> items = v.cast<String>();
    if (items.toSet().length != items.length) {
      errors.add('$_rule manifest "$key" has duplicates');
    }
    return items;
  }

  void compare(String key, List<String> catalog) {
    final List<String> items = list(key);
    for (final String i in items) {
      if (!catalog.contains(i)) {
        errors.add('$_rule manifest "$key" names "$i", which is not in the '
            'catalogue');
      }
    }
    notInBuild[key] =
        catalog.where((String c) => !items.contains(c)).toList();
  }

  compare('components', componentCatalog);
  compare('destinations', destinationCatalog);
  compare('quickAddTypes', quickAddTypeCatalog);
  list('pages');

  final List<String> destinations = notInBuild['destinations'] ?? <String>[];
  for (final String core in coreDestinations) {
    if (destinations.contains(core)) {
      errors.add('ND-02 core destination "$core" missing from the manifest');
    }
  }
  return ManifestResult(hash: hash, errors: errors, notInBuild: notInBuild);
}
