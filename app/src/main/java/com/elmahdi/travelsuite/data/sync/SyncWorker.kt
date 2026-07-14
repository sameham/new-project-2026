package com.elmahdi.travelsuite.data.sync

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import java.util.concurrent.TimeUnit

/**
 * عامل المزامنة: يعمل فقط عند توفر الإنترنت، ويعيد المحاولة تلقائيًا
 * عند الفشل، فلا تُفقد أي بيانات عند انقطاع الاتصال.
 */
@HiltWorker
class SyncWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val syncEngine: SyncEngine,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result =
        syncEngine.syncAll().fold(
            onSuccess = { Result.success() },
            onFailure = { if (runAttemptCount < 5) Result.retry() else Result.failure() },
        )

    companion object {
        private const val PERIODIC = "sync_periodic"
        private const val IMMEDIATE = "sync_now"

        private val onlineOnly =
            Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

        /** مزامنة دورية كل 15 دقيقة طالما يوجد إنترنت */
        fun schedulePeriodic(workManager: WorkManager) {
            val request = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
                .setConstraints(onlineOnly)
                .build()
            workManager.enqueueUniquePeriodicWork(
                PERIODIC, ExistingPeriodicWorkPolicy.KEEP, request
            )
        }

        /**
         * مزامنة فورية: تُستدعى بعد كل عملية حفظ وعند عودة الإنترنت.
         * إذا لم يوجد اتصال ينتظر WorkManager حتى يعود ثم ينفذها تلقائيًا.
         */
        fun syncNow(workManager: WorkManager) {
            val request = OneTimeWorkRequestBuilder<SyncWorker>()
                .setConstraints(onlineOnly)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10, TimeUnit.SECONDS)
                .build()
            workManager.enqueueUniqueWork(IMMEDIATE, ExistingWorkPolicy.REPLACE, request)
        }
    }
}
