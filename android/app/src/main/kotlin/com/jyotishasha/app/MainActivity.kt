package com.jyotishasha.app

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val panchangNotificationChannel = "jyotishasha.app/panchang_notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, panchangNotificationChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "dismissByTag" -> {
                        val tag = call.argument<String>("tag")
                        result.success(dismissNotificationByTag(tag))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Cancels ONLY the single active notification whose tag matches [tag] —
     * every other active notification (Festival, Vrat, Transit, Muhurat, or
     * anything else) is left untouched. Returns true if a match was found
     * and cancelled, false otherwise (no tag supplied, unsupported Android
     * version, or nothing currently posted with that tag).
     */
    private fun dismissNotificationByTag(tag: String?): Boolean {
        if (tag.isNullOrEmpty()) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val match = notificationManager.activeNotifications.firstOrNull { it.tag == tag }
            ?: return false

        notificationManager.cancel(match.tag, match.id)
        return true
    }
}
