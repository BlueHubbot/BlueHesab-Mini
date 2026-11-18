// RM-01: the three-way reduced-motion setting (T-037). The labels live in
// the copy catalog (CM-10) and the stored value in settings (later tasks).

/// The reduced-motion setting of RM-01.
enum ReducedMotionSetting {
  /// Follow the operating system (default).
  followSystem,

  /// Always reduce motion.
  on,

  /// Never reduce motion.
  off,
}

/// RM-01: reduced motion is on when the setting is [ReducedMotionSetting.on],
/// or when it follows the system and the system asks for it
/// (`MediaQuery.disableAnimations`).
bool resolveReduced(
  ReducedMotionSetting setting, {
  required bool systemDisableAnimations,
}) =>
    switch (setting) {
      ReducedMotionSetting.on => true,
      ReducedMotionSetting.off => false,
      ReducedMotionSetting.followSystem => systemDisableAnimations,
    };
