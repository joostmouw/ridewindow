package com.fanalists.ridewindow.ridewindow

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/**
 * RideWidgetProvider — Android AppWidgetProvider that reads next ride slot data
 * from SharedPreferences (written by Flutter via the home_widget package) and
 * updates the widget RemoteViews.
 *
 * Data keys written by WidgetUpdateService via HomeWidget.saveWidgetData:
 *   flutter.slot_available  — Boolean
 *   flutter.slot_date       — String, e.g. "za 21 jun"
 *   flutter.slot_time       — String, e.g. "09:00–13:00"
 *   flutter.slot_duration   — String, e.g. "4u"
 *   flutter.slot_tier       — String, e.g. "Perfect"
 *
 * The home_widget package namespaces all keys under the "flutter." prefix when
 * writing to FlutterSharedPreferences.
 */
class RideWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )

        val slotAvailable = prefs.getBoolean("flutter.slot_available", false)
        val slotDate = prefs.getString("flutter.slot_date", null)
        val slotTime = prefs.getString("flutter.slot_time", null)
        val slotDuration = prefs.getString("flutter.slot_duration", null)
        val slotTier = prefs.getString("flutter.slot_tier", null)

        // Create tap PendingIntent that opens MainActivity (FLAG_IMMUTABLE required on Android 12+)
        val launchIntent = Intent(context, MainActivity::class.java)
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val packageName = context.packageName

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(packageName, R.layout.ride_widget)

            if (slotAvailable) {
                views.setTextViewText(R.id.widget_date, slotDate ?: "")
                views.setTextViewText(R.id.widget_time, slotTime ?: "")
                views.setTextViewText(R.id.widget_duration, slotDuration ?: "")
                views.setTextViewText(R.id.widget_tier, slotTier ?: "")
                views.setViewVisibility(R.id.widget_empty, View.GONE)
            } else {
                views.setTextViewText(R.id.widget_date, "")
                views.setTextViewText(R.id.widget_time, "")
                views.setTextViewText(R.id.widget_duration, "")
                views.setTextViewText(R.id.widget_tier, "")
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            }

            // Wire tap on entire widget to open the app
            views.setOnClickPendingIntent(R.id.widget_root_layout, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
