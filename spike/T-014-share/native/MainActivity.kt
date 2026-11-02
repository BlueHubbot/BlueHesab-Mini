// T-014 (SP-07): share glue without any plugin. Copied over the generated
// MainActivity.kt by tool/prepare_android.py; the package line must match the
// one `flutter create --org dev.bluehesab.spike --project-name spike_share`
// writes. Accepts ACTION_SEND text/plain only and needs no permission.
package dev.bluehesab.spike.spike_share

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Read before super.onCreate starts the engine, so Dart's first call
        // always finds it.
        initialText = sharedText(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        ch.setMethodCallHandler { call, result ->
            if (call.method == "takeInitialText") {
                val text = initialText
                initialText = null
                result.success(text)
            } else {
                result.notImplemented()
            }
        }
        channel = ch
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val text = sharedText(intent) ?: return
        channel?.invokeMethod("sharedText", text)
    }

    private fun sharedText(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_SEND) return null
        val type = intent.type ?: return null
        if (!type.startsWith("text/plain")) return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)
    }

    companion object {
        // Must match ShareInbox.channelName in lib/share_inbox.dart.
        private const val CHANNEL = "spike.share/intent"
    }
}
