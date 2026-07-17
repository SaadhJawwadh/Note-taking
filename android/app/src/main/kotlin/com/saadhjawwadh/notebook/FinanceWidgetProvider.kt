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
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // Responsive tiers: analytics grow first; recent transactions only
        // appear on the tallest sizes.
        val widgetOptions = options ?: appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minHeight = widgetOptions?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 180
        val hasBudget = (prefs.getLong("flutter.widget_budget_percent", -1L).toInt()) >= 0
        val showBudget = minHeight >= 120 && hasBudget
        val showTopCategory = minHeight >= if (hasBudget) 190 else 120
        val showRecent = minHeight >= 260

        views.setViewVisibility(R.id.widget_budget_section, if (showBudget) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_top_category_section, if (showTopCategory) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_recent_section, if (showRecent) View.VISIBLE else View.GONE)

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
        val recentTransactionsJson = prefs.getString("flutter.widget_recent_transactions", "[]") ?: "[]"

        views.setTextViewText(R.id.widget_today_spent, spentToday)
        views.setTextViewText(R.id.widget_month_spent, spentMonth)
        views.setTextViewText(R.id.widget_month_net, netMonth)
        views.setTextColor(
            R.id.widget_month_net,
            context.getColor(if (netPositive) R.color.widget_income else R.color.widget_expense)
        )

        // Budget progress
        val budgetPercent = prefs.getLong("flutter.widget_budget_percent", -1L).toInt()
        if (budgetPercent >= 0) {
            views.setProgressBar(R.id.widget_budget_bar, 100, budgetPercent.coerceAtMost(100), false)
            views.setTextViewText(R.id.widget_budget_percent, "$budgetPercent%")
            views.setTextColor(
                R.id.widget_budget_percent,
                context.getColor(if (budgetPercent > 100) R.color.widget_expense else R.color.widget_on_primary_container)
            )
            views.setTextViewText(
                R.id.widget_budget_label,
                prefs.getString("flutter.widget_budget_label", "") ?: ""
            )
        }

        // Top spending category
        val topCategory = prefs.getString("flutter.widget_top_category", "") ?: ""
        if (topCategory.isNotEmpty()) {
            views.setTextViewText(R.id.widget_top_category, "Top: $topCategory")
            views.setTextViewText(
                R.id.widget_top_category_amount,
                prefs.getString("flutter.widget_top_category_amount", "") ?: ""
            )
        } else {
            views.setViewVisibility(R.id.widget_top_category_section, View.GONE)
        }

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
