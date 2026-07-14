package com.elmahdi.travelsuite.data.repository

import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.local.dao.AuditLogDao
import com.elmahdi.travelsuite.data.local.entity.AuditLogEntity
import com.elmahdi.travelsuite.domain.model.AuditAction
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuditRepository @Inject constructor(
    private val auditLogDao: AuditLogDao,
    private val session: SessionManager,
) {
    fun observeRecent(): Flow<List<AuditLogEntity>> = auditLogDao.observeRecent()

    suspend fun log(
        action: AuditAction,
        entityType: String = "",
        entityId: String = "",
        details: String = "",
    ) {
        auditLogDao.upsert(
            AuditLogEntity(
                userId = session.currentUid.orEmpty(),
                userEmail = session.currentEmail,
                action = action,
                entityType = entityType,
                entityId = entityId,
                details = details,
            )
        )
    }
}
