package com.elmahdi.travelsuite.data.repository

import androidx.work.WorkManager
import com.elmahdi.travelsuite.data.local.dao.BookingDao
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.sync.SyncWorker
import com.elmahdi.travelsuite.domain.model.AuditAction
import com.elmahdi.travelsuite.domain.model.BookingStatus
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class BookingRepository @Inject constructor(
    private val dao: BookingDao,
    private val audit: AuditRepository,
    private val workManager: WorkManager,
) {
    fun observeAll(query: String, status: BookingStatus?): Flow<List<BookingEntity>> =
        dao.observeAll(query, status)

    fun observeByCustomer(customerId: String): Flow<List<BookingEntity>> =
        dao.observeByCustomer(customerId)

    suspend fun byId(id: String): BookingEntity? = dao.byId(id)

    suspend fun save(booking: BookingEntity, isNew: Boolean) {
        dao.upsert(booking.copy(updatedAt = System.currentTimeMillis(), isSynced = false))
        audit.log(
            if (isNew) AuditAction.CREATE_BOOKING else AuditAction.UPDATE_BOOKING,
            entityType = "booking",
            entityId = booking.id,
            details = "${booking.customerName}: ${booking.fromAirport} ← ${booking.toAirport}",
        )
        SyncWorker.syncNow(workManager)
    }

    suspend fun delete(id: String) {
        dao.softDelete(id)
        audit.log(AuditAction.DELETE_ENTITY, entityType = "booking", entityId = id)
        SyncWorker.syncNow(workManager)
    }
}
