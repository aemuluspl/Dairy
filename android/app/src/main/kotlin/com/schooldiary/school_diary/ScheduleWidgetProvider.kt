package com.schooldiary.school_diary

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews

/**
 * Нативный виджет расписания Hash.
 *
 * Данные приходят из Flutter через `home_widget` в SharedPreferences
 * `HomeWidgetPreferences` под ключом `schedule_data` (JSON). Шапка и пустое
 * состояние рисуются здесь, а уроки — через [ScheduleWidgetService]
 * (`ListView`), поэтому длинное расписание прокручивается, а не обрезается.
 * Провайдер перерисовывается по AlarmManager на границах уроков и в полночь.
 *
 * Любая ошибка построения RemoteViews не должна ронять процесс лаунчера:
 * все ветки заканчиваются безопасным fallback-состоянием.
 */
class ScheduleWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            updateSafely(context, appWidgetManager, id)
        }
        notifySafely(context, appWidgetIds)
        scheduleNextUpdate(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        super.onAppWidgetOptionsChanged(
            context,
            appWidgetManager,
            appWidgetId,
            newOptions,
        )
        updateSafely(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_REFRESH,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
            -> {
                refreshAll(context)
                scheduleNextUpdate(context)
            }
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val manager = AppWidgetManager.getInstance(context)
        val remaining = manager.getAppWidgetIds(
            ComponentName(context, ScheduleWidgetProvider::class.java),
        )
        if (remaining.isEmpty()) cancelUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelUpdate(context)
    }

    private fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, ScheduleWidgetProvider::class.java),
        )
        if (ids.isEmpty()) return
        ids.forEach { id ->
            updateSafely(context, manager, id)
        }
        notifySafely(context, ids)
    }

    /** Обновление списка не должно ронять процесс лаунчера. */
    private fun notifySafely(context: Context, ids: IntArray) {
        try {
            AppWidgetManager.getInstance(context)
                .notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
        } catch (_: Throwable) {
            // Список мог ещё не подключиться — шапка уже отрисована.
        }
    }

    // ---------------------------------------------------------------------
    // Отрисовка
    // ---------------------------------------------------------------------

    private fun updateSafely(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ) {
        val views = try {
            buildViews(context, widgetId)
        } catch (_: Throwable) {
            fallbackViews(context)
        } ?: return
        try {
            manager.updateAppWidget(widgetId, views)
        } catch (_: Throwable) {
            // Лаунчер мог удалить виджет между выборкой и обновлением.
        }
    }

    private fun buildViews(context: Context, widgetId: Int): RemoteViews {
        val snapshot = ScheduleWidgetData.snapshot(context)
        val primary = ScheduleWidgetData.primary(snapshot.dark)
        val muted = ScheduleWidgetData.muted(snapshot.dark)

        val views = RemoteViews(context.packageName, R.layout.schedule_widget)
        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (snapshot.dark) {
                R.drawable.widget_background_dark
            } else {
                R.drawable.widget_background_light
            },
        )
        views.setTextViewText(R.id.widget_day, snapshot.title)
        views.setTextColor(R.id.widget_day, primary)
        views.setTextViewText(R.id.widget_note, "")
        views.setTextColor(R.id.widget_note, muted)

        views.setTextViewText(R.id.widget_empty, snapshot.emptyText)
        views.setTextColor(R.id.widget_empty, muted)

        val hasRows = snapshot.rows.isNotEmpty()
        views.setViewVisibility(
            R.id.widget_list,
            if (hasRows) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.widget_empty,
            if (hasRows) View.GONE else View.VISIBLE,
        )

        if (hasRows) {
            val adapterIntent = Intent(context, ScheduleWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                // Уникальные данные на каждый экземпляр: иначе система
                // переиспользует один и тот же Intent и фабрику.
                data = Uri.parse("hash://schedule-widget/$widgetId")
            }
            views.setRemoteAdapter(R.id.widget_list, adapterIntent)
            views.setEmptyView(R.id.widget_list, R.id.widget_empty)
            views.setPendingIntentTemplate(
                R.id.widget_list,
                launchIntent(context, templateFlags()),
            )
        }

        attachClick(context, views)
        return views
    }

    /** Минимальный безопасный виджет: шапка и «Расписание не загружено». */
    private fun fallbackViews(context: Context): RemoteViews? {
        return try {
            val views = RemoteViews(context.packageName, R.layout.schedule_widget)
            val dark = ScheduleWidgetData.systemDark(context)
            views.setInt(
                R.id.widget_root,
                "setBackgroundResource",
                if (dark) {
                    R.drawable.widget_background_dark
                } else {
                    R.drawable.widget_background_light
                },
            )
            views.setTextViewText(
                R.id.widget_day,
                context.getString(R.string.widget_title),
            )
            views.setTextViewText(R.id.widget_note, "")
            views.setTextViewText(
                R.id.widget_empty,
                context.getString(R.string.widget_not_loaded),
            )
            views.setTextColor(
                R.id.widget_empty,
                ScheduleWidgetData.muted(dark),
            )
            views.setViewVisibility(R.id.widget_list, View.GONE)
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            attachClick(context, views)
            views
        } catch (_: Throwable) {
            null
        }
    }

    private fun attachClick(context: Context, views: RemoteViews) {
        try {
            views.setOnClickPendingIntent(
                R.id.widget_root,
                launchIntent(context, pendingFlags()),
            )
        } catch (_: Throwable) {
            // Клик не критичен для отрисовки.
        }
    }

    private fun launchIntent(context: Context, flags: Int): PendingIntent {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, CLICK_REQUEST, launch, flags)
    }

    // ---------------------------------------------------------------------
    // Обновления по расписанию
    // ---------------------------------------------------------------------

    private fun scheduleNextUpdate(context: Context) {
        try {
            val payload = ScheduleWidgetData.readPayload(context)
            if (payload == null || payload.simulatedMinutes != null ||
                payload.simulatedWeekday != null
            ) {
                cancelUpdate(context)
                return
            }
            val trigger = ScheduleWidgetData.nextBoundary(payload) ?: return
            val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pending = refreshIntent(context)
            manager.cancel(pending)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                !manager.canScheduleExactAlarms()
            ) {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
            } else {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
            }
        } catch (_: SecurityException) {
            // Нет разрешения на точные будильники — виджет обновится при
            // следующем открытии приложения или по системному времени.
        } catch (_: Throwable) {
            // Планирование не должно ломать обновление виджета.
        }
    }

    private fun refreshIntent(context: Context): PendingIntent {
        val intent = Intent(context, ScheduleWidgetProvider::class.java)
            .setAction(ACTION_REFRESH)
        return PendingIntent.getBroadcast(
            context,
            REFRESH_REQUEST,
            intent,
            pendingFlags(),
        )
    }

    private fun cancelUpdate(context: Context) {
        try {
            val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            manager.cancel(refreshIntent(context))
        } catch (_: Throwable) {
            // Нечего отменять.
        }
    }

    private fun pendingFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }

    /**
     * Шаблон клика по строке списка: конкретную строку система дополняет
     * fill-in intent'ом, поэтому PendingIntent должен быть изменяемым.
     */
    private fun templateFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }

    companion object {
        private const val ACTION_REFRESH =
            "com.schooldiary.school_diary.SCHEDULE_WIDGET_REFRESH"
        private const val REFRESH_REQUEST = 7411
        private const val CLICK_REQUEST = 7412
    }
}
