package com.schooldiary.school_diary

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import org.json.JSONObject
import java.util.Calendar

/**
 * Общий слой данных нативного виджета.
 *
 * Провайдер и [ScheduleWidgetService] читают один и тот же снимок, поэтому
 * заголовок, пустое состояние и строки списка не расходятся. Любая ошибка
 * разбора или построения строк превращается в безопасное «Нет данных»
 * вместо падения виджета.
 */
object ScheduleWidgetData {

    const val PREFERENCES = "HomeWidgetPreferences"
    const val DATA_KEY = "schedule_data"

    data class Lesson(
        val subject: String,
        val start: Int,
        val end: Int,
        val startText: String,
        val endText: String,
        val room: String?,
        val number: Int?,
    )

    data class Payload(
        val lessonsByDay: Map<Int, List<Lesson>>,
        val showRooms: Boolean,
        val saturdayOff: Boolean,
        val dark: Boolean,
        val english: Boolean,
        val simulatedMinutes: Int?,
        val simulatedWeekday: Int?,
    )

    enum class RowStyle { PAST, CURRENT, NEXT, NORMAL, BREAK }

    data class Row(
        val text: String,
        val time: String?,
        val style: RowStyle,
        val number: Int?,
    )

    /** Готовый к отрисовке снимок: шапка, пустое состояние и строки. */
    data class Snapshot(
        val title: String,
        val emptyText: String,
        val dark: Boolean,
        val rows: List<Row>,
    )

    // ---------------------------------------------------------------------
    // Снимок
    // ---------------------------------------------------------------------

    fun snapshot(context: Context): Snapshot {
        return try {
            buildSnapshot(context)
        } catch (_: Throwable) {
            Snapshot(
                title = context.getString(R.string.widget_title),
                emptyText = context.getString(R.string.widget_not_loaded),
                dark = systemDark(context),
                rows = emptyList(),
            )
        }
    }

