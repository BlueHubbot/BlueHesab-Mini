// T-002 acceptance check: no floating-point type on the money path (I-01,
// MN-01, MC-19). Scans every Dart file under lib/ with comments removed.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _forbidden = RegExp(r'\b(double|num)\b|toDouble|\.parseDouble');

/// Offending lines of [source], ignoring `//` comments.
List<String> floatUses(String source) {
  final hits = <String>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final code = lines[i].split('//').first;
    if (_forbidden.hasMatch(code)) {
      hits.add('${i + 1}: ${lines[i].trim()}');
    }
  }
  return hits;
}

void main() {
  test('the check itself catches a float (negative control)', () {
    expect(floatUses('final double x = 1;'), isNotEmpty);
    expect(floatUses('num y = 2;'), isNotEmpty);
    expect(floatUses('final v = n.toDouble();'), isNotEmpty);
    expect(floatUses('// a double in a comment is fine'), isEmpty);
    expect(floatUses('final number = 3;'), isEmpty);
  });

  test('lib/ has no double or num (I-01)', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty);
    final hits = <String>[
      for (final f in files)
        for (final hit in floatUses(f.readAsStringSync())) '${f.path}:$hit',
    ];
    expect(hits, isEmpty);
  });
}
