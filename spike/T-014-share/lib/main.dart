import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fingerprint.dart';
import 'share_inbox.dart';

// T-014 (SP-07, emulator half). Evidence, not product: the visible strings
// are copy keys, never Persian literals (CM-10). Nothing is saved (CAP-C5):
// the text only fills a draft field.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SpikeShareApp(inbox: ShareInbox()));
}

/// Keys the tests use.
abstract final class SpikeKeys {
  static const ValueKey<String> draft = ValueKey<String>('draft');
  static const ValueKey<String> paste = ValueKey<String>('paste');
  static const ValueKey<String> source = ValueKey<String>('source');
}

/// Shows the last received text in a draft field.
class SpikeShareApp extends StatefulWidget {
  /// Creates the app around [inbox].
  const SpikeShareApp({required this.inbox, super.key});

  /// Share glue.
  final ShareInbox inbox;

  @override
  State<SpikeShareApp> createState() => _SpikeShareAppState();
}

class _SpikeShareAppState extends State<SpikeShareApp> {
  final TextEditingController _draft = TextEditingController();
  String _source = 'none';

  @override
  void initState() {
    super.initState();
    widget.inbox.listen((text) => _receive('warm', text));
    widget.inbox.takeInitialText().then((text) {
      if (text != null) _receive('cold', text);
    });
  }

  @override
  void dispose() {
    widget.inbox.close();
    _draft.dispose();
    super.dispose();
  }

  void _receive(String source, String text) {
    // The marker carries length and fingerprint only, never the text.
    // ignore: avoid_print
    print(shareMarker(source, text));
    if (!mounted) return;
    setState(() {
      _source = source;
      _draft.text = text;
    });
  }

  /// Reads the clipboard only here, on an explicit tap (CAPTURE_PIPELINE §6).
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) _receive('clipboard', text);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('spike.share.title')),
          body: ListView(
            children: [
              Text('spike.share.source:$_source', key: SpikeKeys.source),
              TextField(
                key: SpikeKeys.draft,
                controller: _draft,
                maxLines: null,
                maxLength: 4000,
              ),
              TextButton(
                key: SpikeKeys.paste,
                onPressed: _paste,
                child: const Text('spike.share.paste'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