    private fun buildSnapshot(context: Context): Snapshot {
        val payload = readPayload(context)
        val dark = payload?.dark ?: systemDark(context)
        val labels = Labels(payload?.english ?: false)

        if (payload == null) {
            return Snapshot(
                title = context.getString(R.string.widget_title),
                emptyText = context.getString(R.string.widget_not_loaded),
                dark = dark,
                rows = emptyList(),
            )
        }

        // Пустая база или сброшенное расписание: ни одного урока нет ни в
        // одном дне. Показываем статичное состояние вместо пустого списка.
        val hasAnyLessons = payload.lessonsByDay.values.any { it.isNotEmpty() }
        if (!hasAnyLessons) {
            return Snapshot(
                title = context.getString(R.string.widget_title),
                emptyText = context.getString(R.string.widget_not_loaded),
                dark = dark,
                rows = emptyList(),
            )
        }

        val calendar = Calendar.getInstance()
        // Отладочная симуляция дня важнее системного дня недели.
        val day = payload.simulatedWeekday ?: dartDayOf(calendar)
        val systemMinutes = calendar.get(Calendar.HOUR_OF_DAY) * 60 +
            calendar.get(Calendar.MINUTE)
        // Отладочная симуляция времени важнее системных часов.
        val nowMinutes = payload.simulatedMinutes ?: systemMinutes
        val dayOff = day == 7 || (payload.saturdayOff && day == 6)
        val lessons = if (dayOff) {
            emptyList()
        } else {
            payload.lessonsByDay[day] ?: emptyList()
        }

        val title = "${labels.today} · ${labels.dayName(day)}"

        if (lessons.isEmpty()) {
            return Snapshot(
                title = title,
                emptyText = if (dayOff) labels.dayOff else labels.noLessons,
                dark = dark,
                rows = emptyList(),
            )
        }

        return Snapshot(
            title = title,
            emptyText = "",
            dark = dark,
            rows = buildLessonRows(lessons, nowMinutes, payload.showRooms, labels),
        )
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
                rows.add(Row("", null, RowStyle.BREAK, null))
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
                    lesson.number,
                ),
            )
        }

        return rows
    }

    // ---------------------------------------------------------------------
    // Чтение payload из Flutter
    // ---------------------------------------------------------------------

    fun readPayload(context: Context): Payload? {
        return try {
            val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            // Жёсткая проверка типа и пустоты: после сброса расписания или
            // первого запуска ключа может не быть вовсе.
            val raw = prefs.all[DATA_KEY] as? String
            if (raw.isNullOrBlank()) return null
            val root = JSONObject(raw)
            val daysJson = root.optJSONObject("days") ?: return null
            val placeholderSubject = Labels(
                root.optBoolean("english", false),
            ).placeholderSubject
            val byDay = HashMap<Int, List<Lesson>>()
            for (day in 1..7) {
                val array = daysJson.optJSONArray(day.toString()) ?: continue
                val lessons = ArrayList<Lesson>(array.length())
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val startText = stringOrNull(item.opt("start")) ?: "08:00"
                    val endText = stringOrNull(item.opt("end")) ?: "08:40"
                    // «number» может прийти как null, строкой, пустой строкой
                    // или отсутствовать — уроки вроде РОВ остаются без номера.
                    val number = parseNumberOrNull(item.opt("number"))
                    val room = stringOrNull(item.opt("room"))
                    val subject = stringOrNull(item.opt("subject"))
                        ?: placeholderSubject
                    lessons.add(
                        Lesson(
                            subject = subject,
                            start = minutesOf(startText),
                            end = minutesOf(endText),
                            startText = startText,
                            endText = endText,
                            room = room,
                            number = number,
                        ),
                    )
                }
                lessons.sortBy { it.start }
                byDay[day] = lessons
            }
            Payload(
                lessonsByDay = byDay,
                showRooms = root.optBoolean("showRooms", true),
                saturdayOff = root.optBoolean("saturdayOff", false),
                dark = root.optBoolean("dark", false),
                english = root.optBoolean("english", false),
                simulatedMinutes = parseTimeOrNull(
                    root.optString("simulatedTime", ""),
                ),
                simulatedWeekday = root.optInt("simulatedWeekday", 0)
                    .takeIf { it in 1..7 },
            )
        } catch (_: Throwable) {
            null
        }
    }

    // ---------------------------------------------------------------------
    // Обновления по расписанию
    // ---------------------------------------------------------------------

    fun nextBoundary(payload: Payload): Long? {
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

    // ---------------------------------------------------------------------
    // Палитра
    // ---------------------------------------------------------------------

    fun primary(dark: Boolean): Int =
        if (dark) DARK_TEXT else LIGHT_TEXT

    fun muted(dark: Boolean): Int =
        if (dark) DARK_MUTED else LIGHT_MUTED

    /** Цвет текста на контрастной плашке текущего урока. */
    fun onAccent(dark: Boolean): Int =
        if (dark) Color.BLACK else Color.WHITE

    /** Фон строки: у обычных уроков его нет, у текущего и следующего — есть. */
    fun rowBackground(style: RowStyle, dark: Boolean): Int = when (style) {
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

        RowStyle.PAST, RowStyle.NORMAL -> R.drawable.widget_row_transparent
    }

    fun nameColor(style: RowStyle, dark: Boolean): Int {
        val primary = primary(dark)
        return when (style) {
            RowStyle.CURRENT -> onAccent(dark)
            RowStyle.PAST -> withAlpha(primary, 0.45f)
            RowStyle.BREAK -> muted(dark)
            else -> primary
        }
    }

    fun timeColor(style: RowStyle, dark: Boolean): Int {
        val muted = muted(dark)
        return when (style) {
            RowStyle.CURRENT -> onAccent(dark)
            RowStyle.PAST -> withAlpha(muted, 0.45f)
            else -> muted
        }
    }

    fun stripeColor(style: RowStyle, dark: Boolean): Int {
        val primary = primary(dark)
        return when (style) {
            RowStyle.CURRENT -> onAccent(dark)
            RowStyle.PAST -> withAlpha(primary, 0.18f)
            RowStyle.NEXT -> primary
            else -> withAlpha(primary, 0.38f)
        }
    }

    // ---------------------------------------------------------------------
    // Помощники
    // ---------------------------------------------------------------------

    fun systemDark(context: Context): Boolean {
        val mode = context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK
        return mode == Configuration.UI_MODE_NIGHT_YES
    }

    fun dartDayOf(calendar: Calendar): Int {
        val day = calendar.get(Calendar.DAY_OF_WEEK)
        return if (day == Calendar.SUNDAY) 7 else day - 1
    }

    /// «HH:mm» → минуты от полуночи, либо null для пустой/битой строки.
    private fun parseTimeOrNull(value: String): Int? {
        val trimmed = value.trim()
        if (trimmed.isEmpty() || !trimmed.contains(":")) return null
        val parts = trimmed.split(":")
        val hours = parts.getOrNull(0)?.trim()?.toIntOrNull() ?: return null
        val minutes = parts.getOrNull(1)?.trim()?.toIntOrNull() ?: return null
        if (hours !in 0..23 || minutes !in 0..59) return null
        return hours * 60 + minutes
    }

    /** JSON-значение → непустая строка либо null (включая `JSONObject.NULL`). */
    private fun stringOrNull(value: Any?): String? {
        if (value == null || value == JSONObject.NULL) return null
        return value.toString().trim().takeIf { it.isNotEmpty() }
    }

    /** Номер урока: null, пустая строка, 0 и отрицательные → null. */
    private fun parseNumberOrNull(value: Any?): Int? {
        if (value == null || value == JSONObject.NULL) return null
        val number = when (value) {
            is Number -> value.toInt()
            is String -> value.trim().toIntOrNull()
            else -> value.toString().trim().toIntOrNull()
        } ?: return null
        return number.takeIf { it > 0 }
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

    /** Подписи, зависящие от выбранного в приложении языка. */
    class Labels(private val english: Boolean) {
        val today: String get() = if (english) "Today" else "Сегодня"
        val dayOff: String get() = if (english) "Day off" else "Выходной"
        val noLessons: String
            get() = if (english) "No lessons today" else "Сегодня уроков нет"
        val placeholderSubject: String
            get() = if (english) "Lesson" else "Предмет"

        fun dayName(day: Int): String {
            val index = (day - 1).coerceIn(0, 6)
            return if (english) DAYS_EN[index] else DAYS_RU[index]
        }

        fun interval(start: String, end: String): String = "$start–$end"

        fun lessonName(subject: String, room: String?, showRooms: Boolean): String {
            if (!showRooms || room.isNullOrBlank()) return subject
            return if (english) "$subject · rm $room" else "$subject · каб. $room"
        }
    }

    private val LIGHT_TEXT = Color.parseColor("#18181B")
    private val LIGHT_MUTED = Color.parseColor("#71717A")
    private val DARK_TEXT = Color.parseColor("#FAFAFA")
    private val DARK_MUTED = Color.parseColor("#A1A1AA")

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
