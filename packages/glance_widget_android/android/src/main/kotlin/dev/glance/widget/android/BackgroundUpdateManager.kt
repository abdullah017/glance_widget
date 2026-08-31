package dev.glance.widget.android

import android.content.Context
import android.util.Log
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Manages background widget updates using WorkManager.
 *
 * WorkManager ensures updates happen even when the app is closed,
 * while respecting Android's battery optimization guidelines.
 */
object BackgroundUpdateManager {
    private const val TAG = "BackgroundUpdateManager"
    private const val WORK_NAME_PREFIX = "glance_widget_update_"
    private const val MIN_INTERVAL_MINUTES = 15

    /**
     * Schedule periodic background updates for a widget.
     *
     * @param context Application context
     * @param config Background update configuration
     */
    fun scheduleWork(context: Context, config: BackgroundUpdateConfig) {
        val workName = "$WORK_NAME_PREFIX${config.widgetId}"
        val intervalMinutes = config.intervalMinutes.coerceAtLeast(MIN_INTERVAL_MINUTES)

        Log.d(TAG, "Scheduling work for widget ${config.widgetId} with interval $intervalMinutes minutes")

        // Network constraint - only run when connected
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        // Pass widget ID to worker
        val inputData = Data.Builder()
            .putString("widgetId", config.widgetId)
            .build()

        // Create periodic work request
        val request = PeriodicWorkRequestBuilder<GlanceWidgetWorker>(
            intervalMinutes.toLong(), TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .setInputData(inputData)
            .addTag(config.widgetId)
            .build()

        // Enqueue with UPDATE policy to replace existing work
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            workName,
            ExistingPeriodicWorkPolicy.UPDATE,
            request
        )

        Log.d(TAG, "Work scheduled successfully for widget ${config.widgetId}")
    }

    /**
     * Cancel background updates for a widget.
     *
     * @param context Application context
     * @param widgetId Widget identifier
     */
    fun cancelWork(context: Context, widgetId: String) {
        val workName = "$WORK_NAME_PREFIX$widgetId"
        Log.d(TAG, "Cancelling work for widget $widgetId")

        WorkManager.getInstance(context).cancelUniqueWork(workName)
        BackgroundUpdateConfig.delete(context, widgetId)

        Log.d(TAG, "Work cancelled for widget $widgetId")
    }

    /**
     * Get the status of background updates for a widget.
     *
     * @param context Application context
     * @param widgetId Widget identifier
     * @return Map containing status information
     */
    fun getStatus(context: Context, widgetId: String): Map<String, Any?> {
        val workName = "$WORK_NAME_PREFIX$widgetId"
        val config = BackgroundUpdateConfig.load(context, widgetId)

        val workInfos = try {
            WorkManager.getInstance(context)
                .getWorkInfosForUniqueWork(workName)
                .get()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting work info", e)
            emptyList<WorkInfo>()
        }

        val workInfo = workInfos.firstOrNull()

        return mapOf(
            "widgetId" to widgetId,
            "isConfigured" to (config != null),
            "isEnabled" to (config?.enabled == true),
            "intervalMinutes" to (config?.intervalMinutes ?: 0),
            "workState" to (workInfo?.state?.name ?: "NOT_SCHEDULED"),
            "apiUrl" to config?.apiUrl
        )
    }

    /**
     * Check if background updates are scheduled for a widget.
     *
     * @param context Application context
     * @param widgetId Widget identifier
     * @return true if updates are scheduled
     */
    fun isScheduled(context: Context, widgetId: String): Boolean {
        val workName = "$WORK_NAME_PREFIX$widgetId"

        return try {
            val workInfos = WorkManager.getInstance(context)
                .getWorkInfosForUniqueWork(workName)
                .get()

            workInfos.any { it.state == WorkInfo.State.ENQUEUED || it.state == WorkInfo.State.RUNNING }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking work status", e)
            false
        }
    }

    /**
     * Cancel all background widget updates.
     *
     * @param context Application context
     */
    fun cancelAllWork(context: Context) {
        Log.d(TAG, "Cancelling all widget background work")

        val configs = BackgroundUpdateConfig.getAll(context)
        configs.forEach { config ->
            cancelWork(context, config.widgetId)
        }
    }

    /**
     * Run background update once immediately (for testing).
     *
     * This schedules a one-time work request that runs as soon as possible.
     * Useful for testing the worker without waiting 15 minutes.
     *
     * @param context Application context
     * @param widgetId Widget identifier
     */
    fun runOnce(context: Context, widgetId: String) {
        Log.d(TAG, "Running one-time update for widget: $widgetId")

        val config = BackgroundUpdateConfig.load(context, widgetId)
        if (config == null) {
            Log.e(TAG, "No configuration found for widget: $widgetId")
            return
        }

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val inputData = Data.Builder()
            .putString("widgetId", widgetId)
            .build()

        val request = OneTimeWorkRequestBuilder<GlanceWidgetWorker>()
            .setConstraints(constraints)
            .setInputData(inputData)
            .addTag("${widgetId}_test")
            .build()

        WorkManager.getInstance(context).enqueue(request)
        Log.d(TAG, "One-time work enqueued for widget: $widgetId")
    }
}
