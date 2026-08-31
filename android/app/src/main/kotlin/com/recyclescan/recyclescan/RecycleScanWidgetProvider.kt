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
        for (appWidgetId in appWidgetIds) updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val layoutId = getLayoutId()
        val views = RemoteViews(context.packageName, layoutId)

        val widgetData = HomeWidgetPlugin.getData(context)
        val currentIndex = widgetData.getInt("widget_view_index_$appWidgetId", 0)
        
        val totalItems = widgetData.getInt("total_items", 0)
        val itemsRecycled = widgetData.getInt("items_recycled", 0)
        val itemsThisWeek = widgetData.getInt("items_this_week", 0)
        val recyclablePercentage = widgetData.getInt("recyclable_percentage", 0)
        val ecoTip = widgetData.getString("eco_tip", "Scan any item to discover how to recycle it and help protect our planet.") ?: ""

        val recent0Name = widgetData.getString("recent_0_name", "No scans yet") ?: "No scans yet"
        val recent0Cat  = widgetData.getString("recent_0_category", "Tap + SCAN to start") ?: "Tap + SCAN to start"
        val recent1Name = widgetData.getString("recent_1_name", "-") ?: "-"
        val recent1Cat  = widgetData.getString("recent_1_category", "-") ?: "-"

        try { views.setTextViewText(R.id.tv_total_items, totalItems.toString()) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_items_recycled, itemsRecycled.toString()) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_items_this_week, "+$itemsThisWeek items") } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recyclable_percentage, "$recyclablePercentage%") } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_eco_tip, ecoTip) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_0_name, recent0Name) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_0_cat, recent0Cat) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_1_name, recent1Name) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_1_cat, recent1Cat) } catch (e: Exception) {}

        try { views.setDisplayedChild(R.id.view_flipper, currentIndex) } catch (e: Exception) {}

        fun getPendingIntent(route: String): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("recyclescan://app" + route)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(context, route.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        try { views.setOnClickPendingIntent(R.id.btn_scan, getPendingIntent("/scanner")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_scan3, getPendingIntent("/scanner")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_history, getPendingIntent("/history")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_history2, getPendingIntent("/history")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_guides, getPendingIntent("/guide")) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.view_recent_scan_0, getPendingIntent("/history")) } catch (e: Exception) {}

        val nextIntent = Intent(context, javaClass).apply {
            action = "ACTION_NEXT_VIEW"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val nextPI = PendingIntent.getBroadcast(context, appWidgetId, nextIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        try { views.setOnClickPendingIntent(R.id.btn_next_0, nextPI) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_next_1, nextPI) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_next_2, nextPI) } catch (e: Exception) {}

        val prevIntent = Intent(context, javaClass).apply {
            action = "ACTION_PREV_VIEW"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val prevPI = PendingIntent.getBroadcast(context, appWidgetId + 1000, prevIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        try { views.setOnClickPendingIntent(R.id.btn_prev_0, prevPI) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_prev_1, prevPI) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_prev_2, prevPI) } catch (e: Exception) {}

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

class RecycleScanWidgetProviderCompact : RecycleScanWidgetProvider() { override fun getLayoutId() = R.layout.widget_compact }
class RecycleScanWidgetProviderWide : RecycleScanWidgetProvider() { override fun getLayoutId() = R.layout.widget_wide }
class RecycleScanWidgetProviderLarge : RecycleScanWidgetProvider() { override fun getLayoutId() = R.layout.widget_large }

