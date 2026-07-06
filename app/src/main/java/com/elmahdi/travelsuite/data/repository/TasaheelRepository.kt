package com.elmahdi.travelsuite.data.repository

import androidx.work.WorkManager
import com.elmahdi.travelsuite.data.local.dao.TasaheelDao
import com.elmahdi.travelsuite.data.local.entity.TasaheelEntity
import com.elmahdi.travelsuite.data.sync.SyncWorker
import com.elmahdi.travelsuite.domain.model.AuditAction
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TasaheelRepository @Inject constructor(
    private val dao: TasaheelDao,
    private val audit: AuditRepository,
    private val workManager: WorkManager,
) {
    fun observeAll(query: String): Flow<List<TasaheelEntity>> = dao.observeAll(query)
    suspend fun byId(id: String): TasaheelEntity? = dao.byId(id)

    suspend fun save(item: TasaheelEntity) {
        dao.upsert(item.copy(updatedAt = System.currentTimeMillis(), isSynced = false))
        SyncWorker.syncNow(workManager)
    }

    suspend fun delete(id: String) {
        dao.softDelete(id)
        audit.log(AuditAction.DELETE_ENTITY, entityType = "tasaheel", entityId = id)
        SyncWorker.syncNow(workManager)
    }
}
