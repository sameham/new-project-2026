package com.elmahdi.travelsuite.data.local.entity

import androidx.room.Entity
import androidx.room.Ignore
import androidx.room.Index
import androidx.room.PrimaryKey
import com.elmahdi.travelsuite.domain.model.BookingStatus
import com.elmahdi.travelsuite.domain.model.TripType
import java.util.UUID

/** حجز طيران. رحلة الذهاب إلزامية، وحقول العودة تُملأ فقط عند "ذهاب وعودة". */
@Entity(tableName = "bookings", indices = [Index("customerId"), Index("departAt"), Index("status")])
data class BookingEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val customerId: String,
    val customerName: String, // منسوخ للعرض السريع في القوائم
    // بيانات الذهاب
    val fromAirport: String,
    val toAirport: String,
    val departAt: Long,        // تاريخ الذهاب (epoch millis لبداية اليوم)
    val departTime: String,    // "HH:mm"
    val tripType: TripType = TripType.ONE_WAY,
    // بيانات العودة (ذهاب وعودة فقط)
    val returnFromAirport: String = "",
    val returnToAirport: String = "",
    val returnAt: Long? = null,
    val returnTime: String = "",
    // البيانات المالية
    val buyPrice: Double = 0.0,
    val sellPrice: Double = 0.0,
    val paidAmount: Double = 0.0,
    val status: BookingStatus = BookingStatus.UPCOMING,
    val notes: String = "",
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val isDeleted: Boolean = false,
    val isSynced: Boolean = false,
) {
    /** الربح = سعر البيع − سعر الشراء (يُحسب تلقائيًا ولا يُخزن) */
    @get:Ignore val profit: Double get() = sellPrice - buyPrice

    /** المتبقي = سعر البيع − المدفوع (يُحسب تلقائيًا ولا يُخزن) */
    @get:Ignore val remaining: Double get() = sellPrice - paidAmount
}
