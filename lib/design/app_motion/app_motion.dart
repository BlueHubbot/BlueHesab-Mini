/// Package `app_motion` (MT-11, MX-03, CM-08, AGR-01).
///
/// The only place in `lib/` that reads motion tokens and builds animations;
/// widgets elsewhere ask `context.motion` (section 4-2). Slice 1 (T-037)
/// holds the values, the catalog of table 4-3 and the reduced-motion rules
/// RM-01 and RM-02; slice 2 (T-039) adds MotionHandle and the MX-08
/// MotionRegistry; slice 3 (T-040) lets a live handle follow an RM-01
/// change at once; slice 4 (T-042) names the MT-05 sizes and the MT-06
/// direction; the animated widgets arrive with their components.
library;

export 'src/motion_catalog.dart';
export 'src/motion_handle.dart';
export 'src/motion_magnitude.dart';
export 'src/motion_resolve.dart';
export 'src/motion_scope.dart';
export 'src/motion_tokens.dart';
export 'src/reduced_motion.dart';
