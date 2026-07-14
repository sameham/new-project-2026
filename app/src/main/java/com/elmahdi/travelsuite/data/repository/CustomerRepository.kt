package com.elmahdi.travelsuite.data.repository

import androidx.work.WorkManager
import com.elmahdi.travelsuite.data.local.dao.CustomerDao
import com.elmahdi.travelsuite.data.local.entity.CustomerEntity
import com.elmahdi.travelsuite.data.sync.SyncWorker
import com.elmahdi.travelsuite.domain.model.AuditAction
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CustomerRepository @Inject constructor(
    private val dao: CustomerDao,
    private val audit: AuditRepository,
    private val workManager: WorkManager,
) {
    fun observeAll(query: String): Flow<List<CustomerEntity>> = dao.observeAll(query)
    fun observeById(id: String): Flow<CustomerEntity?> = dao.observeById(id)
    suspend fun byId(id: String): CustomerEntity? = dao.byId(id)

    suspend fun save(customer: CustomerEntity) {
        dao.upsert(customer.copy(updatedAt = System.currentTimeMillis(), isSynced = false))
        SyncWorker.syncNow(workManager)
    }

    /** الحذف ممنوع إذا كان العميل مرتبطًا بحجوزات أو ديون أو عمليات تساهيل */
    suspend fun delete(id: String): Result<Unit> {
        if (dao.linkedOperationsCount(id) > 0) {
            return Result.failure(IllegalStateException("لا يمكن حذف العميل لأنه مرتبط بعمليات مسجلة"))
        }
        dao.softDelete(id)
        audit.log(AuditAction.DELETE_ENTITY, entityType = "customer", entityId = id)
        SyncWorker.syncNow(workManager)
        return Result.success(Unit)
    }
}
