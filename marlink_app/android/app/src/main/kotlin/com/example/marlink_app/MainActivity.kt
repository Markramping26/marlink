package com.example.marlink_app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.graphics.BitmapFactory
import android.graphics.Color
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.os.Build
import android.util.Rational
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PIP_CHANNEL = "com.marlink.app/pip"
    private val NOTIFICATION_CHANNEL = "com.marlink.app/notifications"
    private val NOTIF_SYSTEM_CHANNEL_ID = "marlink_alerts_channel"
    private val NOTIF_CALL_CHANNEL_ID = "marlink_calls_channel"

    private var pipChannel: MethodChannel? = null
    private var autoPipEnabled: Boolean = false
    private var ringtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Picture-in-Picture Channel
        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
        pipChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPip" -> {
                    val entered = enterPipMode()
                    result.success(entered)
                }
                "setAutoPip" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    autoPipEnabled = enabled
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(9, 16))
                                .setAutoEnterEnabled(enabled)
                                .build()
                            setPictureInPictureParams(params)
                        } catch (e: Exception) {
                            // Ignored if device doesn't support auto enter
                        }
                    }
                    result.success(true)
                }
                "isPipSupported" -> {
                    val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
                    result.success(supported)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Notifications Channel
        val notifChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
        createNotificationChannels()

        notifChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "MarLink Alert"
                    val body = call.argument<String>("body") ?: ""
                    val isAlert = call.argument<Boolean>("isAlert") ?: false
                    val isCall = call.argument<Boolean>("isCall") ?: false
                    val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()

                    showSystemNotification(id, title, body, isAlert, isCall)
                    result.success(true)
                }
                "playChime" -> {
                    try {
                        val toneGen = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 80)
                        toneGen.startTone(ToneGenerator.TONE_PROP_BEEP, 250)
                    } catch (e: Exception) {
                        // Ignored
                    }
                    result.success(true)
                }
                "startRingtone" -> {
                    startCallRingtone()
                    result.success(true)
                }
                "stopRingtone" -> {
                    stopCallRingtone()
                    result.success(true)
                }
                "cancelNotification" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    nm.cancel(id)
                    result.success(true)
                }
                "requestPermission" -> {
                    requestNotificationPermission()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enterPipMode(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
        ) {
            return try {
                val params = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(9, 16))
                    .build()
                enterPictureInPictureMode(params)
            } catch (e: Exception) {
                false
            }
        }
        return false
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (autoPipEnabled) {
            enterPipMode()
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // General alerts and chat messages channel
            val name = "MarLink Alerts & Room Notifications"
            val descriptionText = "Real-time SOS safety alerts, room chat messages, and location updates"
            val channel = NotificationChannel(
                NOTIF_SYSTEM_CHANNEL_ID,
                name,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = descriptionText
                enableLights(true)
                lightColor = Color.CYAN
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 150, 300)
            }
            notificationManager.createNotificationChannel(channel)

            // Dedicated High-Priority Incoming Calls Channel
            val callChannelName = "MarLink Voice & Video Calls"
            val callChannelDesc = "Incoming voice and video call alerts from circle members"
            val callChannel = NotificationChannel(
                NOTIF_CALL_CHANNEL_ID,
                callChannelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = callChannelDesc
                enableLights(true)
                lightColor = Color.GREEN
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500, 1000)
            }
            notificationManager.createNotificationChannel(callChannel)
        }
    }

    private fun startCallRingtone() {
        try {
            stopCallRingtone()
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ringtone = RingtoneManager.getRingtone(applicationContext, uri)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                ringtone?.isLooping = true
            }
            ringtone?.play()
        } catch (e: Exception) {
            try {
                val toneGen = ToneGenerator(AudioManager.STREAM_VOICE_CALL, 90)
                toneGen.startTone(ToneGenerator.TONE_SUP_RINGTONE, 3000)
            } catch (ex: Exception) {}
        }
    }

    private fun stopCallRingtone() {
        try {
            ringtone?.stop()
            ringtone = null
        } catch (e: Exception) {
            // Ignored
        }
    }

    private fun showSystemNotification(id: Int, title: String, body: String, isAlert: Boolean, isCall: Boolean) {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, flags)

        val smallIcon = resources.getIdentifier("ic_notification", "drawable", packageName).takeIf { it != 0 }
            ?: (applicationInfo.icon.takeIf { it != 0 } ?: android.R.drawable.ic_dialog_info)

        val largeIcon = try {
            val launcherId = resources.getIdentifier("ic_launcher", "mipmap", packageName).takeIf { it != 0 }
                ?: applicationInfo.icon.takeIf { it != 0 }
            if (launcherId != null && launcherId != 0) {
                BitmapFactory.decodeResource(resources, launcherId)
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }

        val targetChannel = if (isCall) NOTIF_CALL_CHANNEL_ID else NOTIF_SYSTEM_CHANNEL_ID

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val builder = Notification.Builder(this, targetChannel)
                .setSmallIcon(smallIcon)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)

            if (largeIcon != null) {
                builder.setLargeIcon(largeIcon)
            }

            if (isCall) {
                builder.setColor(Color.parseColor("#10b981")) // Emerald green
                builder.setCategory(Notification.CATEGORY_CALL)
            } else if (isAlert) {
                builder.setColor(Color.RED)
                builder.setCategory(Notification.CATEGORY_ALARM)
            } else {
                builder.setColor(Color.parseColor("#0ea5e9")) // MarLink Cyan/Sky
                builder.setCategory(Notification.CATEGORY_MESSAGE)
            }

            notificationManager.notify(id, builder.build())
        } else {
            @Suppress("DEPRECATION")
            val builder = Notification.Builder(this)
                .setSmallIcon(smallIcon)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .setPriority(if (isCall || isAlert) Notification.PRIORITY_MAX else Notification.PRIORITY_HIGH)

            if (largeIcon != null) {
                builder.setLargeIcon(largeIcon)
            }

            if (isCall) {
                builder.setVibrate(longArrayOf(0, 1000, 500, 1000))
            } else if (isAlert) {
                builder.setVibrate(longArrayOf(0, 500, 200, 500))
            }

            notificationManager.notify(id, builder.build())
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    1001
                )
            }
        }
    }
}
