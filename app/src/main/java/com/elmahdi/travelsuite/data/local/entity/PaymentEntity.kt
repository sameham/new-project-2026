package com.elmahdi.travelsuite.data.local.entity

import androidx.room.Entity
import androidx.room.Ignore
import androidx.room.Index
import androidx.room.PrimaryKey
import com.elmahdi.travelsuite.domain.model.PaymentCategory
import java.util.UUID

/** مدفوعات ومصاريف */
@Entity(tableName = "payments", indices = [Index("date"), Index("category")])
data class PaymentEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val payeeName: String,          // اسم الجهة المدفوع لها
    val currency: String = "EGP",   // نوع العملة
    val currencyRateEgp: Double = 1.0, // قيمة العملة بالمصري
    val amount: Double = 0.0,       // المبلغ المدفوع (بالعملة المختارة)
    val profit: Double = 0.0,       // الربح أو العمولة إن وجدت
    val date: Long,
    val notes: String = "",
    val category: PaymentCategory = PaymentCategory.GENERAL_EXPENSE,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val isDeleted: Boolean = false,
    val isSynced: Boolean = false,
) {
    /** قيمة المبلغ محولة للجنيه المصري */
    @get:Ignore val amountEgp: Double get() = amount * currencyRateEgp
}
