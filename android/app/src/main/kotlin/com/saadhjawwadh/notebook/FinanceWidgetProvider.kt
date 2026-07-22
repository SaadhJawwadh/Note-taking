package com.saadhjawwadh.notebook

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
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

        // Linear Regression Forecast
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
            views.setTextViewText(R.id.widget_forecast_trend, "")
        }

        // Top spending category with percentage share
        val breakdownJson = prefs.getString("flutter.widget_category_breakdown", "[]") ?: "[]"
        try {
            val jsonArray = JSONArray(breakdownJson)
            if (jsonArray.length() >= 1) {
                val topItem = jsonArray.getJSONObject(0)
                val catName = topItem.optString("name", "Other")
                val pct = topItem.optInt("pct", 0)
                views.setTextViewText(R.id.widget_top_category, "Top: $catName ($pct%)")
            } else {
                val legacyTop = prefs.getString("flutter.widget_top_category", "") ?: ""
                views.setTextViewText(
                    R.id.widget_top_category,
                    if (legacyTop.isNotEmpty()) "Top: $legacyTop" else ""
                )
            }
        } catch (e: Exception) {
            val legacyTop = prefs.getString("flutter.widget_top_category", "") ?: ""
            views.setTextViewText(
                R.id.widget_top_category,
                if (legacyTop.isNotEmpty()) "Top: $legacyTop" else ""
            )
        }
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
            action = "com.saadhjawwadh.notebook.VIEW_BUDGETS"
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
