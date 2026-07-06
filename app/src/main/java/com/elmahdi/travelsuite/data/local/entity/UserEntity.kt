package com.elmahdi.travelsuite.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.domain.model.UserRole

/**
 * مستخدم داخل مساحة العمل. المصدر الأساسي هو Firestore
 * (workspaces/{wid}/users) وهذه نسخة محلية للعمل بدون إنترنت.
 */
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String, // Firebase UID
    val email: String,
    val displayName: String = "",
    val role: UserRole = UserRole.STAFF,
    val permissionsCsv: String = "", // الصلاحيات مفصولة بفواصل
    val isActive: Boolean = true,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val isDeleted: Boolean = false,
    val isSynced: Boolean = false,
) {
    fun permissions(): Set<Permission> =
        permissionsCsv.split(',').filter { it.isNotBlank() }
            .mapNotNull { runCatching { Permission.valueOf(it.trim()) }.getOrNull() }
            .toSet()

    companion object {
        fun csvOf(permissions: Set<Permission>) = permissions.joinToString(",") { it.name }
    }
}
