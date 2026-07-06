package com.elmahdi.travelsuite.data.sync

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.local.AppDatabase
import com.elmahdi.travelsuite.data.local.entity.AuditLogEntity
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.local.entity.CustomerEntity
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.data.local.entity.PaymentEntity
import com.elmahdi.travelsuite.data.local.entity.TasaheelEntity
import com.elmahdi.travelsuite.data.local.entity.UserEntity
import com.elmahdi.travelsuite.data.remote.FirestorePaths
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.google.firebase.storage.FirebaseStorage
import com.google.gson.Gson
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.tasks.await
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * محرك المزامنة (Offline-First):
 *
 * القاعدة المحلية Room هي مصدر الحقيقة. كل كتابة محلية تُعلَّم isSynced = false.
 *
 * push: يرفع كل السجلات المعلقة إلى Firestore ثم يعلّمها isSynced = true
 *       (بشرط ألا تكون عُدلت أثناء الرفع — الشرط على updatedAt).
 * pull: يجلب من كل مجموعة المستندات التي updatedAt فيها أحدث من آخر سحب،
 *       ويطبقها محليًا فقط إذا كانت أحدث من النسخة المحلية (الأحدث يفوز).
 *
 * الحذف منطقي (isDeleted = true) في الاتجاهين حتى لا تعود السجلات المحذوفة.
 */
