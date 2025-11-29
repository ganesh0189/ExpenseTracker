package com.moneytracker.money_tracker

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.moneytracker/notifications"
    private val EVENT_CHANNEL = "com.moneytracker/notification_events"

    private var eventSink: EventChannel.EventSink? = null

    // Payment app package names
    private val paymentApps = mapOf(
        "com.google.android.apps.nbu.paisa.user" to "Google Pay",
        "com.phonepe.app" to "PhonePe",
        "net.one97.paytm" to "Paytm",
        "in.amazon.mShop.android.shopping" to "Amazon",
        "com.whatsapp" to "WhatsApp Pay",
        "com.csam.icici.bank.imobile" to "ICICI Bank",
        "com.sbi.SBIFreedomPlus" to "SBI YONO",
        "com.axis.mobile" to "Axis Mobile",
        "com.msf.kbank.mobile" to "Kotak",
        "com.snapwork.hdfc" to "HDFC Bank"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isEnabled" -> {
                        result.success(isNotificationListenerEnabled())
                    }
                    "openSettings" -> {
                        openNotificationListenerSettings()
                        result.success(true)
                    }
                    "requestPermission" -> {
                        val granted = requestNotificationPermission()
                        result.success(granted)
                    }
                    "getInstalledApps" -> {
                        result.success(getInstalledPaymentApps())
                    }
                    "isAppInstalled" -> {
                        val packageName = call.argument<String>("packageName")
                        result.success(isAppInstalled(packageName ?: ""))
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }

        // Set up Event Channel for streaming notifications
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // Set callback for notification service
                    PaymentNotificationListenerService.notificationCallback = { data ->
                        runOnUiThread {
                            eventSink?.success(data)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    PaymentNotificationListenerService.notificationCallback = null
                }
            })
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val packageName = packageName
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":".toRegex())
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && TextUtils.equals(packageName, cn.packageName)) {
                    return true
                }
            }
        }
        return false
    }

    private fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun requestNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val notificationManager = NotificationManagerCompat.from(this)
            if (!notificationManager.areNotificationsEnabled()) {
                val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                startActivity(intent)
                false
            } else {
                true
            }
        } else {
            true
        }
    }

    private fun getInstalledPaymentApps(): List<Map<String, String>> {
        val installedApps = mutableListOf<Map<String, String>>()
        val pm = packageManager

        for ((packageName, appName) in paymentApps) {
            if (isAppInstalled(packageName)) {
                installedApps.add(
                    mapOf(
                        "packageName" to packageName,
                        "appName" to appName
                    )
                )
            }
        }

        return installedApps
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        eventSink = null
        PaymentNotificationListenerService.notificationCallback = null
    }
}
