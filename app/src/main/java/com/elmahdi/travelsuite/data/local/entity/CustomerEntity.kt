package com.elmahdi.travelsuite.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.elmahdi.travelsuite.domain.model.CustomerType
import java.util.UUID

@Entity(tableName = "customers")
data class CustomerEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val phone: String = "",
    val notes: String = "",
    val type: CustomerType = CustomerType.INDIVIDUAL,
    // حقول المزامنة — موجودة في كل الجداول:
    // updatedAt: آخر تعديل (تُستخدم لحسم التعارض: الأحدث يفوز)
    // isDeleted: حذف منطقي حتى تصل عملية الحذف للسحابة
    // isSynced : false تعني أن السجل بانتظار الرفع إلى Firestore
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val isDeleted: Boolean = false,
    val isSynced: Boolean = false,
)
