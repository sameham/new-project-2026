package com.elmahdi.travelsuite.data.auth

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import com.elmahdi.travelsuite.data.local.dao.UserDao
import com.elmahdi.travelsuite.data.local.entity.UserEntity
import com.elmahdi.travelsuite.domain.model.Permission
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject
import javax.inject.Singleton

/**
 * يدير جلسة المستخدم الحالية: من هو، وما مساحة عمله، وما صلاحياته.
 * workspaceId يُحفظ في DataStore حتى يعمل التطبيق بدون إنترنت بعد أول دخول.
 */
@Singleton
class SessionManager @Inject constructor(
    private val auth: FirebaseAuth,
    private val userDao: UserDao,
    private val dataStore: DataStore<Preferences>,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    companion object {
        val KEY_WORKSPACE_ID = stringPreferencesKey("workspace_id")
    }

    val currentUid: String? get() = auth.currentUser?.uid
    val currentEmail: String get() = auth.currentUser?.email.orEmpty()

    suspend fun workspaceId(): String? = dataStore.data.first()[KEY_WORKSPACE_ID]

    suspend fun setWorkspaceId(id: String) {
        dataStore.edit { it[KEY_WORKSPACE_ID] = id }
    }

    suspend fun clearWorkspace() {
        dataStore.edit { it.remove(KEY_WORKSPACE_ID) }
    }

    private val authUid: Flow<String?> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { trySend(it.currentUser?.uid) }
        auth.addAuthStateListener(listener)
        awaitClose { auth.removeAuthStateListener(listener) }
    }

    /** المستخدم الحالي بصلاحياته من القاعدة المحلية (يعمل بدون إنترنت) */
    @OptIn(ExperimentalCoroutinesApi::class)
    val currentUser: StateFlow<UserEntity?> = authUid
        .flatMapLatest { uid -> if (uid == null) flowOf(null) else userDao.observeById(uid) }
        .stateIn(scope, SharingStarted.Eagerly, null)

    fun has(permission: Permission): Boolean {
        val user = currentUser.value ?: return false
        return user.isActive && permission in user.permissions()
    }

    val permissions: Flow<Set<Permission>> = currentUser.map { user ->
        if (user == null || !user.isActive) emptySet() else user.permissions()
    }
}
