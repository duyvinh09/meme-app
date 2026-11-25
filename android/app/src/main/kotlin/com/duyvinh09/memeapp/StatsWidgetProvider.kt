package com.duyvinh09.memeapp

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import org.json.JSONObject
import android.util.Log

class StatsWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in listOf(
                Intent.ACTION_DATE_CHANGED, Intent.ACTION_TIME_CHANGED,
                Intent.ACTION_TIMEZONE_CHANGED, MIDNIGHT_ACTION
            )) {
            val manager = AppWidgetManager.getInstance(context)
            onUpdate(context, manager, manager.getAppWidgetIds(
                ComponentName(context, StatsWidgetProvider::class.java)))
        }
    }

    override fun onDisabled(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.cancel(midnightIntent(context))
        super.onDisabled(context)
    }

    private fun midnightIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context, 4202,
        Intent(context, StatsWidgetProvider::class.java).setAction(MIDNIGHT_ACTION),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    private fun scheduleMidnight(context: Context) {
        val next = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 5)
            set(Calendar.MILLISECOND, 0)
        }
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // Inexact: no exact-alarm permission; periodic widget updates are a fallback.
        alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis,
            midnightIntent(context))
    }

    private fun withDailyHeader(context: Context, source: Bitmap, raw: String?): Bitmap {
        if (raw == null) return source // Existing installations retain their old bitmap.
        val payload = try {
            JSONObject(raw).takeIf { it.optInt("version") == 1 } ?: return source
        } catch (error: org.json.JSONException) {
            Log.w("StatsWidget", "Invalid cached daily header", error)
            return source
        }
        val result = source.copy(Bitmap.Config.ARGB_8888, true) ?: return source
        val canvas = Canvas(result)
        canvas.scale(result.width / 380f, result.height / 180f)
        val dark = payload.optBoolean("isDark", true)
        val en = payload.optBoolean("isEn", false)
        val now = Date()
        val key = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).format(now)
        val day = payload.optJSONObject("days")?.optJSONObject(key)
        val expense = day?.optString("expense", "") ?: ""
        val income = day?.optString("income", "") ?: ""
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = Color.parseColor(if (dark) "#18191E" else "#FFFFFF")
        canvas.drawRect(16f, 14f, 364f, 42f, paint)
        paint.typeface = Typeface.createFromAsset(context.assets,
            "flutter_assets/assets/fonts/ProximaSoft-Bold.ttf")
        paint.textSize = 11f
        paint.color = Color.parseColor(if (dark) "#9E9EA7" else "#74788A")
        val locale = if (en) Locale.US else Locale.forLanguageTag("vi-VN")
        canvas.drawText(SimpleDateFormat(if (en) "EEE, dd/MM/yyyy" else "EEEE, dd/MM/yyyy", locale).format(now),
            16f, 31f, paint)
        paint.color = Color.parseColor(if (dark) "#242632" else "#EFF2F8")
        canvas.drawRoundRect(222f, 14f, 364f, 42f, 9f, 9f, paint)
        paint.color = Color.parseColor(if (dark) "#9E9EA7" else "#74788A")
        paint.textSize = 9f
        canvas.drawText(if (en) "Today:" else "Hôm nay:", 229f, 31f, paint)
        paint.textAlign = Paint.Align.RIGHT
        paint.textSize = 10f
        if (income.isNotEmpty()) {
            paint.color = Color.parseColor(if (dark) "#4ADE80" else "#059669")
            canvas.drawText(income, 357f, if (expense.isNotEmpty()) 25f else 31f, paint)
        }
        if (expense.isNotEmpty()) {
            paint.color = Color.parseColor(if (dark) "#FF6B6B" else "#E53935")
            canvas.drawText(expense, 357f, if (income.isNotEmpty()) 38f else 31f, paint)
        }
        if (income.isEmpty() && expense.isEmpty()) {
            canvas.drawText(payload.optString("zero", "0đ"), 357f, 31f, paint)
        }
        return result
    }

    companion object {
        private const val MIDNIGHT_ACTION = "com.duyvinh09.memeapp.STATS_MIDNIGHT"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val imagePath = prefs.getString("stats_widget_image", null)
            ?: flutterPrefs.getString("flutter.stats_widget_image", null)
            ?: flutterPrefs.getString("stats_widget_image", null)

        if (appWidgetIds.isEmpty()) return
        scheduleMidnight(context)
        val bitmap = imagePath?.let { path ->
            if (File(path).exists()) BitmapFactory.decodeFile(path) else null
        }?.let { source ->
            withDailyHeader(context, source, prefs.getString("stats_daily_header_v1", null))
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.stats_widget_layout).apply {
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("memeapp://stats")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    widgetId,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                if (bitmap != null) {
                    setImageViewBitmap(R.id.widget_image, bitmap)
                    setViewVisibility(R.id.widget_image, View.VISIBLE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
