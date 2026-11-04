import 'package:flutter/services.dart';

/// Dart side of the share glue in native/MainActivity.kt (SP-07).
///
/// * `takeInitialText`: the `ACTION_SEND` `text/plain` text that started the
///   activity (cold start), returned once, then null.
/// * `sharedText` (native to Dart): a share that reached the running
///   activity through `onNewIntent`.
///
/// On hosts without the native side (desktop, web, `flutter test`) the
/// method is missing and [takeInitialText] returns null.
class ShareInbox {
  /// Uses [channel] when given (tests), else the real channel.
  ShareInbox({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  /// Must match `CHANNEL` in native/MainActivity.kt.
  static const String channelName = 'spike.share/intent';

  final MethodChannel _channel;

  /// The text of the share that started the app, or null.
  Future<String?> takeInitialText() async {
    try {
      final text = await _channel.invokeMethod<String>('takeInitialText');
      return (text == null || text.isEmpty) ? null : text;
    } on MissingPluginException {
      return null;
    }
  }

  /// Calls [onText] for every later non-empty share.
  void listen(void Function(String text) onText) {
    _channel.setMethodCallHandler((MethodCall call) async {
      final args = call.arguments;
      if (call.method == 'sharedText' && args is String && args.isNotEmpty) {
        onText(args);
      }
      return null;
    });
  }

  /// Stops listening.
  void close() => _channel.setMethodCallHandler(null);
}
