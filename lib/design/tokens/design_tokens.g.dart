// GENERATED FILE: do not edit by hand (TK-01, MC-02).
// Source: design/tokens/design_tokens.json, tokens-version 1.1.
// Regenerate: dart run tool/ui_check/ui_check.dart gen

import 'dart:ui' show Color, FontWeight;

import 'package:flutter/animation.dart' show Cubic;

/// Colours of one theme (appendix A, AXT-02 and AXT-03).
final class TokenColors {
  /// Creates the colours of one theme.
  const TokenColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.onFill,
    required this.ringTrack,
    required this.focusRing,
    required this.inverseSurface,
    required this.inverseText,
    required this.scrim,
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.accentHealth,
    required this.accentHealthHover,
    required this.accentHealthPressed,
    required this.accentTasks,
    required this.accentTasksHover,
    required this.accentTasksPressed,
    required this.accentCar,
    required this.accentCarHover,
    required this.accentCarPressed,
    required this.success,
    required this.successHover,
    required this.successPressed,
    required this.warning,
    required this.warningHover,
    required this.warningPressed,
    required this.danger,
    required this.dangerHover,
    required this.dangerPressed,
    required this.info,
    required this.infoHover,
    required this.infoPressed,
    required this.primarySubtle,
    required this.accentHealthSubtle,
    required this.accentTasksSubtle,
    required this.accentCarSubtle,
    required this.successSubtle,
    required this.warningSubtle,
    required this.dangerSubtle,
    required this.infoSubtle,
  });

  /// Token `background`.
  final Color background;
  /// Token `surface`.
  final Color surface;
  /// Token `surface-raised`.
  final Color surfaceRaised;
  /// Token `border`.
  final Color border;
  /// Token `border-strong`.
  final Color borderStrong;
  /// Token `text-primary`.
  final Color textPrimary;
  /// Token `text-secondary`.
  final Color textSecondary;
  /// Token `text-disabled`.
  final Color textDisabled;
  /// Token `on-fill`.
  final Color onFill;
  /// Token `ring-track`.
  final Color ringTrack;
  /// Token `focus-ring`.
  final Color focusRing;
  /// Token `inverse-surface`.
  final Color inverseSurface;
  /// Token `inverse-text`.
  final Color inverseText;
  /// Token `scrim`.
  final Color scrim;
  /// Token `primary`.
  final Color primary;
  /// Token `primary-hover`.
  final Color primaryHover;
  /// Token `primary-pressed`.
  final Color primaryPressed;
  /// Token `accent-health`.
  final Color accentHealth;
  /// Token `accent-health-hover`.
  final Color accentHealthHover;
  /// Token `accent-health-pressed`.
  final Color accentHealthPressed;
  /// Token `accent-tasks`.
  final Color accentTasks;
  /// Token `accent-tasks-hover`.
  final Color accentTasksHover;
  /// Token `accent-tasks-pressed`.
  final Color accentTasksPressed;
  /// Token `accent-car`.
  final Color accentCar;
  /// Token `accent-car-hover`.
  final Color accentCarHover;
  /// Token `accent-car-pressed`.
  final Color accentCarPressed;
  /// Token `success`.
  final Color success;
  /// Token `success-hover`.
  final Color successHover;
  /// Token `success-pressed`.
  final Color successPressed;
  /// Token `warning`.
  final Color warning;
  /// Token `warning-hover`.
  final Color warningHover;
  /// Token `warning-pressed`.
  final Color warningPressed;
  /// Token `danger`.
  final Color danger;
  /// Token `danger-hover`.
  final Color dangerHover;
  /// Token `danger-pressed`.
  final Color dangerPressed;
  /// Token `info`.
  final Color info;
  /// Token `info-hover`.
  final Color infoHover;
  /// Token `info-pressed`.
  final Color infoPressed;
  /// Token `primary-subtle`.
  final Color primarySubtle;
  /// Token `accent-health-subtle`.
  final Color accentHealthSubtle;
  /// Token `accent-tasks-subtle`.
  final Color accentTasksSubtle;
  /// Token `accent-car-subtle`.
  final Color accentCarSubtle;
  /// Token `success-subtle`.
  final Color successSubtle;
  /// Token `warning-subtle`.
  final Color warningSubtle;
  /// Token `danger-subtle`.
  final Color dangerSubtle;
  /// Token `info-subtle`.
  final Color infoSubtle;

  /// Alias `accent-finance` of `primary` (AXT-04).
  Color get accentFinance => primary;

  /// Alias `accent-finance-hover` of `primary-hover` (AXT-04).
  Color get accentFinanceHover => primaryHover;

  /// Alias `accent-finance-pressed` of `primary-pressed` (AXT-04).
  Color get accentFinancePressed => primaryPressed;

  /// Alias `accent-finance-subtle` of `primary-subtle` (AXT-04).
  Color get accentFinanceSubtle => primarySubtle;
}

