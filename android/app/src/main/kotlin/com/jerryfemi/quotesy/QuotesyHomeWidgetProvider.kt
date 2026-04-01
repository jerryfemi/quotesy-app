package com.jerryfemi.quotesy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONException

class QuotesyHomeWidgetProvider : HomeWidgetProvider() {
    private val tag = "QuotesyWidget"

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.quotesy_home_widget)
                val quotePair = nextQuote(widgetData)
                views.setTextViewText(R.id.widget_quote, "\"${quotePair.first}\"")
                views.setTextViewText(R.id.widget_author, quotePair.second.uppercase())

                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId,
                    intent,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    },
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e(tag, "Failed to update widget id=$appWidgetId", t)
                val fallbackViews = RemoteViews(context.packageName, R.layout.quotesy_home_widget)
                fallbackViews.setTextViewText(R.id.widget_quote, "\"Open Quotesy to refresh your widget.\"")
                fallbackViews.setTextViewText(R.id.widget_author, "QUOTESY")
                appWidgetManager.updateAppWidget(appWidgetId, fallbackViews)
            }
        }
    }

    private fun nextQuote(widgetData: SharedPreferences): Pair<String, String> {
        val fallbackQuote = widgetData.getString(KEY_QUOTE, null)
        val fallbackAuthor = widgetData.getString(KEY_AUTHOR, null)

        val poolJson = widgetData.getString(KEY_POOL, null)
        if (poolJson.isNullOrBlank()) {
            return Pair(
                fallbackQuote ?: "Open Quotesy to load your first quote.",
                fallbackAuthor ?: "Quotesy",
            )
        }

        return try {
            val pool = JSONArray(poolJson)
            if (pool.length() == 0) {
                return Pair(
                    fallbackQuote ?: "Open Quotesy to load your first quote.",
                    fallbackAuthor ?: "Quotesy",
                )
            }

            val current = widgetData.getInt(KEY_INDEX, -1)
            val nextIndex = (current + 1).mod(pool.length())
            widgetData.edit().putInt(KEY_INDEX, nextIndex).apply()

            val item = pool.getJSONObject(nextIndex)
            val text = item.optString("text", fallbackQuote ?: "Quote")
            val author = item.optString("author", fallbackAuthor ?: "Quotesy")
            Pair(text, author)
        } catch (e: JSONException) {
            Log.w(tag, "Failed to parse widget quote pool JSON", e)
            Pair(
                fallbackQuote ?: "Open Quotesy to load your first quote.",
                fallbackAuthor ?: "Quotesy",
            )
        }
    }

    companion object {
        private const val KEY_POOL = "quotesy_widget_pool_v1"
        private const val KEY_INDEX = "quotesy_widget_index_v1"
        private const val KEY_QUOTE = "quotesy_widget_quote_v1"
        private const val KEY_AUTHOR = "quotesy_widget_author_v1"
    }
}
