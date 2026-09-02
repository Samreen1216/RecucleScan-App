package com.recyclescan.recyclescan

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle
import android.net.Uri
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

abstract class RecycleScanWidgetProvider : AppWidgetProvider() {

    abstract fun getLayoutId(): Int

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        try {
            val layoutId = getLayoutId()
            val views = RemoteViews(context.packageName, layoutId)

            val widgetData = HomeWidgetPlugin.getData(context)
            val rawIndex = widgetData.getInt("widget_view_index_$appWidgetId", 0)
            val currentIndex = if (rawIndex in 0..2) rawIndex else 0

            val totalItems = widgetData.getInt("total_items", 0)
            val itemsRecycled = widgetData.getInt("items_recycled", 0)
            val itemsThisWeek = widgetData.getInt("items_this_week", 0)
            val recyclablePercentage = widgetData.getInt("recyclable_percentage", 0)
            val ecoTip = widgetData.getString("eco_tip", "Scan any item to discover how to recycle it and help protect our planet.") ?: "Scan any item to discover how to recycle it and help protect our planet."

            val countPlastic = widgetData.getInt("count_plastic", 0)
            val countPaper   = widgetData.getInt("count_paper", 0)
            val countGlass   = widgetData.getInt("count_glass", 0)
            val countMetal   = widgetData.getInt("count_metal", 0)
            val countGeneral = widgetData.getInt("count_general", 0)

            val recent0Name = widgetData.getString("recent_0_name", "No scans yet") ?: "No scans yet"
            val recent0Time = widgetData.getString("recent_0_time", "Tap + to start") ?: "Tap + to start"
            val recent1Name = widgetData.getString("recent_1_name", "-") ?: "-"
            val recent1Time = widgetData.getString("recent_1_time", "-") ?: "-"
            val recent2Name = widgetData.getString("recent_2_name", "-") ?: "-"
            val recent2Time = widgetData.getString("recent_2_time", "-") ?: "-"
            val recent3Name = widgetData.getString("recent_3_name", "-") ?: "-"
            val recent3Time = widgetData.getString("recent_3_time", "-") ?: "-"
            val recent4Name = widgetData.getString("recent_4_name", "-") ?: "-"
            val recent4Time = widgetData.getString("recent_4_time", "-") ?: "-"

            // Text Bindings
            try { views.setTextViewText(R.id.tv_total_items, totalItems.toString()) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_items_this_week, "$itemsThisWeek items") } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_recyclable_percentage, "$recyclablePercentage%") } catch (t: Throwable) {}

            try { views.setTextViewText(R.id.tv_count_plastic, countPlastic.toString()) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_count_paper, countPaper.toString()) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_count_glass, countGlass.toString()) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_count_metal, countMetal.toString()) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_count_general, countGeneral.toString()) } catch (t: Throwable) {}

            try { views.setTextViewText(R.id.tv_eco_tip, ecoTip) } catch (t: Throwable) {}

            try { views.setTextViewText(R.id.tv_recent_0_name, recent0Name) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_recent_0_time, recent0Time) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_recent_1_name, recent1Name) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_recent_1_time, recent1Time) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_recent_2_name, recent2Name) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_recent_2_time, recent2Time) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_recent_3_name, recent3Name) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_recent_3_time, recent3Time) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_recent_4_name, recent4Name) } catch (t: Throwable) {}
            try { views.setTextViewText(R.id.tv_recent_4_time, recent4Time) } catch (t: Throwable) {}

            // Universal RemoteViews ViewFlipper method (works across all Android versions)
            try {
                views.setInt(R.id.view_flipper, "setDisplayedChild", currentIndex)
            } catch (t: Throwable) {}

            fun getPendingIntent(route: String): PendingIntent {
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("recyclescan://app" + route)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                return PendingIntent.getActivity(
                    context,
                    route.hashCode() + appWidgetId,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }

            // Click Handlers for CTAs
            try { views.setOnClickPendingIntent(R.id.btn_scan, getPendingIntent("/scanner")) } catch (t: Throwable) {}
            try { views.setOnClickPendingIntent(R.id.btn_history, getPendingIntent("/history")) } catch (t: Throwable) {}
            try { views.setOnClickPendingIntent(R.id.view_recent_scan_0, getPendingIntent("/history")) } catch (t: Throwable) {}

            // Navigation Intents (< and >)
            val nextIntent = Intent(context, javaClass).apply {
                action = "ACTION_NEXT_VIEW"
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            val nextPI = PendingIntent.getBroadcast(
                context,
                appWidgetId * 10 + 1,
                nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            try { views.setOnClickPendingIntent(R.id.btn_next_0, nextPI) } catch (t: Throwable) {}
            try { views.setOnClickPendingIntent(R.id.btn_next_1, nextPI) } catch (t: Throwable) {}
            try { views.setOnClickPendingIntent(R.id.btn_next_2, nextPI) } catch (t: Throwable) {}

            val prevIntent = Intent(context, javaClass).apply {
                action = "ACTION_PREV_VIEW"
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            val prevPI = PendingIntent.getBroadcast(
                context,
                appWidgetId * 10 + 2,
                prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            try { views.setOnClickPendingIntent(R.id.btn_prev_0, prevPI) } catch (t: Throwable) {}
            try { views.setOnClickPendingIntent(R.id.btn_prev_1, prevPI) } catch (t: Throwable) {}
            try { views.setOnClickPendingIntent(R.id.btn_prev_2, prevPI) } catch (t: Throwable) {}

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (t: Throwable) {
            // Fallback: minimal update so widget is never blank
            try {
                val views = RemoteViews(context.packageName, getLayoutId())
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (ignored: Throwable) {}
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "ACTION_NEXT_VIEW" || intent.action == "ACTION_PREV_VIEW") {
            val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                val widgetData = HomeWidgetPlugin.getData(context)
                var currentIndex = widgetData.getInt("widget_view_index_$appWidgetId", 0)

                if (intent.action == "ACTION_NEXT_VIEW") {
                    currentIndex = (currentIndex + 1) % 3
                } else {
                    currentIndex = (currentIndex - 1 + 3) % 3
                }

                widgetData.edit().putInt("widget_view_index_$appWidgetId", currentIndex).apply()

                val appWidgetManager = AppWidgetManager.getInstance(context)
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}

class RecycleScanWidgetProviderCompact : RecycleScanWidgetProvider() { override fun getLayoutId() = R.layout.widget_compact }
class RecycleScanWidgetProviderWide : RecycleScanWidgetProvider() { override fun getLayoutId() = R.layout.widget_wide }
class RecycleScanWidgetProviderLarge : RecycleScanWidgetProvider() { override fun getLayoutId() = R.layout.widget_large }

