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
        updateAppWidget(context, appWidgetManager, appWidgetId)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val layoutId = getLayoutId()
        val views = RemoteViews(context.packageName, layoutId)

        // Fetch data
        val widgetData = HomeWidgetPlugin.getData(context)
        val currentIndex = widgetData.getInt("widget_view_index_$appWidgetId", 0)
        
        val totalItems = widgetData.getInt("total_items", 0)
        val itemsRecycled = widgetData.getInt("items_recycled", 0)
        val itemsThisWeek = widgetData.getInt("items_this_week", 0)
        val recyclablePercentage = widgetData.getInt("recyclable_percentage", 0)
        val ecoTip = widgetData.getString(
            "eco_tip",
            "Scan any item to discover how to recycle it and help protect our planet."
        ) ?: ""

        val recent0Name = widgetData.getString("recent_0_name", "No scans yet") ?: "No scans yet"
        val recent0Cat  = widgetData.getString("recent_0_category", "Tap + SCAN to start") ?: "Tap + SCAN to start"
        val recent0Status = widgetData.getString("recent_0_status", "") ?: ""
        val recent1Name = widgetData.getString("recent_1_name", "-") ?: "-"
        val recent1Cat  = widgetData.getString("recent_1_category", "-") ?: "-"
        val recent2Name = widgetData.getString("recent_2_name", "-") ?: "-"
        val recent2Cat  = widgetData.getString("recent_2_category", "-") ?: "-"

        // Bind data
        try { views.setTextViewText(R.id.tv_total_items, totalItems.toString()) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_items_recycled, itemsRecycled.toString() + " Recycled") } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_items_this_week, "+$itemsThisWeek items") } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recyclable_percentage, "$recyclablePercentage%") } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_eco_tip, ecoTip) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_eco_tip2, ecoTip) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_0_name, recent0Name) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_0_cat, recent0Cat) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_0_status, recent0Status) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_1_name, recent1Name) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_1_cat, recent1Cat) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_2_name, recent2Name) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_2_cat, recent2Cat) } catch (e: Exception) {}

        // Set the currently displayed view in ViewFlipper manually!
        try { views.setDisplayedChild(R.id.view_flipper, currentIndex) } catch (e: Exception) {}

        // Set Click Intents
        fun getPendingIntent(route: String): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("recyclescan://app" + route)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(context, route.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        try { views.setOnClickPendingIntent(R.id.btn_scan, getPendingIntent("/scanner")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_scan2, getPendingIntent("/scanner")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_scan3, getPendingIntent("/scanner")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_history, getPendingIntent("/history")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_history2, getPendingIntent("/history")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_history3, getPendingIntent("/history")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_guides, getPendingIntent("/guide")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_categories, getPendingIntent("/guide")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.view_recent_scan_0, getPendingIntent("/history")) } catch (e: Exception) {}

        // Prev button manual control
        val prevIntent = Intent(context, this::class.java).apply {
            action = "ACTION_PREV_VIEW"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val prevPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 2 + 1,
            prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try { views.setOnClickPendingIntent(R.id.btn_prev_view, prevPendingIntent) } catch (e: Exception) {}

        // Next button manual control
        val nextIntent = Intent(context, this::class.java).apply {
            action = "ACTION_NEXT_VIEW"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val nextPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 2,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try { views.setOnClickPendingIntent(R.id.btn_next_view, nextPendingIntent) } catch (e: Exception) {}

        appWidgetManager.updateAppWidget(appWidgetId, views)
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

class RecycleScanWidgetProviderCompact : RecycleScanWidgetProvider() {
    override fun getLayoutId() = R.layout.widget_compact
}

class RecycleScanWidgetProviderWide : RecycleScanWidgetProvider() {
    override fun getLayoutId() = R.layout.widget_wide
}

class RecycleScanWidgetProviderLarge : RecycleScanWidgetProvider() {
    override fun getLayoutId() = R.layout.widget_large
}
