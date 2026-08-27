package com.recyclescan.recyclescan

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

open class RecycleScanWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            updateAppWidget(context, appWidgetManager, appWidgetId, options)
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        updateAppWidget(context, appWidgetManager, appWidgetId, newOptions)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, options: Bundle?) {
        val widgetData = HomeWidgetPlugin.getData(context)
        
        val totalItems = widgetData.getInt("total_items", 0)
        val itemsThisWeek = widgetData.getInt("items_this_week", 0)
        val contentTitle = widgetData.getString("content_title", "ECO TIP")
        val contentText = widgetData.getString("content_text", "Small actions. Big impact.")
        val recent0 = widgetData.getString("recent_item_0", "-")
        val recent1 = widgetData.getString("recent_item_1", "-")
        val recent2 = widgetData.getString("recent_item_2", "-")

        val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
        val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0

        // Determine layout based on dimensions
        val layoutId = when {
            minWidth >= 220 && minHeight >= 220 -> R.layout.widget_large
            minWidth >= 220 -> R.layout.widget_wide
            else -> R.layout.widget_compact
        }

        val views = RemoteViews(context.packageName, layoutId)

        // Populate common fields safely
        try { views.setTextViewText(R.id.tv_total_items, totalItems.toString()) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_message, contentText) } catch (e: Exception) {}
        
        // Fields for wide/large
        try { views.setTextViewText(R.id.tv_content_title, contentTitle) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_content_text, contentText) } catch (e: Exception) {}
        
        // Fields for large
        try { views.setTextViewText(R.id.tv_items_this_week, "+$itemsThisWeek this week") } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_item_0, recent0) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_item_1, recent1) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_item_2, recent2) } catch (e: Exception) {}

        // PendingIntent for deep linking
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("recyclescan://app/scanner"))
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try { views.setOnClickPendingIntent(R.id.btn_scan, pendingIntent) } catch (e: Exception) {}

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

class RecycleScanWidgetProviderCompact : RecycleScanWidgetProvider()
class RecycleScanWidgetProviderWide : RecycleScanWidgetProvider()
class RecycleScanWidgetProviderLarge : RecycleScanWidgetProvider()