/// One shadow of an elevation level (AXT-06).
final class TokenShadow {
  /// Creates a shadow.
  const TokenShadow({
    required this.x,
    required this.y,
    required this.blur,
    required this.color,
    required this.opacity,
  });

  final double x;
  final double y;
  final double blur;
  final Color color;
  final double opacity;
}

/// An elevation level: its light and dark shadow (AXT-06).
final class TokenElevation {
  /// Creates an elevation level.
  const TokenElevation({required this.light, required this.dark});

  final TokenShadow light;
  final TokenShadow dark;
}

/// A text role of table 3-1 (AXT-07).
final class TokenTextRole {
  /// Creates a text role.
  const TokenTextRole({
    required this.size,
    required this.weight,
    required this.line,
  });

  final double size;
  final FontWeight weight;
  final double line;
}

/// A layout class of table 2-5 (AXT-11).
final class TokenLayout {
  /// Creates a layout class.
  const TokenLayout({
    required this.minWidth,
    required this.maxWidth,
    required this.pagePadding,
    required this.cardPadding,
    required this.cardGap,
    required this.sectionGap,
  });

  final double minWidth;
  final double? maxWidth;
  final double pagePadding;
  final double cardPadding;
  final double cardGap;
  final double sectionGap;
}

/// The design tokens (TK-01). Widgets read values only from here.
abstract final class DesignTokens {
  static const String tokensVersion = '1.1';
  static const String checksum = 'e6064535e236c5fcb322e0f454173e30d5c2dcdbac603a0a97d18dfebca33e3e';

  static const TokenColors colorsLight = TokenColors(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFF7C8BA1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textDisabled: Color(0xFF94A3B8),
    onFill: Color(0xFFFFFFFF),
    ringTrack: Color(0xFFE2E8F0),
    focusRing: Color(0xFF2563EB),
    inverseSurface: Color(0xFF0F172A),
    inverseText: Color(0xFFF8FAFC),
    scrim: Color(0xFF0F172A),
    primary: Color(0xFF2563EB),
    primaryHover: Color(0xFF225BD8),
    primaryPressed: Color(0xFF2055CA),
    accentHealth: Color(0xFF007974),
    accentHealthHover: Color(0xFF006F6B),
    accentHealthPressed: Color(0xFF006864),
    accentTasks: Color(0xFF6E53B6),
    accentTasksHover: Color(0xFF654CA7),
    accentTasksPressed: Color(0xFF5F479D),
    accentCar: Color(0xFF9B418B),
    accentCarHover: Color(0xFF8F3C80),
    accentCarPressed: Color(0xFF853878),
    success: Color(0xFF15803D),
    successHover: Color(0xFF137638),
    successPressed: Color(0xFF126E34),
    warning: Color(0xFFB45309),
    warningHover: Color(0xFFA64C08),
    warningPressed: Color(0xFF9B4708),
    danger: Color(0xFFB91C1C),
    dangerHover: Color(0xFFAA1A1A),
    dangerPressed: Color(0xFF9F1818),
    info: Color(0xFF0369A1),
    infoHover: Color(0xFF036194),
    infoPressed: Color(0xFF035A8A),
    primarySubtle: Color(0xFFEEF3FD),
    accentHealthSubtle: Color(0xFFEBF4F4),
    accentTasksSubtle: Color(0xFFF3F1F9),
    accentCarSubtle: Color(0xFFF7F0F6),
    successSubtle: Color(0xFFF1F7F3),
    warningSubtle: Color(0xFFFAF5F0),
    dangerSubtle: Color(0xFFFBF1F1),
    infoSubtle: Color(0xFFF0F6F9),
  );

