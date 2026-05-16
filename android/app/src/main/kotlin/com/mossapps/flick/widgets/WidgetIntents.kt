package com.mossapps.flick.widgets

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.mossapps.flick.MainActivity
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Helpers for building [PendingIntent]s used by the widgets.
 *
 * Two flavours are produced:
 *   * Launch intents – open `MainActivity` and forward the Uri to Flutter.
 *     Used for actions that should bring the app to the foreground (open
 *     library section, tap to jump in the now-playing queue).
 *   * Background intents – fire the URI without opening the app. Used for the
 *     play / pause / next / previous transport buttons.
 */
internal object WidgetIntents {

    /** Opens the app and routes the click URI into Flutter. */
    fun launch(context: Context, uri: Uri, requestCode: Int): PendingIntent {
        return HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            uri,
        )
    }

    /** Fires the URI without opening the app (background dispatch). */
    fun background(context: Context, uri: Uri): PendingIntent {
        return HomeWidgetBackgroundIntent.getBroadcast(context, uri)
    }

    fun playerPlayPause(context: Context): PendingIntent =
        background(context, Uri.parse("home_widget://player/play_pause"))

    fun playerNext(context: Context): PendingIntent =
        background(context, Uri.parse("home_widget://player/next"))

    fun playerPrevious(context: Context): PendingIntent =
        background(context, Uri.parse("home_widget://player/previous"))

    fun openApp(context: Context, requestCode: Int): PendingIntent =
        launch(context, Uri.parse("home_widget://player/open"), requestCode)

    fun openLibrarySection(
        context: Context,
        section: String,
        requestCode: Int,
    ): PendingIntent = launch(
        context,
        Uri.parse("home_widget://library/open?section=$section"),
        requestCode,
    )

    /** Template intent used by [RemoteViewsService] item clicks in the queue. */
    fun queueJumpTemplate(context: Context): PendingIntent = launch(
        context,
        Uri.parse("home_widget://player/jump"),
        REQ_QUEUE_TEMPLATE,
    )

    const val REQ_QUEUE_TEMPLATE = 1000
}
