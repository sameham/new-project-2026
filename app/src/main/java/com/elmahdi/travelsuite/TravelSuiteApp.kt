package com.elmahdi.travelsuite

import android.app.Application
import androidx.hilt.work.HiltWorkerFactory
import androidx.work.Configuration
import androidx.work.WorkManager
import com.elmahdi.travelsuite.data.sync.NetworkMonitor
import com.elmahdi.travelsuite.data.sync.SyncWorker
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltAndroidApp
class TravelSuiteApp : Application(), Configuration.Provider {

    @Inject lateinit var workerFactory: HiltWorkerFactory
    @Inject lateinit var networkMonitor: NetworkMonitor

    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder().setWorkerFactory(workerFactory).build()

    override fun onCreate() {
        super.onCreate()
        val workManager = WorkManager.getInstance(this)
        SyncWorker.schedulePeriodic(workManager)

        // عند عودة الإنترنت: مزامنة فورية تلقائية
        appScope.launch {
            networkMonitor.isOnline.collect { online ->
                if (online) SyncWorker.syncNow(workManager)
            }
        }
    }
}
