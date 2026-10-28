// Tool tests of the MVP profile and manifest (ADR-UI-009 acceptance tests
// 1, 4, 5, 6; VR-07).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ui_check/src/manifest.dart';
import '../../tool/ui_check/src/sha256.dart';
import '../../tool/ui_check/src/tokens_stage.dart';
import '../../tool/ui_check/ui_check.dart';

final List<int> _json = File(tokensPath).readAsBytesSync();
final List<int> _manifest = File(manifestPath).readAsBytesSync();

StageResult _run(List<int>? manifest, Profile profile) => runTokensStage(
      jsonBytes: _json,
      generatedBytes: File('lib/design/tokens/design_tokens.g.dart')
          .readAsBytesSync(),
      manifestBytes: manifest,
      profile: profile,
    );

List<int> _manifestWith(Map<String, Object?> changes) {
  final Map<String, Object?> m =
      (jsonDecode(utf8.decode(_manifest)) as Map<String, Object?>)
        ..addAll(changes);
  return utf8.encode(jsonEncode(m));
}

void main() {
  test('mvp lists the exact NOT_IN_BUILD set and passes (test 1)', () {
    final ManifestResult m = readManifest(_manifest);
    expect(m.errors, isEmpty);
    expect(m.notInBuild['components'], <String>[
      'OfflineBanner',
      'SyncStatus',
      'Badge',
      'PercentageChange',
      'NumericColumnMetrics',
      'AIActionCard',
    ]);
    expect(m.notInBuild['destinations'],
        <String>['tasks', 'health', 'car', 'markets', 'assistant']);
    expect(m.notInBuild['quickAddTypes'], <String>['task']);
    expect(m.exemptionCount, 12);

    final StageResult r = _run(_manifest, Profile.mvp);
    expect(r.passed, isTrue, reason: r.report.join('\n'));
    expect(r.report, contains('NOT_IN_BUILD (12):'));
    expect(
      r.report,
      contains('  quickAddTypes (1): task'),
    );
  });

  test('full fails while any exemption exists (test 4)', () {
    final StageResult r = _run(_manifest, Profile.full);
    expect(r.failedRules, <String>['ADR-UI-009']);
    expect(r.report.last, 'Result: FAIL (ADR-UI-009)');
  });

  test('full passes when the manifest holds every catalogue item', () {
    final List<int> all = _manifestWith(<String, Object?>{
      'components': componentCatalog,
      'destinations': destinationCatalog,
      'quickAddTypes': quickAddTypeCatalog,
    });
    expect(_run(all, Profile.full).passed, isTrue);
  });

  test('the report states profile and manifest hash (test 5)', () {
    final StageResult r = _run(_manifest, Profile.mvp);
    expect(
      r.report.first,
      'ui_check tokens · profile=mvp · manifest sha256 ${sha256Hex(_manifest)}',
    );
  });

  test('a missing manifest fails', () {
    expect(_run(null, Profile.mvp).failedRules, <String>['ADR-UI-009']);
  });

  test('a manifest without a core destination fails ND-02', () {
    final List<int> m = _manifestWith(<String, Object?>{
      'destinations': <String>['home', 'accounting', 'settings', 'budget'],
    });
    expect(_run(m, Profile.mvp).failedRules, <String>['ND-02']);
  });

  test('an unknown component name fails', () {
    final List<int> m = _manifestWith(<String, Object?>{
      'components': <String>['Button', 'FancyCarousel'],
    });
    expect(_run(m, Profile.mvp).failedRules, <String>['ADR-UI-009']);
  });

  test('an extra exemption key fails (no ad-hoc ignore lists, VR-03)', () {
    final List<int> m = _manifestWith(<String, Object?>{
      'skipRules': <String>['VT-02'],
    });
    expect(_run(m, Profile.mvp).failedRules, <String>['ADR-UI-009']);
  });

  test('a profile other than mvp inside the manifest fails', () {
    final List<int> m = _manifestWith(<String, Object?>{'profile': 'lite'});
    expect(_run(m, Profile.mvp).failedRules, <String>['ADR-UI-009']);
  });

  test('the command line rejects an unknown profile', () {
    final StringBuffer err = StringBuffer();
    expect(runCli(<String>['--profile=lite'], StringBuffer(), err), 64);
    expect(err.toString(), contains('usage:'));
  });

  test('sha256 matches the FIPS 180-4 vectors', () {
    expect(
      sha256Hex(utf8.encode('')),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
    expect(
      sha256Hex(utf8.encode('abc')),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    expect(
      sha256Hex(utf8.encode(
          'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')),
      '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
    );
  });
}
