package com.elmahdi.travelsuite.data.local.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import com.elmahdi.travelsuite.data.local.entity.AuditLogEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface AuditLogDao {
    @Query("SELECT * FROM audit_logs WHERE isDeleted = 0 ORDER BY timestamp DESC LIMIT 300")
    fun observeRecent(): Flow<List<AuditLogEntity>>

    @Upsert
    suspend fun upsert(log: AuditLogEntity)

    @Query("SELECT * FROM audit_logs WHERE isSynced = 0")
    suspend fun pendingSync(): List<AuditLogEntity>

    @Query("UPDATE audit_logs SET isSynced = 1 WHERE id = :id AND updatedAt = :updatedAt")
    suspend fun markSynced(id: String, updatedAt: Long)

    @Query("SELECT updatedAt FROM audit_logs WHERE id = :id")
    suspend fun localUpdatedAt(id: String): Long?

    @Query("DELETE FROM audit_logs")
    suspend fun wipe()
}
