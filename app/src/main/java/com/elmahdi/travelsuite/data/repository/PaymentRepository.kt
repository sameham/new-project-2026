package com.elmahdi.travelsuite.data.repository

import androidx.work.WorkManager
import com.elmahdi.travelsuite.data.local.dao.PaymentDao
import com.elmahdi.travelsuite.data.local.entity.PaymentEntity
import com.elmahdi.travelsuite.data.sync.SyncWorker
import com.elmahdi.travelsuite.domain.model.AuditAction
import com.elmahdi.travelsuite.domain.model.PaymentCategory
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PaymentRepository @Inject constructor(
    private val dao: PaymentDao,
    private val audit: AuditRepository,
    private val workManager: WorkManager,
) {
    fun observeAll(query: String, category: PaymentCategory?): Flow<List<PaymentEntity>> =
        dao.observeAll(query, category)

    suspend fun byId(id: String): PaymentEntity? = dao.byId(id)

    suspend fun save(payment: PaymentEntity) {
        dao.upsert(payment.copy(updatedAt = System.currentTimeMillis(), isSynced = false))
        SyncWorker.syncNow(workManager)
    }

    suspend fun delete(id: String) {
        dao.softDelete(id)
        audit.log(AuditAction.DELETE_ENTITY, entityType = "payment", entityId = id)
        SyncWorker.syncNow(workManager)
    }
}
