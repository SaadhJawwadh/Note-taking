package com.saadhjawwadh.notebook

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.os.Bundle
import android.widget.RemoteViews
import org.json.JSONArray

class FinanceWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId, newOptions)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        options: Bundle? = null
    ) {
        val views = RemoteViews(context.packageName, R.layout.finance_widget_layout)

        // Populate Widget Data
        populateWidgetData(context, views)

        // Set up click intents
        setupIntents(context, views)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun populateWidgetData(context: Context, views: RemoteViews) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val spentToday = prefs.getString("flutter.widget_spent_today", "$0.00") ?: "$0.00"
        val spentMonth = prefs.getString("flutter.widget_spent_month", "$0.00") ?: "$0.00"
        val netMonth = prefs.getString("flutter.widget_net_month", "+$0.00") ?: "+$0.00"
        val netPositive = prefs.getBoolean("flutter.widget_net_positive", true)

        views.setTextViewText(R.id.widget_today_spent, spentToday)
        views.setTextViewText(R.id.widget_month_spent, spentMonth)
        views.setTextViewText(R.id.widget_month_net, netMonth)
        views.setTextColor(
            R.id.widget_month_net,
            context.getColor(if (netPositive) R.color.widget_income else R.color.widget_expense)
        )

        // Forecast & Pace Status
        val forecastAmount = prefs.getString("flutter.widget_forecast_amount", "") ?: ""
        val forecastTrend = prefs.getString("flutter.widget_forecast_trend", "") ?: ""
        val isTrendingUp = prefs.getBoolean("flutter.widget_is_trending_up", false)

        if (forecastAmount.isNotEmpty()) {
            views.setTextViewText(R.id.widget_forecast_amount, forecastAmount)
            views.setTextViewText(R.id.widget_forecast_trend, forecastTrend)
            views.setTextColor(
                R.id.widget_forecast_trend,
                context.getColor(if (isTrendingUp) R.color.widget_expense else R.color.widget_income)
            )
        } else {
            views.setTextViewText(R.id.widget_forecast_amount, spentMonth)
            views.setTextViewText(R.id.widget_forecast_trend, "On Track 🟢")
        }

        // Render Dynamic Mini Sparkline Plot
        val sparklineJson = prefs.getString("flutter.widget_sparkline_data", "[]") ?: "[]"
        val points = mutableListOf<Float>()
        try {
            val jsonArray = JSONArray(sparklineJson)
            for (i in 0 until jsonArray.length()) {
                points.add(jsonArray.getDouble(i).toFloat())
            }
        } catch (_: Exception) {}

        val sparklineBitmap = generateSparklineBitmap(context, points, isTrendingUp)
        if (sparklineBitmap != null) {
            views.setImageViewBitmap(R.id.widget_sparkline_plot, sparklineBitmap)
        }
    }

    private fun generateSparklineBitmap(
        context: Context,
        points: List<Float>,
        isAlert: Boolean
    ): Bitmap? {
        val width = 340
        val height = 120
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val paddingX = 16f
        val paddingY = 18f

        val drawPoints = if (points.size >= 2) points else listOf(100f, 120f, 110f, 140f, 130f, 150f)
        val n = drawPoints.size

        var maxVal = drawPoints.maxOrNull() ?: 1f
        var minVal = drawPoints.minOrNull() ?: 0f
        if (maxVal == minVal) {
            maxVal += 10f
            minVal = (minVal - 10f).coerceAtLeast(0f)
        }
        val range = (maxVal - minVal).coerceAtLeast(1f)

        val coords = mutableListOf<PointF>()
        val stepX = (width - 2 * paddingX) / (n - 1)
        for (i in 0 until n) {
            val x = paddingX + i * stepX
            val normY = (drawPoints[i] - minVal) / range
            val y = height - paddingY - normY * (height - 2 * paddingY)
            coords.add(PointF(x, y))
        }

        val primaryColor = context.getColor(R.color.widget_accent)
        val tertiaryColor = context.getColor(if (isAlert) R.color.widget_expense else R.color.widget_income)

        // Gradient Area Under Line
        val fillPath = Path()
        fillPath.moveTo(coords[0].x, coords[0].y)
        for (i in 0 until n - 1) {
            val p1 = coords[i]
            val p2 = coords[i + 1]
            val cx = (p1.x + p2.x) / 2f
            fillPath.cubicTo(cx, p1.y, cx, p2.y, p2.x, p2.y)
        }
        fillPath.lineTo(coords.last().x, height.toFloat())
        fillPath.lineTo(coords.first().x, height.toFloat())
        fillPath.close()

        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            shader = LinearGradient(
                0f, 0f, 0f, height.toFloat(),
                Color.argb(55, Color.red(primaryColor), Color.green(primaryColor), Color.blue(primaryColor)),
                Color.TRANSPARENT,
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(fillPath, fillPaint)

        // Solid Spine for historical points (0 until n-1)
        val solidPath = Path()
        solidPath.moveTo(coords[0].x, coords[0].y)
        val solidEndIdx = if (n >= 3) n - 2 else n - 1
        for (i in 0 until solidEndIdx) {
            val p1 = coords[i]
            val p2 = coords[i + 1]
            val cx = (p1.x + p2.x) / 2f
            solidPath.cubicTo(cx, p1.y, cx, p2.y, p2.x, p2.y)
        }

        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 6f
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
            color = primaryColor
        }
        canvas.drawPath(solidPath, strokePaint)

        // Dashed Extension to Est point (from solidEndIdx to n-1)
        if (n >= 3) {
            val dashPath = Path()
            val p1 = coords[solidEndIdx]
            val p2 = coords[n - 1]
            val cx = (p1.x + p2.x) / 2f
            dashPath.moveTo(p1.x, p1.y)
            dashPath.cubicTo(cx, p1.y, cx, p2.y, p2.x, p2.y)

            val dashPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 5.5f
                strokeCap = Paint.Cap.ROUND
                pathEffect = DashPathEffect(floatArrayOf(12f, 10f), 0f)
                color = tertiaryColor
            }
            canvas.drawPath(dashPath, dashPaint)
        }

        // Draw Historical Dots
        val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = primaryColor
        }
        val dotHolePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = Color.WHITE
        }
        for (i in 0 until (if (n >= 3) n - 1 else n)) {
            canvas.drawCircle(coords[i].x, coords[i].y, 7f, dotPaint)
            canvas.drawCircle(coords[i].x, coords[i].y, 3.5f, dotHolePaint)
        }

        // Highlighted Est Forecast End Dot
        val forecastDot = coords.last()
        val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = Color.argb(80, Color.red(tertiaryColor), Color.green(tertiaryColor), Color.blue(tertiaryColor))
        }
        val targetDotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = tertiaryColor
        }
        canvas.drawCircle(forecastDot.x, forecastDot.y, 14f, glowPaint)
        canvas.drawCircle(forecastDot.x, forecastDot.y, 8.5f, targetDotPaint)
        canvas.drawCircle(forecastDot.x, forecastDot.y, 4f, dotHolePaint)

        return bitmap
    }

    private fun setupIntents(context: Context, views: RemoteViews) {
        // Intent for clicking the "+" quick-add button
        val addIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.saadhjawwadh.notebook.ADD_TRANSACTION"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addPendingIntent = PendingIntent.getActivity(
            context,
            1,
            addIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_add_button, addPendingIntent)

        // Intent for clicking the widget body (opens MainActivity deep link to Budgets/Analytics)
        val mainIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.saadhjawwadh.notebook.VIEW_TRENDS"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val mainPendingIntent = PendingIntent.getActivity(
            context,
            2,
            mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, mainPendingIntent)
    }
}

