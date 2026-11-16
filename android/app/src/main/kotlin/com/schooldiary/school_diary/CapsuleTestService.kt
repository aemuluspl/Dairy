package com.schooldiary.school_diary

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper

/**
 * Эксперимент «Капля» (Android 16 Live Updates / promoted notifications).
 *
 * Сервис держит постоянное (`FLAG_ONGOING_EVENT`) уведомление с обратным
 * отсчётом и просит систему показать его в статус-баре как live update:
 * `Notification.ProgressStyle`, `setShortCriticalText` и extra
 * `android.requestPromotedOngoing`.
 *
 * Ветка экспериментальная: сервис запускается только кнопкой «Тест Капли»
 * в настройках и не используется основным сценарием приложения.
 */
class CapsuleTestService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var endsAt: Long = 0L

    private val ticker = object : Runnable {
        override fun run() {
            val remaining = remainingSeconds()
            if (remaining <= 0L) {
                stopSelf()
                return
            }
            publish(remaining)
            handler.postDelayed(this, TICK_MILLIS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (endsAt <= System.currentTimeMillis()) {
            endsAt = System.currentTimeMillis() + DURATION_MILLIS
        }
        startInForeground(remainingSeconds())
        handler.removeCallbacks(ticker)
        handler.postDelayed(ticker, TICK_MILLIS)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(ticker)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    private fun remainingSeconds(): Long {
        val left = endsAt - System.currentTimeMillis()
        return (left / 1000L).coerceAtLeast(0L)
    }

    private fun startInForeground(remaining: Long) {
        val notification = buildNotification(remaining)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    /** Обновление таймера не должно ронять сервис. */
    private fun publish(remaining: Long) {
        try {
            notificationManager().notify(NOTIFICATION_ID, buildNotification(remaining))
        } catch (_: Throwable) {
            // Уведомление могло быть заблокировано пользователем.
        }
    }

    private fun buildNotification(remaining: Long): Notification {
        ensureChannel(notificationManager())
        val elapsed = (DURATION_SECONDS - remaining).coerceIn(0L, DURATION_SECONDS)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(R.drawable.ic_capsule_test)
            .setContentTitle(getString(R.string.capsule_title))
            .setContentText(getString(R.string.capsule_remaining, formatTime(remaining)))
            .setSubText(getString(R.string.capsule_subtitle))
            .setColor(ACCENT)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setAutoCancel(false)
            .setCategory(Notification.CATEGORY_PROGRESS)
            .setShowWhen(true)
            .setWhen(System.currentTimeMillis() + remaining * 1000L)
            .setUsesChronometer(true)
            .setContentIntent(contentIntent())
            .addExtras(promotionExtras())
            .addAction(stopAction())

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setChronometerCountDown(true)
        }

        // Android 16: прогресс-стиль и короткий текст в капсуле.
        if (Build.VERSION.SDK_INT >= 36) {
            progressStyle(elapsed)?.let { style -> builder.setStyle(style) }
            builder.setShortCriticalText(formatTime(remaining))
        }

        return builder.build()
    }

    /**
     * `Notification.ProgressStyle` — обязательная часть live update:
     * по нему система рисует полосу прогресса в капсуле и шторке.
     */
    private fun progressStyle(elapsed: Long): Notification.ProgressStyle? {
        if (Build.VERSION.SDK_INT < 36) return null
        val total = DURATION_SECONDS.toInt()
        return try {
            Notification.ProgressStyle()
                .setStyledByProgress(true)
                .setProgress(elapsed.toInt().coerceIn(0, total))
                .setProgressSegments(
                    listOf(
                        Notification.ProgressStyle.Segment(total).setColor(ACCENT),
                    ),
                )
                .setProgressPoints(
                    listOf(
                        Notification.ProgressStyle.Point(total / 4).setColor(POINT),
                        Notification.ProgressStyle.Point(total / 2).setColor(POINT),
                        Notification.ProgressStyle.Point(total * 3 / 4).setColor(POINT),
                    ),
                )
        } catch (_: Throwable) {
            null
        }
    }

    /**
     * Extra `android.requestPromotedOngoing` — то же, что делает
     * `NotificationCompat.Builder.setRequestPromotedOngoing(true)`.
     * Без него система не рассматривает уведомление как каплю.
     */
    private fun promotionExtras(): Bundle {
        return Bundle().apply {
            putBoolean(EXTRA_REQUEST_PROMOTED_ONGOING, true)
        }
    }

    private fun stopAction(): Notification.Action {
        return Notification.Action.Builder(
            null as android.graphics.drawable.Icon?,
            getString(R.string.capsule_stop),
            stopIntent(),
        ).build()
    }

    private fun contentIntent(): PendingIntent {
        val launch = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(this, CONTENT_REQUEST, launch, pendingFlags())
    }

    private fun stopIntent(): PendingIntent {
        val intent = Intent(this, CapsuleTestService::class.java).setAction(ACTION_STOP)
        return PendingIntent.getService(this, STOP_REQUEST, intent, pendingFlags())
    }

    private fun pendingFlags(): Int {
        return PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    }

    private fun notificationManager(): NotificationManager {
        return getSystemService(NotificationManager::class.java)
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.capsule_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = getString(R.string.capsule_channel_description)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun formatTime(seconds: Long): String {
        val total = seconds.coerceAtLeast(0L)
        return "%d:%02d".format(total / 60, total % 60)
    }

    companion object {
        const val ACTION_STOP =
            "com.schooldiary.school_diary.CAPSULE_TEST_STOP"

        private const val CHANNEL_ID = "hash_capsule_test"
        private const val NOTIFICATION_ID = 7413
        private const val CONTENT_REQUEST = 7414
        private const val STOP_REQUEST = 7415

        private const val TICK_MILLIS = 1_000L
        private const val DURATION_MILLIS = 10 * 60 * 1_000L
        private const val DURATION_SECONDS = 10 * 60L

        private const val EXTRA_REQUEST_PROMOTED_ONGOING =
            "android.requestPromotedOngoing"

        private val ACCENT = Color.parseColor("#5B5BD6")
        private val POINT = Color.parseColor("#B4B4FF")
    }
}
