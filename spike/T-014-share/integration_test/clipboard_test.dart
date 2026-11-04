// On-device test (Android emulator in CI): the clipboard is read only on
// tap (CAPTURE_PIPELINE §6, SP-07). Limitation: the test puts the text on
// the system clipboard from this app; a copy made in another app is a
// real-phone item (T-014 README).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spike_share/main.dart';
import 'package:spike_share/share_inbox.dart';

const String persianSample = 'برداشت '
    '۱۲۳٬۴۵۰ '
    'ریال، مانده 98,765';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clipboard is read only after the tap', (tester) async {
    await Clipboard.setData(const ClipboardData(text: persianSample));
    await tester.pumpWidget(SpikeShareApp(inbox: ShareInbox()));
    await tester.pumpAndSettle();

    TextField field() => tester.widget<TextField>(find.byKey(SpikeKeys.draft));
    expect(field().controller!.text, isEmpty, reason: 'no read before tap');

    await tester.tap(find.byKey(SpikeKeys.paste));
    await tester.pumpAndSettle();
    expect(field().controller!.text, persianSample);
    expect(find.text('spike.share.source:clipboard'), findsOneWidget);
  });
}
