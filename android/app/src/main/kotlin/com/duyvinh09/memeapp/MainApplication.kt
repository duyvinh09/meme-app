package com.duyvinh09.memeapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {
    companion object {
        const val CHAT_CHANNEL_ID = "chat_messages_channel_v3"
        const val FRIEND_CHANNEL_ID = "friend_requests_channel_v3"
        const val REMINDER_CHANNEL_ID = "expense_reminders_channel_v3"
        const val SOUND_RES_NAME = "meme_sound"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Clean up legacy channel IDs to ensure new channels with custom sound take effect
            val legacyChannelIds = listOf(
                "chat_messages_channel",
                "chat_messages_channel_v2",
                "friend_requests_channel",
                "friend_requests_channel_v2",
                "expense_reminders_channel",
                "expense_reminders_channel_v2"
            )
            for (oldChannel in legacyChannelIds) {
                try {
                    notificationManager.deleteNotificationChannel(oldChannel)
                } catch (_: Exception) {}
            }

            val soundUri = Uri.parse("${ContentResolver.SCHEME_ANDROID_RESOURCE}://${packageName}/raw/$SOUND_RES_NAME")
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            val chatChannel = NotificationChannel(
                CHAT_CHANNEL_ID,
                "Tin nhắn & Cảm xúc",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Thông báo khi có tin nhắn mới hoặc phản hồi cảm xúc"
                setSound(soundUri, audioAttributes)
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val friendChannel = NotificationChannel(
                FRIEND_CHANNEL_ID,
                "Lời mời & Bạn bè",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Thông báo lời mời kết bạn và tương tác bạn bè"
                setSound(soundUri, audioAttributes)
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val reminderChannel = NotificationChannel(
                REMINDER_CHANNEL_ID,
                "Nhắc nhở chi tiêu & Chuỗi",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Nhắc nhở ghi chép chi tiêu và duy trì chuỗi hàng ngày"
                setSound(soundUri, audioAttributes)
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            notificationManager.createNotificationChannel(chatChannel)
            notificationManager.createNotificationChannel(friendChannel)
            notificationManager.createNotificationChannel(reminderChannel)
        }
    }
}
