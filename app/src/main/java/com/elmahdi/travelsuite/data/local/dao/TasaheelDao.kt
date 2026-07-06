package com.elmahdi.travelsuite.data.local.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import com.elmahdi.travelsuite.data.local.entity.TasaheelEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface TasaheelDao {
    @Query(
        """SELECT * FROM tasaheel WHERE isDeleted = 0
           AND (name LIKE '%' || :q || '%' OR consulate LIKE '%' || :q || '%')
           ORDER BY date DESC"""
    )
    fun observeAll(q: String = ""): Flow<List<TasaheelEntity>>

    @Query("SELECT * FROM tasaheel WHERE id = :id")
    suspend fun byId(id: String): TasaheelEntity?

    @Query("SELECT * FROM tasaheel WHERE customerId = :customerId AND isDeleted = 0 ORDER BY date DESC")
    fun observeByCustomer(customerId: String): Flow<List<TasaheelEntity>>

    @Upsert
    suspend fun upsert(item: TasaheelEntity)

    @Query("UPDATE tasaheel SET isDeleted = 1, isSynced = 0, updatedAt = :now WHERE id = :id")
    suspend fun softDelete(id: String, now: Long = System.currentTimeMillis())

    @Query("SELECT COALESCE(SUM(sellPrice - buyPrice), 0) FROM tasaheel WHERE isDeleted = 0")
    fun observeTotalProfit(): Flow<Double>

    @Query("SELECT COALESCE(SUM(sellPrice - paidAmount), 0) FROM tasaheel WHERE isDeleted = 0")
    fun observeTotalRemaining(): Flow<Double>

    @Query("SELECT COALESCE(SUM(sellPrice - buyPrice), 0) FROM tasaheel WHERE isDeleted = 0 AND date BETWEEN :from AND :to")
    suspend fun profitBetween(from: Long, to: Long): Double

    @Query("SELECT * FROM tasaheel WHERE isDeleted = 0 AND date BETWEEN :from AND :to ORDER BY date")
    suspend fun betweenDates(from: Long, to: Long): List<TasaheelEntity>

    // --- مزامنة ---
    @Query("SELECT * FROM tasaheel WHERE isSynced = 0")
    suspend fun pendingSync(): List<TasaheelEntity>

    @Query("UPDATE tasaheel SET isSynced = 1 WHERE id = :id AND updatedAt = :updatedAt")
    suspend fun markSynced(id: String, updatedAt: Long)

    @Query("SELECT updatedAt FROM tasaheel WHERE id = :id")
    suspend fun localUpdatedAt(id: String): Long?

    @Query("DELETE FROM tasaheel")
    suspend fun wipe()
}
