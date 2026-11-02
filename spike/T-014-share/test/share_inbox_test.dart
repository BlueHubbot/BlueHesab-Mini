// Host tests for the Dart side of the share glue (T-014, SP-07). The native
// side runs only on the emulator job (.github/workflows/spike-share.yml).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_share/fingerprint.dart';
import 'package:spike_share/main.dart';
import 'package:spike_share/share_inbox.dart';

// Synthetic Persian text with Persian digits, an Arabic thousands separator
// and an LTR number, as escapes (no Persian literal in code, CM-10).
const String persianSample = 'برداشت '
    '۱۲۳٬۴۵۰ '
    'ریال، مانده 98,765';

const MethodChannel channel = MethodChannel(ShareInbox.channelName);

Future<void> sendFromNative(String method, Object? args) async {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  await messenger.handlePlatformMessage(
    ShareInbox.channelName,
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
    (_) {},
  );
}

void mockInitial(String? text) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (call.method == 'takeInitialText') return text;
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('fingerprint (same vectors as tool/share_cases.py)', () {
    test('FNV-1a 32 reference vectors', () {
      expect(fnv1a32Hex(''), '811c9dc5');
      expect(fnv1a32Hex('a'), 'e40c292c');
      expect(fnv1a32Hex('Synthetic share 1234567890 IRR'), '3b97f3c3');
      expect(fnv1a32Hex(persianSample), 'e6c70ebc');
    });

    test('marker carries length and hash, not the text', () {
      final marker = shareMarker('cold', persianSample);
      expect(marker, 'SPIKE_SHARE source=cold chars=33 fnv=e6c70ebc');
      expect(marker.contains(persianSample), isFalse);
    });
  });

  group('ShareInbox', () {
    test('initial text is returned when the native side has one', () async {
      mockInitial(persianSample);
      expect(await ShareInbox().takeInitialText(), persianSample);
    });

    test('empty or missing initial text is null', () async {
      mockInitial('');
      expect(await ShareInbox().takeInitialText(), isNull);
      mockInitial(null);
      expect(await ShareInbox().takeInitialText(), isNull);
    });

    test('no native side (desktop, web, host) gives null', () async {
      expect(await ShareInbox().takeInitialText(), isNull);
    });

    test('later shares reach the listener; other calls are ignored', () async {
      final got = <String>[];
      final inbox = ShareInbox()..listen(got.add);
      await sendFromNative('sharedText', 'first');
      await sendFromNative('sharedText', '');
      await sendFromNative('sharedText', 42);
      await sendFromNative('other', 'ignored');
      await sendFromNative('sharedText', persianSample);
      inbox.close();
      expect(got, ['first', persianSample]);
    });
  });

  group('app', () {
    testWidgets('cold-start share fills the draft field', (tester) async {
      mockInitial(persianSample);
      await tester.pumpWidget(SpikeShareApp(inbox: ShareInbox()));
      await tester.pump();
      final field = tester.widget<TextField>(find.byKey(SpikeKeys.draft));
      expect(field.controller!.text, persianSample);
      expect(find.text('spike.share.source:cold'), findsOneWidget);
    });

    testWidgets('a share while running replaces the draft', (tester) async {
      mockInitial(null);
      await tester.pumpWidget(SpikeShareApp(inbox: ShareInbox()));
      await tester.pump();
      await sendFromNative('sharedText', 'second share');
      await tester.pump();
      final field = tester.widget<TextField>(find.byKey(SpikeKeys.draft));
      expect(field.controller!.text, 'second share');
      expect(find.text('spike.share.source:warm'), findsOneWidget);
    });
  });
}
