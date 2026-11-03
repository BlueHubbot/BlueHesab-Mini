// T-011 toy subject for the golden harness (SP-06). Material widgets with
// their default theme values only: no raw colours, sizes or durations
// (TK-13), and every visible text is a copy-catalog key (CM-10).

import 'package:flutter/material.dart';

/// When true (`--dart-define=TOY_MUTATE=true`), the progress value moves by
/// 0.002, which is less than one pixel of the bar. The compare job expects
/// the golden test to fail then (GM-01: exact match, no threshold).
const bool toyMutate = bool.fromEnvironment('TOY_MUTATE');

/// Progress shown by the determinate bar.
const double toyProgress = toyMutate ? 0.602 : 0.6;

/// One combination of the GMX-01 matrix: theme × direction × text scale.
@immutable
class GoldenCase {
  /// Creates a case.
  const GoldenCase({
    required this.dark,
    required this.rtl,
    required this.scale,
  });

  /// Dark theme when true, light otherwise.
  final bool dark;

  /// Right-to-left when true.
  final bool rtl;

  /// Text scale: 1.0 or 2.0.
  final double scale;

  /// File stem per GM-02: `<state>__<theme>_<dir>_s<scale>`.
  String fileStem(String state) =>
      '${state}__${dark ? 'dark' : 'light'}_${rtl ? 'rtl' : 'ltr'}'
      '_s${(scale * 10).round()}';

  /// The 8 combinations of GMX-01, base case (DS-01: light, RTL, 1.0) first.
  static const List<GoldenCase> all = <GoldenCase>[
    GoldenCase(dark: false, rtl: true, scale: 1),
    GoldenCase(dark: false, rtl: true, scale: 2),
    GoldenCase(dark: false, rtl: false, scale: 1),
    GoldenCase(dark: false, rtl: false, scale: 2),
    GoldenCase(dark: true, rtl: true, scale: 1),
    GoldenCase(dark: true, rtl: true, scale: 2),
    GoldenCase(dark: true, rtl: false, scale: 1),
    GoldenCase(dark: true, rtl: false, scale: 2),
  ];
}

/// The app frame of one case: theme, direction and text scale are fixed
/// here so that nothing is read from the host (DS-01, VR-04).
class ToyHarness extends StatelessWidget {
  /// Creates the frame.
  const ToyHarness({required this.goldenCase, super.key});

  /// The combination to render.
  final GoldenCase goldenCase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: goldenCase.dark ? Brightness.dark : Brightness.light,
      ),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(goldenCase.scale),
        ),
        child: Directionality(
          textDirection: goldenCase.rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const Scaffold(
        body: SafeArea(child: ToyCard()),
      ),
    );
  }
}

/// The toy card: text, an LTR number inside the page direction, a
/// determinate bar, an indeterminate spinner (frozen at time zero by the
/// test, GM-07), a button and the card's own shadow.
class ToyCard extends StatelessWidget {
  /// Creates the card.
  const ToyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const ListTile(
            title: Text('toy.title'),
            subtitle: Text('1234567890', textDirection: TextDirection.ltr),
            trailing: CircularProgressIndicator(),
          ),
          const LinearProgressIndicator(value: toyProgress),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: <Widget>[
              FilledButton(onPressed: () {}, child: const Text('toy.action')),
            ],
          ),
        ],
      ),
    );
  }
}
