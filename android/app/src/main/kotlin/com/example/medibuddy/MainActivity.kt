package com.example.medibuddy

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        normalizeNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        normalizeNotificationIntent(intent)
    }

    private fun normalizeNotificationIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action != "SELECT_NOTIFICATION") return
        val payload = intent.getStringExtra("payload") ?: return
        if (!payload.startsWith("com.example.medibuddy://")) return
        intent.data = Uri.parse(payload)
        setIntent(intent)
        Log.d("MainActivity", "Normalized SELECT_NOTIFICATION to uri=$payload")
    }
}
