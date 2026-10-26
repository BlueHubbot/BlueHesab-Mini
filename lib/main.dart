// T-001 skeleton (ADR-0009 §1, SP-01): an empty right-to-left page.
//
// Rules this file follows:
// - No raw colors, sizes or durations (TK-13, TY-02): framework defaults only
//   until the generated tokens exist (T-003).
// - No user-facing strings (CM-10): the page shows no text yet.
// - Font: platform default (`system`) until ADR-UI-003 is accepted
//   (ui-spec §3-1, table 12-1-a, AD-06).
import 'package:flutter/material.dart';

void main() {
  runApp(const BlueHesabApp());
}

/// Root widget of the skeleton. Replaced by the real app shell in M1.
class BlueHesabApp extends StatelessWidget {
  const BlueHesabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Persian-first: everything below the app root is right-to-left.
      // Localization delegates arrive with the copy catalog (CM-10).
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const EmptyRtlPage(),
    );
  }
}

/// The empty page of the skeleton.
class EmptyRtlPage extends StatelessWidget {
  const EmptyRtlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.expand(key: Key('empty-rtl-page')));
  }
}
