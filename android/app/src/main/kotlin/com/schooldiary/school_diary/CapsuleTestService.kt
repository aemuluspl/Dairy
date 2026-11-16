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
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Эксперимент «Капля» (Android 16 Live Updates / promoted notifications).
 *
 * Таймер полностью нативный: уведомление публикуется **один раз**, а секунды
 * рисует системный `Chronometer` (`setUsesChronometer` + `setChronometerCountDown`
 * + база `setWhen(endsAt)`). Сервис больше не вызывает `notify()` каждую
 * секунду, поэтому текстовый блок не перерисовывается и не мерцает.
 *
 * Ветка экспериментальная: сервис запускается только кнопкой «Тест Капли»
 * в настройках.
 */
class CapsuleTestService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var endsAt: Long = 0L

    /** Единственная отложенная задача: остановить сервис в конце отсчёта. */
    private val finish = Runnable { stopSelf() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        val now = System.currentTimeMillis()
        if (endsAt <= now) {
            endsAt = now + DURATION_MILLIS
        }

        // Одна публикация: дальше уведомление живёт само, время анимирует
        // система. Повторный notify() здесь не нужен и вреден.
        startInForeground()

        handler.removeCallbacks(finish)
        handler.postDelayed(finish, (endsAt - now).coerceAtLeast(0L))
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(finish)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    private fun startInForeground() {
        val notification = buildNotification()
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

    private fun buildNotification(): Notification {
        ensureChannel(notificationManager())

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(R.drawable.ic_capsule_test)
            .setContentTitle(getString(R.string.capsule_title))
            .setContentText(getString(R.string.capsule_until, endTime()))
            .setSubText(getString(R.string.capsule_subtitle))
            .setColor(ACCENT)
            // Без colorized система не считает уведомление кандидатом
            // в каплю: hasPromotableCharacteristics() требует
            // isColorizedRequested() && isOngoingEvent() && hasTitle().
            .setColorized(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setAutoCancel(false)
            .setCategory(Notification.CATEGORY_PROGRESS)
            .setShowWhen(true)
            // База Chronometer — время окончания, а не старта.
            .setWhen(endsAt)
            .setUsesChronometer(true)
            .setContentIntent(contentIntent())
            .addExtras(promotionExtras())
            .addAction(stopAction())

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // Обратный отсчёт: системный Chronometer сам плавно
            // уменьшает секунды без участия приложения.
            builder.setChronometerCountDown(true)
        }

        if (Build.VERSION.SDK_INT >= 36) {
            progressStyle()?.let { style -> builder.setStyle(style) }
            // Статичный короткий текст капсулы: время окончания.
            builder.setShortCriticalText(endTime())
        }

        return builder.build()
    }

    /**
     * Полоса прогресса анимируется системой (indeterminate), поэтому
     * приложению не нужно присылать обновления ради её движения.
     * Стиль при этом остаётся `ProgressStyle` — он входит в
     * `hasPromotableStyle()`.
     */
    private fun progressStyle(): Notification.ProgressStyle? {
        if (Build.VERSION.SDK_INT < 36) return null
        return try {
            Notification.ProgressStyle()
                .setStyledByProgress(false)
                .setProgressIndeterminate(true)
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
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
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

    /** Время окончания в локальном формате «HH:mm». */
    private fun endTime(): String {
        return SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(endsAt))
    }

    companion object {
        const val ACTION_STOP =
            "com.schooldiary.school_diary.CAPSULE_TEST_STOP"

        private const val CHANNEL_ID = "hash_capsule_test"
        private const val NOTIFICATION_ID = 7413
        private const val CONTENT_REQUEST = 7414
        private const val STOP_REQUEST = 7415

        private const val DURATION_MILLIS = 10 * 60 * 1_000L

        private const val EXTRA_REQUEST_PROMOTED_ONGOING =
            "android.requestPromotedOngoing"

        private val ACCENT = Color.parseColor("#5B5BD6")
    }
}
