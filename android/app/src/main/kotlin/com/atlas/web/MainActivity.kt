package com.atlas.web

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.atlas.web/share"
    private var sharedText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSharedText") {
                result.success(sharedText)
                sharedText = null
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        // If the app is already running, we can actively push the new intent text to Flutter.
        // We'll fetch the flutterEngine and send it if it's ready.
        flutterEngine?.let {
            val text = sharedText
            if (text != null) {
                MethodChannel(it.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onSharedText", text)
                sharedText = null
            }
        }
    }

    private fun handleIntent(intent: Intent) {
        if (Intent.ACTION_SEND == intent.action && "text/plain" == intent.type) {
            sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        }
    }
}
