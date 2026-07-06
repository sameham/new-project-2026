package com.elmahdi.travelsuite.data.local.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import com.elmahdi.travelsuite.data.local.entity.CustomerEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface CustomerDao {
    @Query("SELECT * FROM customers WHERE isDeleted = 0 AND (name LIKE '%' || :q || '%' OR phone LIKE '%' || :q || '%') ORDER BY name")
    fun observeAll(q: String = ""): Flow<List<CustomerEntity>>

    @Query("SELECT * FROM customers WHERE id = :id")
    suspend fun byId(id: String): CustomerEntity?

    @Query("SELECT * FROM customers WHERE id = :id")
    fun observeById(id: String): Flow<CustomerEntity?>

    @Upsert
    suspend fun upsert(customer: CustomerEntity)

    @Query("UPDATE customers SET isDeleted = 1, isSynced = 0, updatedAt = :now WHERE id = :id")
    suspend fun softDelete(id: String, now: Long = System.currentTimeMillis())

    /** هل العميل مرتبط بعمليات؟ يمنع الحذف إن كان مرتبطًا */
    @Query(
        """SELECT (SELECT COUNT(*) FROM bookings WHERE customerId = :id AND isDeleted = 0)
                + (SELECT COUNT(*) FROM debts WHERE customerId = :id AND isDeleted = 0)
                + (SELECT COUNT(*) FROM tasaheel WHERE customerId = :id AND isDeleted = 0)"""
    )
    suspend fun linkedOperationsCount(id: String): Int

    // --- مزامنة ---
    @Query("SELECT * FROM customers WHERE isSynced = 0")
    suspend fun pendingSync(): List<CustomerEntity>

    @Query("UPDATE customers SET isSynced = 1 WHERE id = :id AND updatedAt = :updatedAt")
    suspend fun markSynced(id: String, updatedAt: Long)

    @Query("SELECT updatedAt FROM customers WHERE id = :id")
    suspend fun localUpdatedAt(id: String): Long?

    @Query("DELETE FROM customers")
    suspend fun wipe()
}