@Singleton
class SyncEngine @Inject constructor(
    private val db: AppDatabase,
    private val firestore: FirebaseFirestore,
    private val storage: FirebaseStorage,
    private val session: SessionManager,
    private val dataStore: DataStore<Preferences>,
) {
    private val gson = Gson()

    private class Table<T : Any>(
        val collection: String,
        val type: Class<T>,
        val pending: suspend () -> List<T>,
        val id: (T) -> String,
        val updatedAt: (T) -> Long,
        val markSynced: suspend (String, Long) -> Unit,
        val localUpdatedAt: suspend (String) -> Long?,
        val upsertLocal: suspend (T) -> Unit,
    )

    private fun tables(): List<Table<*>> = listOf(
        Table(FirestorePaths.CUSTOMERS, CustomerEntity::class.java,
            { db.customerDao().pendingSync() }, { it.id }, { it.updatedAt },
            { id, t -> db.customerDao().markSynced(id, t) },
            { db.customerDao().localUpdatedAt(it) },
            { db.customerDao().upsert(it.copy(isSynced = true)) }),
        Table(FirestorePaths.BOOKINGS, BookingEntity::class.java,
            { db.bookingDao().pendingSync() }, { it.id }, { it.updatedAt },
            { id, t -> db.bookingDao().markSynced(id, t) },
            { db.bookingDao().localUpdatedAt(it) },
            { db.bookingDao().upsert(it.copy(isSynced = true)) }),
        Table(FirestorePaths.TASAHEEL, TasaheelEntity::class.java,
            { db.tasaheelDao().pendingSync() }, { it.id }, { it.updatedAt },
            { id, t -> db.tasaheelDao().markSynced(id, t) },
            { db.tasaheelDao().localUpdatedAt(it) },
            { db.tasaheelDao().upsert(it.copy(isSynced = true)) }),
        Table(FirestorePaths.PAYMENTS, PaymentEntity::class.java,
            { db.paymentDao().pendingSync() }, { it.id }, { it.updatedAt },
            { id, t -> db.paymentDao().markSynced(id, t) },
            { db.paymentDao().localUpdatedAt(it) },
            { db.paymentDao().upsert(it.copy(isSynced = true)) }),
        Table(FirestorePaths.DEBTS, DebtEntity::class.java,
            { db.debtDao().pendingSync() }, { it.id }, { it.updatedAt },
            { id, t -> db.debtDao().markSynced(id, t) },
            { db.debtDao().localUpdatedAt(it) },
            { db.debtDao().upsert(it.copy(isSynced = true)) }),
        Table(FirestorePaths.USERS, UserEntity::class.java,
            { db.userDao().pendingSync() }, { it.id }, { it.updatedAt },
            { id, t -> db.userDao().markSynced(id, t) },
            { db.userDao().localUpdatedAt(it) },
            { db.userDao().upsert(it.copy(isSynced = true)) }),
        Table(FirestorePaths.AUDIT_LOGS, AuditLogEntity::class.java,
            { db.auditLogDao().pendingSync() }, { it.id }, { it.updatedAt },
            { id, t -> db.auditLogDao().markSynced(id, t) },
            { db.auditLogDao().localUpdatedAt(it) },
            { db.auditLogDao().upsert(it.copy(isSynced = true)) }),
    )

    /** مزامنة كاملة: رفع المعلق ثم سحب الجديد. تُستدعى من SyncWorker. */
    suspend fun syncAll(): Result<Unit> = runCatching {
        val wid = session.workspaceId() ?: return Result.success(Unit) // لا جلسة بعد
        uploadPendingDebtImages(wid)
        tables().forEach { table ->
            push(wid, table)
            pull(wid, table)
        }
    }

    private suspend fun <T : Any> push(wid: String, table: Table<T>) {
        val col = firestore.collection(FirestorePaths.WORKSPACES).document(wid)
            .collection(table.collection)
        table.pending().forEach { row ->
            val map = entityToMap(row)
            col.document(table.id(row)).set(map, SetOptions.merge()).await()
            table.markSynced(table.id(row), table.updatedAt(row))
        }
    }

    private suspend fun <T : Any> pull(wid: String, table: Table<T>) {
        val key = longPreferencesKey("last_pull_${table.collection}")
        val lastPull = dataStore.data.first()[key] ?: 0L
        val snapshot = firestore.collection(FirestorePaths.WORKSPACES).document(wid)
            .collection(table.collection)
            .whereGreaterThan("updatedAt", lastPull)
            .get().await()

        var maxUpdatedAt = lastPull
        for (doc in snapshot.documents) {
            val entity = mapToEntity(doc.data ?: continue, table.type) ?: continue
            val remoteUpdatedAt = table.updatedAt(entity)
            if (remoteUpdatedAt > maxUpdatedAt) maxUpdatedAt = remoteUpdatedAt
            val localUpdatedAt = table.localUpdatedAt(table.id(entity))
            // الأحدث يفوز: نتجاهل النسخة السحابية إذا كانت المحلية أحدث أو مساوية
            if (localUpdatedAt == null || remoteUpdatedAt > localUpdatedAt) {
                table.upsertLocal(entity)
            }
        }
        dataStore.edit { it[key] = maxUpdatedAt }
    }

    /** رفع صور التحويلات التي حُفظت محليًا ولم تُرفع بعد */
    private suspend fun uploadPendingDebtImages(wid: String) {
        db.debtDao().pendingSync()
            .filter { it.transferImageLocalPath.isNotBlank() && it.transferImageUrl.isBlank() }
            .forEach { debt ->
                val file = File(debt.transferImageLocalPath)
                if (!file.exists()) return@forEach
                val ref = storage.reference.child("$wid/transfers/${debt.id}.jpg")
                ref.putFile(android.net.Uri.fromFile(file)).await()
                val url = ref.downloadUrl.await().toString()
                db.debtDao().upsert(
                    debt.copy(
                        transferImageUrl = url,
                        updatedAt = System.currentTimeMillis(),
                        isSynced = false,
                    )
                )
            }
    }

    /** إعادة ضبط مؤشرات السحب (بعد استرجاع نسخة احتياطية أو مسح القاعدة) */
    suspend fun resetPullCursors() {
        dataStore.edit { prefs ->
            FirestorePaths.ALL_COLLECTIONS.forEach {
                prefs.remove(longPreferencesKey("last_pull_$it"))
            }
        }
    }

    // التحويل بين الكيانات وخرائط Firestore عبر Gson (يحافظ على أسماء الحقول)
    private fun entityToMap(entity: Any): Map<String, Any?> {
        @Suppress("UNCHECKED_CAST")
        return gson.fromJson(gson.toJson(entity), Map::class.java) as Map<String, Any?>
    }

    private fun <T> mapToEntity(map: Map<String, Any?>, type: Class<T>): T? =
        runCatching { gson.fromJson(gson.toJson(map), type) }.getOrNull()
}
