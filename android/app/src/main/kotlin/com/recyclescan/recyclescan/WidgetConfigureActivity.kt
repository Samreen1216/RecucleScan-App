package com.recyclescan.recyclescan

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.Switch
import android.widget.TextView

class WidgetConfigureActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var widgetSize = 0 // 1 = compact, 2 = wide, 3 = large

    public override fun onCreate(icicle: Bundle?) {
        super.onCreate(icicle)

        // Set the result to CANCELED. This will cause the widget host to cancel
        // out of the widget placement if the user presses the back button.
        setResult(RESULT_CANCELED)

        setContentView(R.layout.activity_widget_configure)

        // Find the widget id from the intent.
        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        // If this activity was started with an intent without an app widget ID, finish with an error.
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val tvTitle = findViewById<TextView>(R.id.tv_widget_title)
        val rbView0 = findViewById<RadioButton>(R.id.rb_view_0)
        val rbView1 = findViewById<RadioButton>(R.id.rb_view_1)
        val rbView2 = findViewById<RadioButton>(R.id.rb_view_2)
        val rbView3 = findViewById<RadioButton>(R.id.rb_view_3)

        // Determine which widget provider this ID belongs to.
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val widgetInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)
        val providerName = widgetInfo?.provider?.className ?: ""

        if (providerName.contains("Compact")) {
            widgetSize = 1
            tvTitle.text = "RecycleScan Small"
            rbView0.text = "App Introduction"
            rbView1.text = "Quick Scan"
            rbView2.text = "Recycling Stats"
        } else if (providerName.contains("Wide")) {
            widgetSize = 2
            tvTitle.text = "RecycleScan Medium"
            rbView0.text = "Eco Tip"
            rbView1.text = "Recent Scan"
            rbView2.text = "Quick Actions"
        } else if (providerName.contains("Large")) {
            widgetSize = 3
            tvTitle.text = "RecycleScan Large"
            rbView0.text = "Dashboard"
            rbView1.text = "Recycling Progress"
            rbView2.text = "Daily Quiz"
            rbView3.text = "Recent Activity"
            rbView3.visibility = View.VISIBLE
        } else {
            // Fallback
            widgetSize = 1
        }
        
        rbView0.isChecked = true

        findViewById<Button>(R.id.btn_cancel).setOnClickListener {
            finish()
        }

        findViewById<Button>(R.id.btn_add).setOnClickListener {
            val context = this@WidgetConfigureActivity
            
            // Get selected view index
            var selectedIndex = 0
            if (rbView1.isChecked) selectedIndex = 1
            if (rbView2.isChecked) selectedIndex = 2
            if (rbView3.isChecked) selectedIndex = 3
            
            val autoRotate = findViewById<Switch>(R.id.sw_auto_rotate).isChecked

            // Save config
            saveWidgetConfig(context, appWidgetId, selectedIndex, autoRotate)

            // It is the responsibility of the configuration activity to update the app widget
            val appWidgetManager = AppWidgetManager.getInstance(context)
            
            // Trigger an update for this specific widget
            val intent = Intent(context, RecycleScanWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            // We need to send to the specific provider class
            intent.component = widgetInfo.provider
            context.sendBroadcast(intent)

            // Make sure we pass back the original appWidgetId
            val resultValue = Intent()
            resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }

    companion object {
        private const val PREFS_NAME = "com.recyclescan.recyclescan.WidgetProvider"
        private const val PREF_PREFIX_KEY = "appwidget_"

        // Write the prefix to the SharedPreferences object for this widget
        internal fun saveWidgetConfig(context: Context, appWidgetId: Int, viewIndex: Int, autoRotate: Boolean) {
            val prefs = context.getSharedPreferences(PREFS_NAME, 0).edit()
            prefs.putInt(PREF_PREFIX_KEY + appWidgetId + "_viewIndex", viewIndex)
            prefs.putBoolean(PREF_PREFIX_KEY + appWidgetId + "_autoRotate", autoRotate)
            prefs.apply()
        }

        // Read the config
        internal fun getViewIndex(context: Context, appWidgetId: Int): Int {
            val prefs = context.getSharedPreferences(PREFS_NAME, 0)
            return prefs.getInt(PREF_PREFIX_KEY + appWidgetId + "_viewIndex", 0)
        }
        
        internal fun getAutoRotate(context: Context, appWidgetId: Int): Boolean {
            val prefs = context.getSharedPreferences(PREFS_NAME, 0)
            return prefs.getBoolean(PREF_PREFIX_KEY + appWidgetId + "_autoRotate", false)
        }
        
        internal fun deleteWidgetConfig(context: Context, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, 0).edit()
            prefs.remove(PREF_PREFIX_KEY + appWidgetId + "_viewIndex")
            prefs.remove(PREF_PREFIX_KEY + appWidgetId + "_autoRotate")
            prefs.apply()
        }
    }
}
