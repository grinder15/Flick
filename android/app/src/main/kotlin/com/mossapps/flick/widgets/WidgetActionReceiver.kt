package com.mossapps.flick.widgets

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val uri = intent.data?.toString() ?: return
        val engine = FlutterEngineCache.getInstance().get("main_engine") ?: return
        MethodChannel(engine.dartExecutor.binaryMessenger, "com.mossapps.flick/widget")
            .invokeMethod("dispatch", uri)
    }
}
