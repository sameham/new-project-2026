package com.elmahdi.travelsuite.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.elmahdi.travelsuite.domain.model.AuditAction
import java.util.UUID

/** سجل العمليات المهمة (يُعرض في شاشة المدير) */
@Entity(tableName = "audit_logs", indices = [Index("timestamp")])
data class AuditLogEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val userId: String,
    val userEmail: String,
    val action: AuditAction,
    val entityType: String = "", // booking / debt / customer ...
    val entityId: String = "",
    val details: String = "",
    val timestamp: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val isDeleted: Boolean = false,
    val isSynced: Boolean = false,
)