  static const TokenColors colorsDark = TokenColors(
    background: Color(0xFF0B1220),
    surface: Color(0xFF111A2C),
    surfaceRaised: Color(0xFF17233A),
    border: Color(0xFF26324A),
    borderStrong: Color(0xFF64748B),
    textPrimary: Color(0xFFE8EDF5),
    textSecondary: Color(0xFF9AA8BD),
    textDisabled: Color(0xFF5B6B87),
    onFill: Color(0xFF0B1220),
    ringTrack: Color(0xFF26324A),
    focusRing: Color(0xFF60A5FA),
    inverseSurface: Color(0xFFE8EDF5),
    inverseText: Color(0xFF0B1220),
    scrim: Color(0xFF000000),
    primary: Color(0xFF60A5FA),
    primaryHover: Color(0xFF5898E6),
    primaryPressed: Color(0xFF538ED7),
    accentHealth: Color(0xFF0DCBC3),
    accentHealthHover: Color(0xFF0CBBB3),
    accentHealthPressed: Color(0xFF0BAFA8),
    accentTasks: Color(0xFFB4A1FC),
    accentTasksHover: Color(0xFFA694E8),
    accentTasksPressed: Color(0xFF9B8AD9),
    accentCar: Color(0xFFE490D2),
    accentCarHover: Color(0xFFD284C1),
    accentCarPressed: Color(0xFFC47CB5),
    success: Color(0xFF4ADE80),
    successHover: Color(0xFF44CC76),
    successPressed: Color(0xFF40BF6E),
    warning: Color(0xFFFBBF24),
    warningHover: Color(0xFFE7B021),
    warningPressed: Color(0xFFD8A41F),
    danger: Color(0xFFF87171),
    dangerHover: Color(0xFFE46868),
    dangerPressed: Color(0xFFD56161),
    info: Color(0xFF38BDF8),
    infoHover: Color(0xFF34AEE4),
    infoPressed: Color(0xFF30A3D5),
    primarySubtle: Color(0xFF1E304D),
    accentHealthSubtle: Color(0xFF103644),
    accentTasksSubtle: Color(0xFF2B304D),
    accentCarSubtle: Color(0xFF332D47),
    successSubtle: Color(0xFF1A3939),
    warningSubtle: Color(0xFF36342B),
    dangerSubtle: Color(0xFF362837),
    infoSubtle: Color(0xFF17344D),
  );

  static const double scrimOpacityLight = 0.4;
  static const double scrimOpacityDark = 0.6;
  static const double stateHoverLayer = 0.08;
  static const double statePressedLayer = 0.12;
  static const double stateDisabledContent = 0.38;
  static const double stateDisabledSurface = 0.12;

  static const TokenElevation? elev0 = null;
  static const TokenElevation elev1 = TokenElevation(
    light: TokenShadow(
      x: 0,
      y: 4,
      blur: 16,
      color: Color(0xFF0F172A),
      opacity: 0.08,
    ),
    dark: TokenShadow(
      x: 0,
      y: 4,
      blur: 16,
      color: Color(0xFF000000),
      opacity: 0.4,
    ),
  );
  static const TokenElevation elev2 = TokenElevation(
    light: TokenShadow(
      x: 0,
      y: 8,
      blur: 24,
      color: Color(0xFF0F172A),
      opacity: 0.12,
    ),
    dark: TokenShadow(
      x: 0,
      y: 8,
      blur: 24,
      color: Color(0xFF000000),
      opacity: 0.5,
    ),
  );

