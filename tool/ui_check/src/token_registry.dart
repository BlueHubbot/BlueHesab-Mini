// Registered token names (appendix A, table A-2-a, rows AXT-01…AXT-13) and
// the contrast groups of table 11-3-a (VTG-01…VTG-10).
//
// VT-01 step 1 compares the keys of design_tokens.json with this registry:
// an unregistered name and a registered name that is missing are both
// errors. test/tool/ui_check_spec_sync_test.dart keeps this file equal to
// the appendix table, so the registry cannot drift from the spec (AX-03).

/// One container of the token file and the keys it must hold.
final class RegistryEntry {
  const RegistryEntry(this.axt, this.path, this.keys);

  /// Row of table A-2-a, e.g. `AXT-08` (`AX-02` for the root order).
  final String axt;

  /// Dot path of the JSON object, e.g. `space` or `color.light`.
  final String path;

  /// Exact key set of that object, in file order.
  final List<String> keys;
}

/// The eight fill colours; each has `-hover`, `-pressed` and `-subtle`
/// variants (AXT-03).
const List<String> fillBaseNames = <String>[
  'primary',
  'accent-health',
  'accent-tasks',
  'accent-car',
  'success',
  'warning',
  'danger',
  'info',
];

/// Neutral colours (AXT-02).
const List<String> neutralColorNames = <String>[
  'background',
  'surface',
  'surface-raised',
  'border',
  'border-strong',
  'text-primary',
  'text-secondary',
  'text-disabled',
  'on-fill',
  'ring-track',
  'focus-ring',
  'inverse-surface',
  'inverse-text',
  'scrim',
];

/// All colour names of one theme in file order: neutrals, then each fill
/// with hover and pressed, then the subtle variants (AXT-02, AXT-03).
List<String> colorNames() => <String>[
      ...neutralColorNames,
      for (final String f in fillBaseNames) ...<String>[
        f,
        '$f-hover',
        '$f-pressed',
      ],
      for (final String f in fillBaseNames) '$f-subtle',
    ];

const List<String> _layoutClasses = <String>[
  'compact',
  'medium',
  'expanded',
  'large',
];

const List<String> _layoutKeys = <String>[
  'min-width',
  'max-width',
  'page-padding',
  'card-padding',
  'card-gap',
  'section-gap',
];

/// Top-level sections of the file, in the order of block A-3 (AX-02).
const List<String> rootKeys = <String>[
  'meta',
  'color',
  'alias',
  'scrim-opacity',
  'state-opacity',
  'elevation',
  'typography',
  'space',
  'radius',
  'size',
  'layout',
  'motion',
  'contrast',
];

/// Every object of the file whose keys are checked, with its AXT row.
List<RegistryEntry> registry() => <RegistryEntry>[
      const RegistryEntry('AX-02', '', rootKeys),
      const RegistryEntry('AXT-01', 'meta', <String>[
        'name',
        'tokens-version',
        'format-version',
        'checksum',
      ]),
      const RegistryEntry('AXT-02', 'color', <String>['light', 'dark']),
      RegistryEntry('AXT-03', 'color.light', colorNames()),
      RegistryEntry('AXT-03', 'color.dark', colorNames()),
      const RegistryEntry('AXT-04', 'alias', <String>[
        'accent-finance',
        'accent-finance-hover',
        'accent-finance-pressed',
        'accent-finance-subtle',
      ]),
      const RegistryEntry('AXT-05', 'scrim-opacity', <String>['light', 'dark']),
      const RegistryEntry('AXT-05', 'state-opacity', <String>[
        'hover-layer',
        'pressed-layer',
        'disabled-content',
        'disabled-surface',
      ]),
      const RegistryEntry('AXT-06', 'elevation', <String>[
        'elev-0',
        'elev-1',
        'elev-2',
      ]),
      const RegistryEntry('AXT-07', 'typography', <String>[
        'font-family-fa',
        'font-family-latin',
        'weights',
        'letter-spacing',
        'scale',
      ]),
      const RegistryEntry('AXT-07', 'typography.scale', textRoleNames),
      const RegistryEntry('AXT-08', 'space', <String>[
        'space-1',
        'space-2',
        'space-3',
        'space-4',
        'space-6',
        'space-8',
        'space-12',
      ]),
      const RegistryEntry('AXT-09', 'radius', <String>[
        'radius-sm',
        'radius-md',
        'radius-lg',
        'radius-xl',
        'radius-full',
      ]),
      const RegistryEntry('AXT-10', 'size', sizeNames),
      const RegistryEntry('AXT-11', 'layout', _layoutClasses),
      for (final String c in _layoutClasses)
        RegistryEntry('AXT-11', 'layout.$c', _layoutKeys),
      const RegistryEntry('AXT-12', 'motion', <String>[
        'duration',
        'timing',
        'curve',
      ]),
      const RegistryEntry('AXT-12', 'motion.duration', <String>[
        'instant',
        'micro',
        'exit',
        'base',
        'enter',
        'max',
        'ring-stagger',
        'spinner-loop',
        'skeleton-loop',
        'breathe-loop',
      ]),
      const RegistryEntry('AXT-12', 'motion.timing', <String>[
        'skeleton-delay',
        'toast-visible',
        'toast-undo-visible',
        'tooltip-delay',
      ]),
      const RegistryEntry('AXT-12', 'motion.curve', <String>[
        'standard',
        'decelerate',
        'accelerate',
      ]),
      const RegistryEntry('AXT-13', 'contrast', <String>['surfaces', 'groups']),
    ];

/// Text roles of table 3-1 (AXT-07).
const List<String> textRoleNames = <String>[
  'caption',
  'body-sm',
  'body',
  'label',
  'title-sm',
  'title',
  'heading',
  'display',
];

/// Size tokens (AXT-10).
const List<String> sizeNames = <String>[
  'touch-min',
  'control-sm',
  'control-md',
  'control-lg',
  'icon-sm',
  'icon-md',
  'icon-lg',
  'dot-sm',
  'dot-md',
  'dot-lg',
  'avatar-sm',
  'avatar-md',
  'fab',
  'bottom-nav-height',
  'topbar-height',
  'side-panel-width',
  'reading-max-width',
  'ring-diameter',
  'ring-stroke',
  'ring-gap',
  'state-icon',
  'content-max',
  'sidebar-width-collapsed',
  'sidebar-width-open',
];

/// A contrast group of table 11-3-a with its threshold (VT-02, table 2-8).
final class GroupSpec {
  const GroupSpec(this.id, this.threshold);

  final String id;
  final double threshold;
}

/// The ten groups in order. VTG-01…VTG-09 count toward 210 (VT-03);
/// VTG-10 is reported separately.
const List<GroupSpec> contrastGroups = <GroupSpec>[
  GroupSpec('VTG-01', 4.5),
  GroupSpec('VTG-02', 4.5),
  GroupSpec('VTG-03', 4.5),
  GroupSpec('VTG-04', 4.5),
  GroupSpec('VTG-05', 4.5),
  GroupSpec('VTG-06', 3),
  GroupSpec('VTG-07', 3),
  GroupSpec('VTG-08', 3),
  GroupSpec('VTG-09', 3),
  GroupSpec('VTG-10', 3.3),
];

/// Group reported apart from the 210 count (VT-03).
const String separateGroupId = 'VTG-10';

/// Pairs of VTG-01…VTG-09 over both themes (VT-03, AX-06, table 2-8).
const int expectedPairCount = 210;

/// The only exempt pair (VT-04, DV-04): `border` on the surfaces.
const String exemptPairNote =
    '`border` on background/surface/surface-raised (VT-04, DV-04)';
