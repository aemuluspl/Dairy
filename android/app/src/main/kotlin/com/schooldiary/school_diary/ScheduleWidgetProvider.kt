package com.schooldiary.school_diary

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.util.Calendar

/**
 * Нативный виджет расписания Hash.
 *
 * Данные приходят из Flutter через `home_widget` в SharedPreferences
 * `HomeWidgetPreferences` под ключом `schedule_data` (JSON). Провайдер
 * рисует текущий день, скрывает прошедшие уроки через прозрачность и
 * перерисовывается по AlarmManager на границах уроков и в полночь.
 */
class ScheduleWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(
                id,
                buildViews(context, appWidgetManager, id),
            )
        }
        scheduleNextUpdate(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        appWidgetManager.updateAppWidget(
            appWidgetId,
            buildViews(context, appWidgetManager, appWidgetId),
        )
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
        ids.forEach { id ->
            manager.updateAppWidget(id, buildViews(context, manager, id))
        }
    }

    // ---------------------------------------------------------------------
    // Отрисовка
    // ---------------------------------------------------------------------

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.schedule_widget)
        val payload = readPayload(context)
        val labels = Labels(payload?.english ?: false)
        val dark = payload?.dark ?: false

        val primary = if (dark) DARK_TEXT else LIGHT_TEXT
        val muted = if (dark) DARK_MUTED else LIGHT_MUTED
        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (dark) R.drawable.widget_background_dark else R.drawable.widget_background_light,
        )
        views.setTextColor(R.id.widget_day, primary)
        views.setTextColor(R.id.widget_note, muted)

        if (payload == null) {
            views.setTextViewText(R.id.widget_day, labels.widgetTitle)
            views.setTextViewText(R.id.widget_note, "")
            showRows(
                views = views,
                rows = listOf(Row(labels.emptyState, null, RowStyle.MESSAGE)),
                capacity = 1,
                dark = dark,
                primary = primary,
                muted = muted,
            )
            attachClick(context, views)
            return views
        }

        val calendar = Calendar.getInstance()
        val day = dartDayOf(calendar)
        val nowMinutes = calendar.get(Calendar.HOUR_OF_DAY) * 60 +
            calendar.get(Calendar.MINUTE)
        val dayOff = day == 7 || (payload.saturdayOff && day == 6)
        val lessons = if (dayOff) {
            emptyList()
        } else {
            payload.lessonsByDay[day] ?: emptyList()
        }

        views.setTextViewText(
            R.id.widget_day,
            "${labels.today} · ${labels.dayName(day)}",
        )

        val rows = if (lessons.isEmpty()) {
            listOf(
                Row(
                    if (dayOff) labels.dayOff else labels.noLessons,
                    null,
                    RowStyle.MESSAGE,
                ),
            )
        } else {
            buildLessonRows(lessons, nowMinutes, payload.showRooms, labels)
        }

        val capacity = capacityFor(manager, widgetId)
        val visible = visibleRows(rows, capacity)
        val note = if (rows.size > visible.size) {
            "+${rows.size - visible.size}"
        } else {
            ""
        }
        views.setTextViewText(R.id.widget_note, note)

        showRows(
            views = views,
            rows = visible,
            capacity = capacity,
            dark = dark,
            primary = primary,
            muted = muted,
        )
        attachClick(context, views)
        return views
    }

    private fun buildLessonRows(
        lessons: List<Lesson>,
        nowMinutes: Int,
        showRooms: Boolean,
        labels: Labels,
    ): List<Row> {
        val rows = ArrayList<Row>(lessons.size + 1)
        var markedNext = false

        lessons.forEachIndexed { index, lesson ->
            // Узкая полоска перемены — только если перемена идёт прямо сейчас.
            if (index > 0 &&
                nowMinutes >= lessons[index - 1].end &&
                nowMinutes < lesson.start
            ) {
                rows.add(
                    Row(
                        labels.breakUntil(lesson.startText),
                        null,
                        RowStyle.BREAK,
                    ),
                )
            }

            val style = when {
                nowMinutes >= lesson.end -> RowStyle.PAST
                nowMinutes >= lesson.start -> RowStyle.CURRENT
                !markedNext -> {
                    markedNext = true
                    RowStyle.NEXT
                }
                else -> RowStyle.NORMAL
            }

            rows.add(
                Row(
                    labels.lessonName(lesson.subject, lesson.room, showRooms),
                    labels.interval(lesson.startText, lesson.endText),
                    style,
                ),
            )
        }

        return rows
    }

    /// Окно строк, которое влезает в виджет.
    ///
    /// В середине дня показываем текущий урок и один прошедший перед ним,
    /// а не первые строки расписания: иначе на 4×2 «сейчас» уезжало бы
    /// за пределы виджета.
    private fun visibleRows(rows: List<Row>, capacity: Int): List<Row> {
        val size = capacity.coerceAtMost(rows.size)
        if (rows.size <= size) return rows

        var anchor = rows.indexOfFirst { it.style == RowStyle.CURRENT }
        if (anchor < 0) anchor = rows.indexOfFirst { it.style == RowStyle.NEXT }
        if (anchor < 0) return rows.takeLast(size)

        val start = (anchor - 1).coerceIn(0, rows.size - size)
        return rows.subList(start, start + size)
    }

    private fun showRows(
        views: RemoteViews,
        rows: List<Row>,
        capacity: Int,
        dark: Boolean,
        primary: Int,
        muted: Int,
    ) {
        val visible = rows.take(capacity)
        visible.forEachIndexed { index, row ->
            applyRow(views, index, row, dark, primary, muted)
        }
        for (index in visible.size until ROW_COUNT) {
            views.setViewVisibility(ROW_IDS[index], View.GONE)
        }
    }

    private fun applyRow(
        views: RemoteViews,
        index: Int,
        row: Row,
        dark: Boolean,
        primary: Int,
        muted: Int,
    ) {
        val rowId = ROW_IDS[index]
        val nameId = ROW_NAME_IDS[index]
        val timeId = ROW_TIME_IDS[index]

        views.setViewVisibility(rowId, View.VISIBLE)
        views.setTextViewTextSize(
            nameId,
            android.util.TypedValue.COMPLEX_UNIT_SP,
            if (row.style == RowStyle.BREAK) 10f else 12f,
        )

        val background = when (row.style) {
            RowStyle.CURRENT -> if (dark) {
                R.drawable.widget_row_current_dark
            } else {
                R.drawable.widget_row_current_light
            }
            RowStyle.NEXT -> if (dark) {
                R.drawable.widget_row_next_dark
            } else {
                R.drawable.widget_row_next_light
            }
            RowStyle.BREAK -> if (dark) {
                R.drawable.widget_row_break_dark
            } else {
                R.drawable.widget_row_break_light
            }
            RowStyle.PAST, RowStyle.NORMAL, RowStyle.MESSAGE ->
                android.R.color.transparent
        }
        views.setInt(rowId, "setBackgroundResource", background)

        val nameColor = when (row.style) {
            RowStyle.CURRENT -> if (dark) DARK_ON_ACCENT else LIGHT_ON_ACCENT
            RowStyle.PAST -> withAlpha(primary, 0.45f)
            RowStyle.BREAK -> muted
            else -> primary
        }
        val timeColor = when (row.style) {
            RowStyle.CURRENT -> if (dark) DARK_ON_ACCENT else LIGHT_ON_ACCENT
            RowStyle.PAST -> withAlpha(muted, 0.45f)
            else -> muted
        }

        views.setTextViewText(nameId, row.text)
        views.setTextColor(nameId, nameColor)

        if (row.time == null) {
            views.setViewVisibility(timeId, View.GONE)
        } else {
            views.setViewVisibility(timeId, View.VISIBLE)
            views.setTextViewText(timeId, row.time)
            views.setTextColor(timeId, timeColor)
        }
    }

    private fun attachClick(context: Context, views: RemoteViews) {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(context, CLICK_REQUEST, launch, pendingFlags()),
            )
        }
    }

    private fun capacityFor(manager: AppWidgetManager, widgetId: Int): Int {
        val options = manager.getAppWidgetOptions(widgetId)
        val minHeightDp = options.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,
            0,
        )
        if (minHeightDp <= 0) return 4
        // Заголовок и отступы занимают около 40dp, строка — 26dp.
        return ((minHeightDp - 40) / 26).coerceIn(1, ROW_COUNT)
    }

    // ---------------------------------------------------------------------
    // Данные
    // ---------------------------------------------------------------------

    private fun readPayload(context: Context): Payload? {
        val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val raw = prefs.getString(DATA_KEY, null) ?: return null
        return try {
            val root = JSONObject(raw)
            val daysJson = root.optJSONObject("days")
            val byDay = HashMap<Int, List<Lesson>>()
            if (daysJson != null) {
                for (day in 1..7) {
                    val array = daysJson.optJSONArray(day.toString()) ?: continue
                    val lessons = ArrayList<Lesson>(array.length())
                    for (index in 0 until array.length()) {
                        val item = array.optJSONObject(index) ?: continue
                        val startText = item.optString("start", "08:00")
                        val endText = item.optString("end", "08:40")
                        val roomRaw = item.opt("room")
                        val room = if (roomRaw == null || roomRaw == JSONObject.NULL) {
                            null
                        } else {
                            roomRaw.toString().trim().takeIf { it.isNotEmpty() }
                        }
                        lessons.add(
                            Lesson(
                                subject = item.optString("subject", "").trim(),
                                start = minutesOf(startText),
                                end = minutesOf(endText),
                                startText = startText,
                                endText = endText,
                                room = room,
                            ),
                        )
                    }
                    lessons.sortBy { it.start }
                    byDay[day] = lessons
                }
            }
            Payload(
                lessonsByDay = byDay,
                showRooms = root.optBoolean("showRooms", true),
                saturdayOff = root.optBoolean("saturdayOff", false),
                dark = root.optBoolean("dark", false),
                english = root.optBoolean("english", false),
            )
        } catch (_: Exception) {
            null
        }
    }

    // ---------------------------------------------------------------------
    // Обновления по расписанию
    // ---------------------------------------------------------------------

    private fun scheduleNextUpdate(context: Context) {
        val payload = readPayload(context)
        if (payload == null) {
            cancelUpdate(context)
            return
        }
        val trigger = nextBoundary(payload) ?: return
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = refreshIntent(context)
        manager.cancel(pending)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                !manager.canScheduleExactAlarms()
            ) {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
            } else {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
            }
        } catch (_: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
        }
    }

    private fun nextBoundary(payload: Payload): Long? {
        val now = System.currentTimeMillis()
        var best: Long? = null

        fun consider(time: Long) {
            if (time <= now + 1_500) return
            val current = best
            if (current == null || time < current) best = time
        }

        for (offset in 0..7) {
            val base = Calendar.getInstance()
            base.timeInMillis = now
            base.add(Calendar.DAY_OF_MONTH, offset)

            // Полночь следующего дня: виджет переключается на новый день.
            if (offset > 0) {
                val midnight = Calendar.getInstance()
                midnight.timeInMillis = base.timeInMillis
                midnight.set(Calendar.HOUR_OF_DAY, 0)
                midnight.set(Calendar.MINUTE, 0)
                midnight.set(Calendar.SECOND, 2)
                midnight.set(Calendar.MILLISECOND, 0)
                consider(midnight.timeInMillis)
            }

            val day = dartDayOf(base)
            if (day == 7 || (payload.saturdayOff && day == 6)) continue
            val lessons = payload.lessonsByDay[day] ?: continue

            for (lesson in lessons) {
                for (minutes in intArrayOf(lesson.start, lesson.end)) {
                    val boundary = Calendar.getInstance()
                    boundary.timeInMillis = base.timeInMillis
                    boundary.set(Calendar.HOUR_OF_DAY, minutes / 60)
                    boundary.set(Calendar.MINUTE, minutes % 60)
                    boundary.set(Calendar.SECOND, 0)
                    boundary.set(Calendar.MILLISECOND, 0)
                    consider(boundary.timeInMillis)
                }
            }
        }

        return best
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
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.cancel(refreshIntent(context))
    }

    private fun pendingFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }

    // ---------------------------------------------------------------------
    // Мелкие помощники
    // ---------------------------------------------------------------------

    private fun dartDayOf(calendar: Calendar): Int {
        val day = calendar.get(Calendar.DAY_OF_WEEK)
        return if (day == Calendar.SUNDAY) 7 else day - 1
    }

    private fun minutesOf(value: String): Int {
        val parts = value.split(":")
        val hours = parts.getOrNull(0)?.trim()?.toIntOrNull() ?: 8
        val minutes = parts.getOrNull(1)?.trim()?.toIntOrNull() ?: 0
        return (hours * 60 + minutes).coerceIn(0, 24 * 60)
    }

    private fun withAlpha(color: Int, factor: Float): Int {
        val alpha = (0xFF * factor).toInt().coerceIn(0, 0xFF)
        return Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))
    }

    private data class Lesson(
        val subject: String,
        val start: Int,
        val end: Int,
        val startText: String,
        val endText: String,
        val room: String?,
    )

    private data class Payload(
        val lessonsByDay: Map<Int, List<Lesson>>,
        val showRooms: Boolean,
        val saturdayOff: Boolean,
        val dark: Boolean,
        val english: Boolean,
    )

    private data class Row(
        val text: String,
        val time: String?,
        val style: RowStyle,
    )

    private enum class RowStyle {
        PAST,
        CURRENT,
        NEXT,
        NORMAL,
        BREAK,
        MESSAGE,
    }

    private class Labels(private val english: Boolean) {
        val widgetTitle: String
            get() = if (english) "Hash · Schedule" else "Hash · Расписание"
        val today: String
            get() = if (english) "Today" else "Сегодня"
        val dayOff: String
            get() = if (english) "Day off" else "Выходной"
        val noLessons: String
            get() = if (english) "No lessons today" else "Сегодня уроков нет"
        val emptyState: String
            get() = if (english) {
                "Add a schedule in Hash"
            } else {
                "Добавь расписание в Hash"
            }

        fun dayName(day: Int): String {
            val index = (day - 1).coerceIn(0, 6)
            return if (english) DAYS_EN[index] else DAYS_RU[index]
        }

        fun breakUntil(start: String): String =
            if (english) "Break · until $start" else "Перемена · до $start"

        fun interval(start: String, end: String): String = "$start–$end"

        fun lessonName(subject: String, room: String?, showRooms: Boolean): String {
            if (!showRooms || room.isNullOrBlank()) return subject
            return if (english) "$subject · rm $room" else "$subject · каб. $room"
        }
    }

    companion object {
        private const val PREFERENCES = "HomeWidgetPreferences"
        private const val DATA_KEY = "schedule_data"
        private const val ACTION_REFRESH =
            "com.schooldiary.school_diary.SCHEDULE_WIDGET_REFRESH"
        private const val REFRESH_REQUEST = 7411
        private const val CLICK_REQUEST = 7412
        private const val ROW_COUNT = 8

        private val ROW_IDS = intArrayOf(
            R.id.row_0,
            R.id.row_1,
            R.id.row_2,
            R.id.row_3,
            R.id.row_4,
            R.id.row_5,
            R.id.row_6,
            R.id.row_7,
        )
        private val ROW_NAME_IDS = intArrayOf(
            R.id.row_0_name,
            R.id.row_1_name,
            R.id.row_2_name,
            R.id.row_3_name,
            R.id.row_4_name,
            R.id.row_5_name,
            R.id.row_6_name,
            R.id.row_7_name,
        )
        private val ROW_TIME_IDS = intArrayOf(
            R.id.row_0_time,
            R.id.row_1_time,
            R.id.row_2_time,
            R.id.row_3_time,
            R.id.row_4_time,
            R.id.row_5_time,
            R.id.row_6_time,
            R.id.row_7_time,
        )

        private val LIGHT_TEXT = Color.parseColor("#18181B")
        private val LIGHT_MUTED = Color.parseColor("#71717A")
        private val LIGHT_ON_ACCENT = Color.parseColor("#FFFFFF")
        private val DARK_TEXT = Color.parseColor("#FAFAFA")
        private val DARK_MUTED = Color.parseColor("#A1A1AA")
        private val DARK_ON_ACCENT = Color.parseColor("#09090B")

        private val DAYS_RU = arrayOf(
            "Понедельник",
            "Вторник",
            "Среда",
            "Четверг",
            "Пятница",
            "Суббота",
            "Воскресенье",
        )
        private val DAYS_EN = arrayOf(
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday",
            "Sunday",
        )
    }
}
