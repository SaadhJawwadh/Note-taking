package com.saadhjawwadh.notebook

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

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

        // Read responsive height configuration
        val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 180
        if (minHeight < 150) {
            views.setViewVisibility(R.id.widget_recent_section, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_recent_section, View.VISIBLE)
        }

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
        val incomeMonth = prefs.getString("flutter.widget_income_month", "$0.00") ?: "$0.00"
        val recentTransactionsJson = prefs.getString("flutter.widget_recent_transactions", "[]") ?: "[]"

        views.setTextViewText(R.id.widget_today_spent, spentToday)
        views.setTextViewText(R.id.widget_month_spent, spentMonth)
        views.setTextViewText(R.id.widget_month_income, incomeMonth)

        try {
            val jsonArray = JSONArray(recentTransactionsJson)
            val numItems = jsonArray.length()
            if (numItems == 0) {
                views.setViewVisibility(R.id.widget_empty_state, View.VISIBLE)
                views.setViewVisibility(R.id.widget_slot_1, View.GONE)
                views.setViewVisibility(R.id.widget_slot_2, View.GONE)
                views.setViewVisibility(R.id.widget_slot_3, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_empty_state, View.GONE)

                // Slot 1
                if (numItems >= 1) {
                    val tx = jsonArray.getJSONObject(0)
                    views.setViewVisibility(R.id.widget_slot_1, View.VISIBLE)
                    views.setTextViewText(R.id.widget_slot_1_category, tx.optString("category", "Other"))
                    views.setTextViewText(R.id.widget_slot_1_desc, tx.optString("description", ""))
                    views.setTextViewText(R.id.widget_slot_1_amount, tx.optString("amount", "$0.00"))
                    val isExpense = tx.optBoolean("isExpense", true)
                    val colorRes = if (isExpense) R.color.widget_expense else R.color.widget_income
                    views.setTextColor(R.id.widget_slot_1_amount, context.getColor(colorRes))
                } else {
                    views.setViewVisibility(R.id.widget_slot_1, View.GONE)
                }

                // Slot 2
                if (numItems >= 2) {
                    val tx = jsonArray.getJSONObject(1)
                    views.setViewVisibility(R.id.widget_slot_2, View.VISIBLE)
                    views.setTextViewText(R.id.widget_slot_2_category, tx.optString("category", "Other"))
                    views.setTextViewText(R.id.widget_slot_2_desc, tx.optString("description", ""))
                    views.setTextViewText(R.id.widget_slot_2_amount, tx.optString("amount", "$0.00"))
                    val isExpense = tx.optBoolean("isExpense", true)
                    val colorRes = if (isExpense) R.color.widget_expense else R.color.widget_income
                    views.setTextColor(R.id.widget_slot_2_amount, context.getColor(colorRes))
                } else {
                    views.setViewVisibility(R.id.widget_slot_2, View.GONE)
                }

                // Slot 3
                if (numItems >= 3) {
                    val tx = jsonArray.getJSONObject(2)
                    views.setViewVisibility(R.id.widget_slot_3, View.VISIBLE)
                    views.setTextViewText(R.id.widget_slot_3_category, tx.optString("category", "Other"))
                    views.setTextViewText(R.id.widget_slot_3_desc, tx.optString("description", ""))
                    views.setTextViewText(R.id.widget_slot_3_amount, tx.optString("amount", "$0.00"))
                    val isExpense = tx.optBoolean("isExpense", true)
                    val colorRes = if (isExpense) R.color.widget_expense else R.color.widget_income
                    views.setTextColor(R.id.widget_slot_3_amount, context.getColor(colorRes))
                } else {
                    views.setViewVisibility(R.id.widget_slot_3, View.GONE)
                }
            }
        } catch (e: Exception) {
            views.setViewVisibility(R.id.widget_empty_state, View.VISIBLE)
            views.setViewVisibility(R.id.widget_slot_1, View.GONE)
            views.setViewVisibility(R.id.widget_slot_2, View.GONE)
            views.setViewVisibility(R.id.widget_slot_3, View.GONE)
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

        // Intent for clicking the widget body (opens MainActivity)
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
