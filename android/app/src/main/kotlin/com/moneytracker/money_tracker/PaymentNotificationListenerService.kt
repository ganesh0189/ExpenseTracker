package com.moneytracker.money_tracker

import android.app.Notification
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class PaymentNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "PaymentNotifListener"

        // Payment app package names to monitor
        private val PAYMENT_APPS = setOf(
            "com.google.android.apps.nbu.paisa.user",  // Google Pay
            "com.phonepe.app",                          // PhonePe
            "net.one97.paytm",                          // Paytm
            "in.amazon.mShop.android.shopping",         // Amazon Pay
            "com.whatsapp",                             // WhatsApp Pay
            "com.csam.icici.bank.imobile",              // ICICI Bank
            "com.sbi.SBIFreedomPlus",                   // SBI YONO
            "com.axis.mobile",                          // Axis Mobile
            "com.msf.kbank.mobile",                     // Kotak
            "com.snapwork.hdfc",                        // HDFC Bank
        )

        // Callback to send notifications to Flutter
        var notificationCallback: ((Map<String, String>) -> Unit)? = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return

        val packageName = sbn.packageName ?: return

        // Check if this is a payment app we're monitoring
        if (!PAYMENT_APPS.contains(packageName)) {
            return
        }

        try {
            val notification = sbn.notification ?: return
            val extras = notification.extras ?: return

            // Extract notification content
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: text

            // Use bigText if available, otherwise use text
            val content = if (bigText.isNotEmpty()) bigText else text

            if (content.isEmpty()) return

            Log.d(TAG, "Payment notification from $packageName: $content")

            // Send to Flutter
            val data = mapOf(
                "packageName" to packageName,
                "title" to title,
                "text" to content
            )

            notificationCallback?.invoke(data)

        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification: ${e.message}")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Not needed for our use case
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Notification listener connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification listener disconnected")
    }
}
