package com.elmahdi.travelsuite.data.repository

import androidx.work.WorkManager
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.local.dao.UserDao
import com.elmahdi.travelsuite.data.local.entity.UserEntity
import com.elmahdi.travelsuite.data.remote.FirestorePaths
import com.elmahdi.travelsuite.data.sync.SyncWorker
import com.elmahdi.travelsuite.domain.model.AuditAction
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.domain.model.UserRole
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

/**
 * إدارة مستخدمي مساحة العمل (شاشة المدير).
 *
 * إنشاء مستخدم جديد يتطلب إنترنت لأنه يمر عبر Firebase Authentication،
 * ويُنفذ على نسخة FirebaseAuth ثانوية حتى لا يفقد المدير جلسته الحالية.
 * باقي العمليات (تعديل/تفعيل/حظر/صلاحيات) تعمل بدون إنترنت وتُزامن لاحقًا.
 */
@Singleton
class UserAdminRepository @Inject constructor(
    private val userDao: UserDao,
    private val firestore: FirebaseFirestore,
    private val session: SessionManager,
    private val audit: AuditRepository,
    private val workManager: WorkManager,
) {
    fun observeAll(): Flow<List<UserEntity>> = userDao.observeAll()

    suspend fun createUser(
        email: String,
        password: String,
        displayName: String,
        role: UserRole,
    ): Result<Unit> = runCatching {
        val wid = session.workspaceId() ?: error("لا توجد مساحة عمل")
        val secondaryAuth = secondaryAuth()
        val created = secondaryAuth.createUserWithEmailAndPassword(email.trim(), password).await()
        val uid = created.user!!.uid
        secondaryAuth.signOut()

        // ملف التعريف العام يوجه المستخدم الجديد إلى مساحة عمل المدير عند دخوله
        firestore.collection(FirestorePaths.PROFILES).document(uid)
            .set(mapOf("workspaceId" to wid, "email" to email.trim())).await()

        val user = UserEntity(
            id = uid,
            email = email.trim(),
            displayName = displayName,
            role = role,
            permissionsCsv = UserEntity.csvOf(Permission.defaultsFor(role)),
            isSynced = false,
        )
        userDao.upsert(user)
        audit.log(AuditAction.USER_MANAGEMENT, "user", uid, "إضافة مستخدم: $email")
        SyncWorker.syncNow(workManager)
    }

    suspend fun updateUser(user: UserEntity, note: String) {
        userDao.upsert(user.copy(updatedAt = System.currentTimeMillis(), isSynced = false))
        audit.log(AuditAction.USER_MANAGEMENT, "user", user.id, note)
        SyncWorker.syncNow(workManager)
    }

    suspend fun setActive(user: UserEntity, active: Boolean) =
        updateUser(user.copy(isActive = active), if (active) "تفعيل ${user.email}" else "حظر ${user.email}")

    suspend fun updatePermissions(user: UserEntity, permissions: Set<Permission>) {
        userDao.upsert(
            user.copy(
                permissionsCsv = UserEntity.csvOf(permissions),
                updatedAt = System.currentTimeMillis(),
                isSynced = false,
            )
        )
        audit.log(AuditAction.UPDATE_PERMISSIONS, "user", user.id, "تعديل صلاحيات ${user.email}")
        SyncWorker.syncNow(workManager)
    }

    suspend fun deleteUser(user: UserEntity) {
        userDao.softDelete(user.id)
        audit.log(AuditAction.USER_MANAGEMENT, "user", user.id, "حذف مستخدم: ${user.email}")
        SyncWorker.syncNow(workManager)
    }

    private fun secondaryAuth(): FirebaseAuth {
        val default = FirebaseApp.getInstance()
        val name = "user-creation"
        val app = runCatching { FirebaseApp.getInstance(name) }.getOrElse {
            FirebaseApp.initializeApp(
                default.applicationContext,
                FirebaseOptions.fromResource(default.applicationContext)
                    ?: default.options,
                name,
            )
        }
        return FirebaseAuth.getInstance(app)
    }
}
