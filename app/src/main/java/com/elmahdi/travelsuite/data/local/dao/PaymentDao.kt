package com.elmahdi.travelsuite.data.local.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import com.elmahdi.travelsuite.data.local.entity.PaymentEntity
import com.elmahdi.travelsuite.domain.model.PaymentCategory
import kotlinx.coroutines.flow.Flow

@Dao
interface PaymentDao {
    @Query(
        """SELECT * FROM payments WHERE isDeleted = 0
           AND payeeName LIKE '%' || :q || '%'
           AND (:category IS NULL OR category = :category)
           ORDER BY date DESC"""
    )
    fun observeAll(q: String = "", category: PaymentCategory? = null): Flow<List<PaymentEntity>>

    @Query("SELECT * FROM payments WHERE id = :id")
    suspend fun byId(id: String): PaymentEntity?

    @Upsert
    suspend fun upsert(payment: PaymentEntity)

    @Query("UPDATE payments SET isDeleted = 1, isSynced = 0, updatedAt = :now WHERE id = :id")
    suspend fun softDelete(id: String, now: Long = System.currentTimeMillis())

    // --- لوحة التحكم ---
    @Query("SELECT COALESCE(SUM(profit), 0) FROM payments WHERE isDeleted = 0")
    fun observeTotalProfit(): Flow<Double>

    /** إجمالي الاستردادات */
    @Query("SELECT COALESCE(SUM(amount * currencyRateEgp), 0) FROM payments WHERE isDeleted = 0 AND category = 'REFUND'")
    fun observeTotalRefunds(): Flow<Double>

    /** رصيد المحفظة = مجموع عمليات تصنيف "محفظة" بالمصري */
    @Query("SELECT COALESCE(SUM(amount * currencyRateEgp), 0) FROM payments WHERE isDeleted = 0 AND category = 'WALLET'")
    fun observeWalletBalance(): Flow<Double>

    // --- تقارير ---
    @Query("SELECT COALESCE(SUM(profit), 0) FROM payments WHERE isDeleted = 0 AND date BETWEEN :from AND :to")
    suspend fun profitBetween(from: Long, to: Long): Double

    @Query("SELECT * FROM payments WHERE isDeleted = 0 AND date BETWEEN :from AND :to ORDER BY date")
    suspend fun betweenDates(from: Long, to: Long): List<PaymentEntity>

    // --- مزامنة ---
    @Query("SELECT * FROM payments WHERE isSynced = 0")
    suspend fun pendingSync(): List<PaymentEntity>

    @Query("UPDATE payments SET isSynced = 1 WHERE id = :id AND updatedAt = :updatedAt")
    suspend fun markSynced(id: String, updatedAt: Long)

    @Query("SELECT updatedAt FROM payments WHERE id = :id")
    suspend fun localUpdatedAt(id: String): Long?

    @Query("DELETE FROM payments")
    suspend fun wipe()
}
