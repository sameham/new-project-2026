package com.elmahdi.travelsuite.data.auth

import com.elmahdi.travelsuite.data.local.dao.UserDao
import com.elmahdi.travelsuite.data.local.entity.UserEntity
import com.elmahdi.travelsuite.data.remote.FirestorePaths
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.domain.model.UserRole
import com.google.firebase.auth.EmailAuthProvider
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore,
    private val userDao: UserDao,
    private val session: SessionManager,
) {
    val isLoggedIn: Boolean get() = auth.currentUser != null

    /**
     * تسجيل الدخول ثم تجهيز الجلسة:
     * - أول دخول على الإطلاق: يُنشأ ملف تعريف ومساحة عمل ويصبح المستخدم مديرًا.
     * - مستخدم أضافه المدير: يُقرأ workspaceId من ملفه ويُجلب دوره وصلاحياته.
     */
    suspend fun login(email: String, password: String): Result<Unit> = runCatching {
        auth.signInWithEmailAndPassword(email.trim(), password).await()
        val uid = auth.currentUser!!.uid

        val profileRef = firestore.collection(FirestorePaths.PROFILES).document(uid)
        val profile = profileRef.get().await()
        val workspaceId = if (profile.exists()) {
            profile.getString("workspaceId") ?: uid
        } else {
            // أول حساب يسجل دخوله يصبح مدير مساحة عمل جديدة
            profileRef.set(mapOf("workspaceId" to uid, "email" to email.trim())).await()
            uid
        }
        session.setWorkspaceId(workspaceId)

        // جلب عضوية المستخدم في مساحة العمل (أو إنشاؤها للمدير الأول)
        val memberRef = firestore.collection(FirestorePaths.WORKSPACES).document(workspaceId)
            .collection(FirestorePaths.USERS).document(uid)
        val member = memberRef.get().await()
        val entity = if (member.exists()) {
            UserEntity(
                id = uid,
                email = member.getString("email") ?: email.trim(),
                displayName = member.getString("displayName").orEmpty(),
                role = runCatching { UserRole.valueOf(member.getString("role") ?: "") }
                    .getOrDefault(UserRole.STAFF),
                permissionsCsv = member.getString("permissionsCsv").orEmpty(),
                isActive = member.getBoolean("isActive") ?: true,
                updatedAt = member.getLong("updatedAt") ?: System.currentTimeMillis(),
                isSynced = true,
            )
        } else {
            val admin = UserEntity(
                id = uid,
                email = email.trim(),
                displayName = "المدير",
                role = UserRole.ADMIN,
                permissionsCsv = UserEntity.csvOf(Permission.defaultsFor(UserRole.ADMIN)),
                isSynced = false,
            )
            admin
        }
        if (!entity.isActive) {
            auth.signOut()
            session.clearWorkspace()
            throw IllegalStateException("هذا الحساب محظور. تواصل مع المدير.")
        }
        userDao.upsert(entity)
    }

    /** دخول بدون إنترنت: يكفي وجود جلسة Firebase مخزنة ومستخدم في القاعدة المحلية */
    suspend fun canWorkOffline(): Boolean {
        val uid = auth.currentUser?.uid ?: return false
        return userDao.byId(uid) != null && session.workspaceId() != null
    }

    suspend fun changePassword(currentPassword: String, newPassword: String): Result<Unit> =
        runCatching {
            val user = auth.currentUser ?: error("لا يوجد مستخدم مسجل")
            val credential = EmailAuthProvider.getCredential(user.email!!, currentPassword)
            user.reauthenticate(credential).await()
            user.updatePassword(newPassword).await()
        }

    suspend fun logout() {
        auth.signOut()
        session.clearWorkspace()
    }
}
