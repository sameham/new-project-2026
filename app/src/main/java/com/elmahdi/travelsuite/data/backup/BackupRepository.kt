package com.elmahdi.travelsuite.data.backup

import android.content.Context
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.local.AppDatabase
import com.elmahdi.travelsuite.data.local.entity.AuditLogEntity
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.local.entity.CustomerEntity
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.data.local.entity.PaymentEntity
import com.elmahdi.travelsuite.data.local.entity.TasaheelEntity
import com.elmahdi.travelsuite.data.remote.FirestorePaths
import com.elmahdi.travelsuite.data.repository.AuditRepository
import com.elmahdi.travelsuite.data.sync.SyncEngine
import com.elmahdi.travelsuite.domain.model.AuditAction
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.storage.FirebaseStorage
import com.google.gson.Gson
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

/** حزمة النسخة الاحتياطية: لقطة كاملة من كل الجداول بصيغة JSON */
data class BackupData(
    val version: Int = 1,
    val createdAt: Long = System.currentTimeMillis(),
    val customers: List<CustomerEntity> = emptyList(),
    val bookings: List<BookingEntity> = emptyList(),
    val tasaheel: List<TasaheelEntity> = emptyList(),
    val payments: List<PaymentEntity> = emptyList(),
    val debts: List<DebtEntity> = emptyList(),
    val auditLogs: List<AuditLogEntity> = emptyList(),
)

@Singleton
class BackupRepository @Inject constructor(
    private val db: AppDatabase,
    private val storage: FirebaseStorage,
    private val firestore: FirebaseFirestore,
    private val session: SessionManager,
    private val audit: AuditRepository,
    private val syncEngine: SyncEngine,
    @ApplicationContext private val context: Context,
) {
    private val gson = Gson()

    /** ينشئ نسخة احتياطية محليًا ويرفعها إلى Firebase Storage. يعيد اسم النسخة. */
    suspend fun createBackup(): Result<String> = runCatching {
        withContext(Dispatchers.IO) {
            val data = snapshot()
            val name = "backup_" + SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.US)
                .format(Date()) + ".json"
            val file = File(File(context.filesDir, "backups").apply { mkdirs() }, name)
            file.writeText(gson.toJson(data))

            val wid = session.workspaceId() ?: error("لا توجد مساحة عمل")
            storage.reference.child("$wid/backups/$name")
                .putBytes(file.readBytes()).await()
            audit.log(AuditAction.CREATE_BACKUP, details = name)
            name
        }
    }

    /** أسماء النسخ المتوفرة سحابيًا */
    suspend fun listCloudBackups(): Result<List<String>> = runCatching {
        val wid = session.workspaceId() ?: error("لا توجد مساحة عمل")
        storage.reference.child("$wid/backups").listAll().await()
            .items.map { it.name }.sortedDescending()
    }

    /** استرجاع نسخة: تنزيل ← مسح الجداول ← إدراج البيانات وإعادة مزامنتها للسحابة */
    suspend fun restoreBackup(name: String): Result<Unit> = runCatching {
        val wid = session.workspaceId() ?: error("لا توجد مساحة عمل")
        val bytes = storage.reference.child("$wid/backups/$name")
            .getBytes(20L * 1024 * 1024).await()
        val data = gson.fromJson(String(bytes), BackupData::class.java)

        db.wipeAllTables()
        // isSynced = false حتى تُرفع البيانات المسترجعة إلى Firestore من جديد
        data.customers.forEach { db.customerDao().upsert(it.copy(isSynced = false)) }
        data.bookings.forEach { db.bookingDao().upsert(it.copy(isSynced = false)) }
        data.tasaheel.forEach { db.tasaheelDao().upsert(it.copy(isSynced = false)) }
        data.payments.forEach { db.paymentDao().upsert(it.copy(isSynced = false)) }
        data.debts.forEach { db.debtDao().upsert(it.copy(isSynced = false)) }
        data.auditLogs.forEach { db.auditLogDao().upsert(it.copy(isSynced = false)) }
        syncEngine.resetPullCursors()
        audit.log(AuditAction.RESTORE_BACKUP, details = name)
    }

    /**
     * حذف قاعدة البيانات: نسخة احتياطية إجبارية أولًا، ثم مسح محلي
     * وحذف مستندات Firestore حتى لا تعود البيانات مع المزامنة.
     */
    suspend fun wipeDatabase(): Result<String> = runCatching {
        val backupName = createBackup().getOrThrow()
        val wid = session.workspaceId() ?: error("لا توجد مساحة عمل")

        FirestorePaths.ALL_COLLECTIONS.filter { it != FirestorePaths.USERS }.forEach { col ->
            val docs = firestore.collection(FirestorePaths.WORKSPACES).document(wid)
                .collection(col).get().await()
            docs.documents.chunked(400).forEach { chunk ->
                val batch = firestore.batch()
                chunk.forEach { batch.delete(it.reference) }
                batch.commit().await()
            }
        }
        db.wipeAllTables()
        syncEngine.resetPullCursors()
        audit.log(AuditAction.WIPE_DATABASE, details = "نسخة ما قبل الحذف: $backupName")
        backupName
    }

    private suspend fun snapshot() = BackupData(
        customers = db.customerDao().observeAll("").first(),
        bookings = db.bookingDao().observeAll("", null).first(),
        tasaheel = db.tasaheelDao().observeAll("").first(),
        payments = db.paymentDao().observeAll("", null).first(),
        debts = db.debtDao().observeAll("", null).first(),
        auditLogs = db.auditLogDao().observeRecent().first(),
    )
}
