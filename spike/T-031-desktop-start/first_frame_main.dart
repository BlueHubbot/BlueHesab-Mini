// T-031 (SP-09): entry point that runs the unchanged root app and ends the
// process once the first frame is rasterized, so a launcher can time
// spawn -> first frame -> exit. Built from the root package with
// `flutter build <os> --release -t spike/T-031-desktop-start/first_frame_main.dart`.
// Not product code: nothing in lib/ or test/ imports this file
// (spike/README.md rule 2), and lib/main.dart is not changed.
import 'dart:io';

import 'package:bluehesab_mini/main.dart';
import 'package:flutter/widgets.dart';

/// Exit code that proves the process ended through this marker, not a crash.
const int firstFrameExitCode = 37;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlueHesabApp());
  await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
  exit(firstFrameExitCode);
}
