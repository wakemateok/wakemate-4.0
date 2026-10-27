package com.example.my_app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "wakemate/notification_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidSdk" -> result.success(Build.VERSION.SDK_INT)
                    "openNotificationSettings", "openChannelSettings" -> {
                        val channelId = call.argument<String>("channelId")
                        if (call.method == "openChannelSettings" && channelId !in setOf(
                                "wakemate_caffeine_reminders_v2_zh",
                                "wakemate_caffeine_reminders_v2_en",
                                "wakemate_caffeine_reminders_v2_id")) {
                            result.error("invalid_notification_channel", null, null)
                            return@setMethodCallHandler
                        }
                        val appDetails = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName"))
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            if (call.method == "openChannelSettings") {
                                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                    .putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
                            } else {
                                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                        } else appDetails
                        try {
                            try {
                                startActivity(intent)
                            } catch (_: ActivityNotFoundException) {
                                startActivity(appDetails)
                            }
                            result.success(null)
                        } catch (_: Exception) {
                            result.error("notification_settings_unavailable", null, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
