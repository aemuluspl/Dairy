package com.schooldiary.school_diary

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService

/**
 * Коллекция строк виджета. `RemoteViewsService` даёт настоящий `ListView`
 * на домашнем экране: расписание из 7+ уроков прокручивается, а не
 * обрезается по высоте виджета.
 */
class ScheduleWidgetService : RemoteViewsService() {

    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ScheduleWidgetFactory(applicationContext)
    }
}

/**
 * Фабрика строк. Каждый вызов [getViewAt] защищён от исключений: лучше
 * показать пустую строку, чем уронить виджет.
 */
class ScheduleWidgetFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {

    private var snapshot: ScheduleWidgetData.Snapshot =
        ScheduleWidgetData.snapshot(context)

    override fun onCreate() {
        reload()
    }

    override fun onDataSetChanged() {
        reload()
    }

    override fun onDestroy() {
        // Ничего не держим: данные читаются из SharedPreferences.
    }

    private fun reload() {
        snapshot = try {
            ScheduleWidgetData.snapshot(context)
        } catch (_: Throwable) {
            ScheduleWidgetData.Snapshot(
                title = context.getString(R.string.widget_title),
                emptyText = context.getString(R.string.widget_not_loaded),
                dark = ScheduleWidgetData.systemDark(context),
                rows = emptyList(),
            )
        }
    }

    override fun getCount(): Int = snapshot.rows.size

    /**
     * Каждая строка собирается внутри try/catch: любая ошибка маппинга
     * возвращает валидный RemoteViews с текстом «Error», иначе лаунчер
     * показывает системное «Couldn't add widget» на каждом элементе.
     */
    override fun getViewAt(position: Int): RemoteViews {
        return try {
            val rows = snapshot.rows
            if (position !in rows.indices) return errorViews()

            val views = RemoteViews(context.packageName, R.layout.schedule_widget_item)
            bind(views, rows[position])
            views
        } catch (e: Exception) {
            errorViews()
        }
    }

    /** Безопасная строка-заглушка для сбойного элемента списка. */
    private fun errorViews(): RemoteViews {
        return try {
            RemoteViews(context.packageName, R.layout.widget_error_item).apply {
                setTextViewText(R.id.error_text, "Error")
            }
        } catch (_: Throwable) {
            // Последний рубеж: даже простая TextView-разметка недоступна.
            RemoteViews(context.packageName, R.layout.widget_error_item)
        }
    }

    private fun bind(views: RemoteViews, row: ScheduleWidgetData.Row) {
        val dark = snapshot.dark
        val nameColor = ScheduleWidgetData.nameColor(row.style, dark)
        val timeColor = ScheduleWidgetData.timeColor(row.style, dark)
        val stripeColor = ScheduleWidgetData.stripeColor(row.style, dark)

        views.setInt(
            R.id.widget_item_root,
            "setBackgroundResource",
            ScheduleWidgetData.rowBackground(row.style, dark),
        )

        val isBreak = row.style == ScheduleWidgetData.RowStyle.BREAK
        val number = row.number

        views.setViewVisibility(
            R.id.widget_item_name,
            if (isBreak) View.GONE else View.VISIBLE,
        )
        views.setTextViewText(R.id.widget_item_name, row.text)
        views.setTextColor(R.id.widget_item_name, nameColor)

        if (isBreak || row.time == null) {
            views.setViewVisibility(R.id.widget_item_time, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_item_time, View.VISIBLE)
            views.setTextViewText(R.id.widget_item_time, row.time)
            views.setTextColor(R.id.widget_item_time, timeColor)
        }

        // number приходит из JSON как null у уроков вроде РОВ. Ширина номера
        // фиксированная, поэтому INVISIBLE сохраняет вертикаль названий.
        if (isBreak) {
            views.setViewVisibility(R.id.widget_item_number, View.GONE)
        } else if (number == null) {
            views.setViewVisibility(R.id.widget_item_number, View.INVISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_item_number, View.VISIBLE)
            views.setTextViewText(R.id.widget_item_number, number.toString())
            views.setTextColor(R.id.widget_item_number, timeColor)
        }

        // Бейдж «NEXT» / «СЛЕД» вместо прежней обводки строки.
        val badge = row.badgeText
        if (!isBreak && !badge.isNullOrBlank()) {
            views.setViewVisibility(R.id.widget_item_badge, View.VISIBLE)
            views.setTextViewText(R.id.widget_item_badge, badge)
            views.setTextColor(
                R.id.widget_item_badge,
                ScheduleWidgetData.onAccent(dark),
            )
            views.setInt(
                R.id.widget_item_badge,
                "setBackgroundResource",
                ScheduleWidgetData.badgeBackground(dark),
            )
        } else {
            views.setViewVisibility(R.id.widget_item_badge, View.GONE)
        }

        // Вертикальная черта как на экране расписания.
        if (isBreak) {
            views.setViewVisibility(R.id.widget_item_stripe, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_item_stripe, View.VISIBLE)
            views.setInt(
                R.id.widget_item_stripe,
                "setBackgroundColor",
                stripeColor,
            )
        }

        // Тап по строке открывает приложение; шаблон задаёт провайдер.
        views.setOnClickFillInIntent(R.id.widget_item_root, Intent())
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false
}
