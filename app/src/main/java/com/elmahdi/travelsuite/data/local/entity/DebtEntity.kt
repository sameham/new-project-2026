package com.elmahdi.travelsuite.data.local.entity

import androidx.room.Entity
import androidx.room.Ignore
import androidx.room.Index
import androidx.room.PrimaryKey
import com.elmahdi.travelsuite.domain.model.DebtStatus
import com.elmahdi.travelsuite.domain.model.DebtType
import java.util.UUID

/** مديونية على عميل أو شركة */
@Entity(tableName = "debts", indices = [Index("date"), Index("status"), Index("customerId")])
data class DebtEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val customerId: String = "",   // يُربط بعميل مسجل إن وجد
    val partyName: String,         // اسم الشركة أو العميل
    val debtType: DebtType = DebtType.CASH,
    val date: Long,
    val amount: Double = 0.0,      // قيمة الدين
    val paidAmount: Double = 0.0,  // المدفوع
    val status: DebtStatus = DebtStatus.OPEN,
    val transferImageLocalPath: String = "", // مسار صورة التحويل على الجهاز
    val transferImageUrl: String = "",       // رابط الصورة بعد رفعها إلى Firebase Storage
    val notes: String = "",
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val isDeleted: Boolean = false,
    val isSynced: Boolean = false,
) {
    @get:Ignore val remaining: Double get() = amount - paidAmount
}
