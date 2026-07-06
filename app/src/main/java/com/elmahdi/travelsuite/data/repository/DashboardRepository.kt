package com.elmahdi.travelsuite.data.repository

import com.elmahdi.travelsuite.data.local.dao.BookingDao
import com.elmahdi.travelsuite.data.local.dao.DebtDao
import com.elmahdi.travelsuite.data.local.dao.PaymentDao
import com.elmahdi.travelsuite.data.local.dao.TasaheelDao
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import javax.inject.Inject
import javax.inject.Singleton

/** ملخص لوحة التحكم */
data class DashboardSummary(
    val totalRemainingOnCustomers: Double = 0.0, // حجوزات + تساهيل + ديون مفتوحة
    val totalProfit: Double = 0.0,               // حجوزات + تساهيل + عمولات المدفوعات
    val totalRefunds: Double = 0.0,
    val walletBalance: Double = 0.0,
    val upcoming24h: List<BookingEntity> = emptyList(),
    val postponed: List<BookingEntity> = emptyList(),
)

@Singleton
class DashboardRepository @Inject constructor(
    private val bookingDao: BookingDao,
    private val tasaheelDao: TasaheelDao,
    private val paymentDao: PaymentDao,
    private val debtDao: DebtDao,
) {
    fun observeSummary(): Flow<DashboardSummary> {
        val now = System.currentTimeMillis()
        val financials = combine(
            bookingDao.observeTotalRemaining(),
            tasaheelDao.observeTotalRemaining(),
            debtDao.observeTotalOpenRemaining(),
            bookingDao.observeTotalProfit(),
            tasaheelDao.observeTotalProfit(),
        ) { bRem, tRem, dRem, bProfit, tProfit ->
            DashboardSummary(
                totalRemainingOnCustomers = bRem + tRem + dRem,
                totalProfit = bProfit + tProfit,
            )
        }
        return combine(
            financials,
            paymentDao.observeTotalProfit(),
            paymentDao.observeTotalRefunds(),
            paymentDao.observeWalletBalance(),
            bookingDao.observeUpcomingWithin(now, now + 24 * 60 * 60 * 1000L),
            bookingDao.observePostponed(),
        ) { values ->
            @Suppress("UNCHECKED_CAST")
            val base = values[0] as DashboardSummary
            base.copy(
                totalProfit = base.totalProfit + values[1] as Double,
                totalRefunds = values[2] as Double,
                walletBalance = values[3] as Double,
                upcoming24h = values[4] as List<BookingEntity>,
                postponed = values[5] as List<BookingEntity>,
            )
        }
    }
}
