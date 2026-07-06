package com.elmahdi.travelsuite.data.local.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.domain.model.BookingStatus
import kotlinx.coroutines.flow.Flow

@Dao
interface BookingDao {
    @Query(
        """SELECT * FROM bookings WHERE isDeleted = 0
           AND (customerName LIKE '%' || :q || '%' OR fromAirport LIKE '%' || :q || '%' OR toAirport LIKE '%' || :q || '%')
           AND (:status IS NULL OR status = :status)
           ORDER BY departAt DESC"""
    )
    fun observeAll(q: String = "", status: BookingStatus? = null): Flow<List<BookingEntity>>

    @Query("SELECT * FROM bookings WHERE id = :id")
    suspend fun byId(id: String): BookingEntity?

    @Query("SELECT * FROM bookings WHERE customerId = :customerId AND isDeleted = 0 ORDER BY departAt DESC")
    fun observeByCustomer(customerId: String): Flow<List<BookingEntity>>

    @Upsert
    suspend fun upsert(booking: BookingEntity)

    @Query("UPDATE bookings SET isDeleted = 1, isSynced = 0, updatedAt = :now WHERE id = :id")
    suspend fun softDelete(id: String, now: Long = System.currentTimeMillis())

    // --- لوحة التحكم ---
    /** الرحلات القادمة خلال 24 ساعة */
    @Query("SELECT * FROM bookings WHERE isDeleted = 0 AND status = 'UPCOMING' AND departAt BETWEEN :from AND :to ORDER BY departAt")
    fun observeUpcomingWithin(from: Long, to: Long): Flow<List<BookingEntity>>

    @Query("SELECT * FROM bookings WHERE isDeleted = 0 AND status = 'POSTPONED' ORDER BY departAt")
    fun observePostponed(): Flow<List<BookingEntity>>

    @Query("SELECT COALESCE(SUM(sellPrice - paidAmount), 0) FROM bookings WHERE isDeleted = 0 AND status != 'CANCELLED'")
    fun observeTotalRemaining(): Flow<Double>

    @Query("SELECT COALESCE(SUM(sellPrice - buyPrice), 0) FROM bookings WHERE isDeleted = 0 AND status != 'CANCELLED'")
    fun observeTotalProfit(): Flow<Double>

    // --- تقارير ---
    @Query(
        """SELECT COALESCE(SUM(sellPrice - buyPrice), 0) FROM bookings
           WHERE isDeleted = 0 AND status != 'CANCELLED' AND departAt BETWEEN :from AND :to"""
    )
    suspend fun profitBetween(from: Long, to: Long): Double

    @Query("SELECT * FROM bookings WHERE isDeleted = 0 AND status = 'UPCOMING' AND departAt >= :from ORDER BY departAt")
    suspend fun upcomingFrom(from: Long): List<BookingEntity>

    @Query("SELECT * FROM bookings WHERE isDeleted = 0 AND departAt BETWEEN :from AND :to ORDER BY departAt")
    suspend fun betweenDates(from: Long, to: Long): List<BookingEntity>

    // --- مزامنة ---
    @Query("SELECT * FROM bookings WHERE isSynced = 0")
    suspend fun pendingSync(): List<BookingEntity>

    @Query("UPDATE bookings SET isSynced = 1 WHERE id = :id AND updatedAt = :updatedAt")
    suspend fun markSynced(id: String, updatedAt: Long)

    @Query("SELECT updatedAt FROM bookings WHERE id = :id")
    suspend fun localUpdatedAt(id: String): Long?

    @Query("DELETE FROM bookings")
    suspend fun wipe()
}
