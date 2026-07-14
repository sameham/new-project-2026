package com.elmahdi.travelsuite.data.local.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import com.elmahdi.travelsuite.data.local.entity.UserEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface UserDao {
    @Query("SELECT * FROM users WHERE isDeleted = 0 ORDER BY displayName")
    fun observeAll(): Flow<List<UserEntity>>

    @Query("SELECT * FROM users WHERE id = :id")
    suspend fun byId(id: String): UserEntity?

    @Query("SELECT * FROM users WHERE id = :id")
    fun observeById(id: String): Flow<UserEntity?>

    @Upsert
    suspend fun upsert(user: UserEntity)

    @Query("UPDATE users SET isDeleted = 1, isSynced = 0, updatedAt = :now WHERE id = :id")
    suspend fun softDelete(id: String, now: Long = System.currentTimeMillis())

    @Query("SELECT * FROM users WHERE isSynced = 0")
    suspend fun pendingSync(): List<UserEntity>

    @Query("UPDATE users SET isSynced = 1 WHERE id = :id AND updatedAt = :updatedAt")
    suspend fun markSynced(id: String, updatedAt: Long)

    @Query("SELECT updatedAt FROM users WHERE id = :id")
    suspend fun localUpdatedAt(id: String): Long?

    @Query("DELETE FROM users")
    suspend fun wipe()
}
