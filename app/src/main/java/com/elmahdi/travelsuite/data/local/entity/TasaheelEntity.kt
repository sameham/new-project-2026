package com.elmahdi.travelsuite.data.local.entity

import androidx.room.Entity
import androidx.room.Ignore
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

/** عملية تساهيل (خدمات قنصلية) */
@Entity(tableName = "tasaheel", indices = [Index("date"), Index("customerId")])
data class TasaheelEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val customerId: String = "", // اختياري: قد تكون العملية باسم غير مسجل
    val name: String,
    val count: Int = 1,
    val consulate: String,
    val date: Long,
    val sellPrice: Double = 0.0,
    val buyPrice: Double = 0.0,
    val paidAmount: Double = 0.0,
    val notes: String = "",
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val isDeleted: Boolean = false,
    val isSynced: Boolean = false,
) {
    @get:Ignore val profit: Double get() = sellPrice - buyPrice
    @get:Ignore val remaining: Double get() = sellPrice - paidAmount
}
