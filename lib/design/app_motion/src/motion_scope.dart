// `context.motion` (section 4-2) and the scope that carries the RM-01
// setting (T-037). A change of the setting rebuilds dependants at once, with
// no restart (RM-01).

import 'package:bluehesab_mini/design/app_motion/src/motion_tokens.dart';
import 'package:bluehesab_mini/design/app_motion/src/reduced_motion.dart';
import 'package:flutter/widgets.dart';

/// Carries the user's reduced-motion setting (RM-01) down the tree.
class AppMotionScope extends InheritedWidget {
  /// Creates the scope.
  const AppMotionScope({
    super.key,
    required this.setting,
    required super.child,
  });

  /// The user's setting.
  final ReducedMotionSetting setting;

  /// The nearest setting, or [ReducedMotionSetting.followSystem] (the RM-01
  /// default) when there is no scope.
  static ReducedMotionSetting settingOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppMotionScope>()?.setting ??
      ReducedMotionSetting.followSystem;

  @override
  bool updateShouldNotify(AppMotionScope oldWidget) =>
      oldWidget.setting != setting;
}

/// `context.motion`: the only way UI code reads motion (MX-03).
extension AppMotionContext on BuildContext {
  /// Motion values and the reduced flag for this context (RM-01).
  AppMotion get motion => AppMotion(
        reduced: resolveReduced(
          AppMotionScope.settingOf(this),
          systemDisableAnimations:
              MediaQuery.maybeDisableAnimationsOf(this) ?? false,
        ),
      );
}
