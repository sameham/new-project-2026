package com.elmahdi.travelsuite.data.repository

import android.content.Context
import android.net.Uri
import androidx.work.WorkManager
import com.elmahdi.travelsuite.data.local.dao.DebtDao
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.data.sync.SyncWorker
import com.elmahdi.travelsuite.domain.model.AuditAction
import com.elmahdi.travelsuite.domain.model.DebtStatus
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DebtRepository @Inject constructor(
    private val dao: DebtDao,
    private val audit: AuditRepository,
    private val workManager: WorkManager,
    @ApplicationContext private val context: Context,
) {
    fun observeAll(query: String, status: DebtStatus?): Flow<List<DebtEntity>> =
        dao.observeAll(query, status)

    fun observeByCustomer(customerId: String): Flow<List<DebtEntity>> =
        dao.observeByCustomer(customerId)

    suspend fun byId(id: String): DebtEntity? = dao.byId(id)

    /**
     * الحفظ مع حساب حالة الدين تلقائيًا من المدفوع/القيمة، ونسخ صورة التحويل
     * (إن اختيرت) إلى تخزين التطبيق ليرفعها محرك المزامنة عند توفر الإنترنت.
     */
    suspend fun save(debt: DebtEntity, isNew: Boolean, transferImage: Uri? = null) {
        val localImagePath = transferImage?.let { copyImageLocally(debt.id, it) }
            ?: debt.transferImageLocalPath
        dao.upsert(
            debt.copy(
                status = DebtStatus.from(debt.amount, debt.paidAmount),
                transferImageLocalPath = localImagePath,
                updatedAt = System.currentTimeMillis(),
                isSynced = false,
            )
        )
        if (isNew) {
            audit.log(
                AuditAction.CREATE_DEBT, entityType = "debt", entityId = debt.id,
                details = "${debt.partyName}: ${debt.amount}",
            )
        }
        SyncWorker.syncNow(workManager)
    }

    suspend fun delete(id: String) {
        dao.softDelete(id)
        audit.log(AuditAction.DELETE_ENTITY, entityType = "debt", entityId = id)
        SyncWorker.syncNow(workManager)
    }

    private suspend fun copyImageLocally(debtId: String, uri: Uri): String =
        withContext(Dispatchers.IO) {
            val dir = File(context.filesDir, "transfers").apply { mkdirs() }
            val target = File(dir, "$debtId.jpg")
            context.contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            }
            target.absolutePath
        }
}