  static const String fontFamilyFa = 'system';
  static const String fontFamilyLatin = 'system';
  static const List<FontWeight> weights = <FontWeight>[
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ];
  static const double letterSpacing = 0;
  static const TokenTextRole textCaption = TokenTextRole(
    size: 12,
    weight: FontWeight.w400,
    line: 20,
  );
  static const TokenTextRole textBodySm = TokenTextRole(
    size: 14,
    weight: FontWeight.w400,
    line: 24,
  );
  static const TokenTextRole textBody = TokenTextRole(
    size: 16,
    weight: FontWeight.w400,
    line: 28,
  );
  static const TokenTextRole textLabel = TokenTextRole(
    size: 14,
    weight: FontWeight.w500,
    line: 22,
  );
  static const TokenTextRole textTitleSm = TokenTextRole(
    size: 20,
    weight: FontWeight.w600,
    line: 30,
  );
  static const TokenTextRole textTitle = TokenTextRole(
    size: 24,
    weight: FontWeight.w600,
    line: 34,
  );
  static const TokenTextRole textHeading = TokenTextRole(
    size: 32,
    weight: FontWeight.w700,
    line: 44,
  );
  static const TokenTextRole textDisplay = TokenTextRole(
    size: 44,
    weight: FontWeight.w700,
    line: 58,
  );

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space12 = 48;

  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 9999;

  static const double touchMin = 44;
  static const double controlSm = 36;
  static const double controlMd = 44;
  static const double controlLg = 48;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double dotSm = 6;
  static const double dotMd = 8;
  static const double dotLg = 12;
  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double fab = 56;
  static const double bottomNavHeight = 64;
  static const double topbarHeight = 64;
  static const double sidePanelWidth = 420;
  static const double readingMaxWidth = 720;
  static const double ringDiameter = 184;
  static const double ringStroke = 10;
  static const double ringGap = 4;
  static const double stateIcon = 48;
  static const double contentMax = 1120;
  static const double sidebarWidthCollapsed = 72;
  static const double sidebarWidthOpen = 264;

  static const TokenLayout layoutCompact = TokenLayout(
    minWidth: 0,
    maxWidth: 599,
    pagePadding: 16,
    cardPadding: 16,
    cardGap: 16,
    sectionGap: 24,
  );
  static const TokenLayout layoutMedium = TokenLayout(
    minWidth: 600,
    maxWidth: 839,
    pagePadding: 24,
    cardPadding: 16,
    cardGap: 16,
    sectionGap: 24,
  );
  static const TokenLayout layoutExpanded = TokenLayout(
    minWidth: 840,
    maxWidth: 1199,
    pagePadding: 32,
    cardPadding: 24,
    cardGap: 24,
    sectionGap: 32,
  );
  static const TokenLayout layoutLarge = TokenLayout(
    minWidth: 1200,
    maxWidth: null,
    pagePadding: 32,
    cardPadding: 24,
    cardGap: 24,
    sectionGap: 32,
  );

  static const Duration durationInstant = Duration(milliseconds: 0);
  static const Duration durationMicro = Duration(milliseconds: 120);
  static const Duration durationExit = Duration(milliseconds: 200);
  static const Duration durationBase = Duration(milliseconds: 240);
  static const Duration durationEnter = Duration(milliseconds: 320);
  static const Duration durationMax = Duration(milliseconds: 350);
  static const Duration durationRingStagger = Duration(milliseconds: 60);
  static const Duration durationSpinnerLoop = Duration(milliseconds: 800);
  static const Duration durationSkeletonLoop = Duration(milliseconds: 1200);
  static const Duration durationBreatheLoop = Duration(milliseconds: 1600);

  static const Duration timingSkeletonDelay = Duration(milliseconds: 400);
  static const Duration timingToastVisible = Duration(milliseconds: 4000);
  static const Duration timingToastUndoVisible = Duration(milliseconds: 6000);
  static const Duration timingTooltipDelay = Duration(milliseconds: 500);

  static const Cubic curveStandard = Cubic(0.2, 0, 0, 1);
  static const Cubic curveDecelerate = Cubic(0, 0, 0, 1);
  static const Cubic curveAccelerate = Cubic(0.3, 0, 1, 1);
}
