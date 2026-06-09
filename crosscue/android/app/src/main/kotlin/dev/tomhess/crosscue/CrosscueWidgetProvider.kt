package dev.tomhess.crosscue

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * Android home-screen widget (#204) — parity with the iOS WidgetKit widget
 * (#114). Renders the current streak + today's puzzle from the same shared-prefs
 * payload `HomeWidgetService` pushes (`crosscue_widget_v1`, schema v1).
 *
 * Tapping deep-links into the app at today's `/solve/<id>` route via the
 * path-form `crosscue://<route>` URL, which `FlutterDeepLinkingEnabled` routes
 * into go_router — mirroring the iOS `widgetURL`.
 *
 * The layout is stacked optional rows (streak / today / future leaderboard) to
 * match #114's additive-schema contract: a `leaderboard` slot can be filled in
 * later without a rebuild.
 */
class CrosscueWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = widgetData.getString(DATA_KEY, null)?.let { raw ->
            runCatching { JSONObject(raw) }.getOrNull()
        }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.crosscue_widget)

            // Streak row.
            val current = payload?.optJSONObject("streak")?.optInt("current", 0) ?: 0
            views.setTextViewText(R.id.widget_streak_value, current.toString())
            views.setViewVisibility(
                R.id.widget_streak_flame,
                if (current > 0) View.VISIBLE else View.GONE,
            )

            // Today row + tap target.
            val today = payload?.optJSONObject("today")
            if (today != null) {
                views.setTextViewText(
                    R.id.widget_today_title,
                    today.optString("title", "Today's puzzle"),
                )
                val status = today.optString("status")
                views.setTextViewText(R.id.widget_today_status, statusLabel(status))
                views.setTextColor(R.id.widget_today_status, statusColor(context, status))
                val route = today.optString("route")
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    deepLinkIntent(context, if (route.isEmpty()) "/" else route),
                )
            } else {
                views.setTextViewText(R.id.widget_today_title, "No puzzle yet")
                views.setTextViewText(R.id.widget_today_status, "")
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    deepLinkIntent(context, "/"),
                )
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * Launches the app for a widget tap via home_widget's launch intent, which
     * carries `crosscue://<route>` (e.g. `crosscue:///solve/<id>`). The Dart side
     * (`app.dart`) listens on `HomeWidget.widgetClicked` /
     * `initiallyLaunchedFromHomeWidget` and routes the URI's path into go_router.
     * `route` is already a percent-encoded go_router path, so it drops in
     * verbatim. (iOS uses the widget's `widgetURL` + FlutterDeepLinkingEnabled
     * instead — home_widget's click stream doesn't fire under the iOS scene
     * lifecycle.)
     */
    private fun deepLinkIntent(context: Context, route: String): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("crosscue://$route"),
        )

    private fun statusLabel(status: String?): String = when (status) {
        "solved" -> "✓ Solved"
        "inProgress" -> "In progress"
        "new" -> "▶ Solve"
        else -> ""
    }

    private fun statusColor(context: Context, status: String?): Int = ContextCompat.getColor(
        context,
        if (status == "solved") R.color.crosscue_widget_solved else R.color.crosscue_brand,
    )

    private companion object {
        // Must match HomeWidgetService.dataKey on the Dart side.
        const val DATA_KEY = "crosscue_widget_v1"
    }
}
