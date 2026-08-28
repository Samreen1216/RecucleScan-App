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

abstract class RecycleScanWidgetProvider : AppWidgetProvider() {

    abstract fun getLayoutId(): Int

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            updateAppWidget(context, appWidgetManager, appWidgetId, options)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            WidgetConfigureActivity.deleteWidgetConfig(context, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        updateAppWidget(context, appWidgetManager, appWidgetId, newOptions)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, options: Bundle?) {
        val widgetData = HomeWidgetPlugin.getData(context)
        
        // --- Shared Data ---
        val totalItems = widgetData.getInt("total_items", 0)
        val itemsRecycled = widgetData.getInt("items_recycled", 0)
        val itemsThisWeek = widgetData.getInt("items_this_week", 0)
        val recyclablePercentage = widgetData.getInt("recyclable_percentage", 0)
        
        // Eco Tip
        val ecoTip = widgetData.getString("eco_tip", "Start your journey by scanning an item to learn how to recycle it properly!")
        
        // Quiz Data
        val quizQuestion = widgetData.getString("quiz_question", "What is the most recycled material in the world?")
        val quizOptionA = widgetData.getString("quiz_option_a", "Plastic")
        val quizOptionB = widgetData.getString("quiz_option_b", "Aluminum")
        val quizOptionC = widgetData.getString("quiz_option_c", "Paper")
        val quizOptionD = widgetData.getString("quiz_option_d", "Glass")
        
        // Recent Scans
        val recent0Name = widgetData.getString("recent_0_name", "-")
        val recent0Cat = widgetData.getString("recent_0_category", "-")
        val recent0Status = widgetData.getString("recent_0_status", "-")
        
        val recent1Name = widgetData.getString("recent_1_name", "-")
        val recent1Cat = widgetData.getString("recent_1_category", "-")
        val recent1Status = widgetData.getString("recent_1_status", "-")
        
        val recent2Name = widgetData.getString("recent_2_name", "-")
        val recent2Cat = widgetData.getString("recent_2_category", "-")
        val recent2Status = widgetData.getString("recent_2_status", "-")

        // Retrieve instance configuration
        val viewIndex = WidgetConfigureActivity.getViewIndex(context, appWidgetId)
        val autoRotate = WidgetConfigureActivity.getAutoRotate(context, appWidgetId)

        val layoutId = getLayoutId()
        val views = RemoteViews(context.packageName, layoutId)

        // Configure ViewFlipper
        try {
            if (autoRotate) {
                // AutoStart and FlipInterval (e.g. 10000ms = 10s) are applied in XML usually or programmatically
                // but RemoteViews doesn't have setFlipInterval natively through easy wrappers for ViewFlipper.
                // However, setAutoStart is available. 
                // A better approach is to rely on XML having autoStart="true" and flipInterval="10000"
                // and here we just toggle it.
                // Wait, some older APIs don't support it. So we just use setBoolean if available.
                views.setBoolean(R.id.view_flipper, "setAutoStart", true)
            } else {
                views.setBoolean(R.id.view_flipper, "setAutoStart", false)
                views.setDisplayedChild(R.id.view_flipper, viewIndex)
            }
        } catch (e: Exception) {}

        // Populate common fields safely
        try { views.setTextViewText(R.id.tv_total_items, totalItems.toString()) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_total_items_2, totalItems.toString()) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_items_recycled, "$itemsRecycled Recycled") } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_items_this_week, "+$itemsThisWeek this week") } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recyclable_percentage, "$recyclablePercentage%") } catch (e: Exception) {}
        
        try { views.setTextViewText(R.id.tv_eco_tip, ecoTip) } catch (e: Exception) {}
        
        // Quiz
        try { views.setTextViewText(R.id.tv_quiz_question, quizQuestion) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_quiz_option_a, quizOptionA) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_quiz_option_b, quizOptionB) } catch (e: Exception) {}
        
        // Recent 0
        try { views.setTextViewText(R.id.tv_recent_0_name, recent0Name) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_0_name_2, recent0Name) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_0_cat, recent0Cat) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_0_cat_2, recent0Cat) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_0_status, recent0Status) } catch (e: Exception) {}
        
        // Recent 1
        try { views.setTextViewText(R.id.tv_recent_1_name, recent1Name) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_1_cat, recent1Cat) } catch (e: Exception) {}
        
        // Recent 2
        try { views.setTextViewText(R.id.tv_recent_2_name, recent2Name) } catch (e: Exception) {}
        try { views.setTextViewText(R.id.tv_recent_2_cat, recent2Cat) } catch (e: Exception) {}

        // PendingIntents for deep linking
        val intentScanner = Intent(Intent.ACTION_VIEW, Uri.parse("recyclescan://app/scanner"))
        val pendingIntentScanner = PendingIntent.getActivity(context, 0, intentScanner, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        
        val intentHistory = Intent(Intent.ACTION_VIEW, Uri.parse("recyclescan://app/history"))
        val pendingIntentHistory = PendingIntent.getActivity(context, 1, intentHistory, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val intentGuides = Intent(Intent.ACTION_VIEW, Uri.parse("recyclescan://app/guide"))
        val pendingIntentGuides = PendingIntent.getActivity(context, 2, intentGuides, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val intentCategories = Intent(Intent.ACTION_VIEW, Uri.parse("recyclescan://app/guide"))
        val pendingIntentCategories = PendingIntent.getActivity(context, 3, intentCategories, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val intentQuiz = Intent(Intent.ACTION_VIEW, Uri.parse("recyclescan://app/quiz"))
        val pendingIntentQuiz = PendingIntent.getActivity(context, 4, intentQuiz, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        // Attach intents safely
        try { views.setOnClickPendingIntent(R.id.btn_scan, pendingIntentScanner) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_scan_2, pendingIntentScanner) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_history, pendingIntentHistory) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_history_2, pendingIntentHistory) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_guides, pendingIntentGuides) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_categories, pendingIntentCategories) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.btn_quiz, pendingIntentQuiz) } catch (e: Exception) {}
        try { views.setOnClickPendingIntent(R.id.view_recent_scan_0, pendingIntentHistory) } catch (e: Exception) {}

        appWidgetManager.updateAppWidget(appWidgetId, views)
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
