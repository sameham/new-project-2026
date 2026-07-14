package com.elmahdi.travelsuite.data.local.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.domain.model.DebtStatus
import kotlinx.coroutines.flow.Flow

@Dao
interface DebtDao {
    @Query(
        """SELECT * FROM debts WHERE isDeleted = 0
           AND partyName LIKE '%' || :q || '%'
           AND (:status IS NULL OR status = :status)
           ORDER BY date DESC"""
    )
    fun observeAll(q: String = "", status: DebtStatus? = null): Flow<List<DebtEntity>>

    @Query("SELECT * FROM debts WHERE id = :id")
    suspend fun byId(id: String): DebtEntity?

    @Query("SELECT * FROM debts WHERE customerId = :customerId AND isDeleted = 0 ORDER BY date DESC")
    fun observeByCustomer(customerId: String): Flow<List<DebtEntity>>

    @Upsert
    suspend fun upsert(debt: DebtEntity)

    @Query("UPDATE debts SET isDeleted = 1, isSynced = 0, updatedAt = :now WHERE id = :id")
    suspend fun softDelete(id: String, now: Long = System.currentTimeMillis())

    @Query("SELECT COALESCE(SUM(amount - paidAmount), 0) FROM debts WHERE isDeleted = 0 AND status != 'CLOSED'")
    fun observeTotalOpenRemaining(): Flow<Double>

    @Query("SELECT * FROM debts WHERE isDeleted = 0 AND status != 'CLOSED' ORDER BY date")
    suspend fun openDebts(): List<DebtEntity>

    @Query("SELECT * FROM debts WHERE isDeleted = 0 AND date BETWEEN :from AND :to ORDER BY date")
    suspend fun betweenDates(from: Long, to: Long): List<DebtEntity>

    // --- مزامنة ---
    @Query("SELECT * FROM debts WHERE isSynced = 0")
    suspend fun pendingSync(): List<DebtEntity>

    @Query("UPDATE debts SET isSynced = 1 WHERE id = :id AND updatedAt = :updatedAt")
    suspend fun markSynced(id: String, updatedAt: Long)

    @Query("SELECT updatedAt FROM debts WHERE id = :id")
    suspend fun localUpdatedAt(id: String): Long?

    @Query("DELETE FROM debts")
    suspend fun wipe()
}
