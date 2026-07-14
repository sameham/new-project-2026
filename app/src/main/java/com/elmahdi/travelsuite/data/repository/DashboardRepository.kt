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
    private data class Financials(
        val remaining: Double,
        val profit: Double,
        val refunds: Double,
        val wallet: Double,
    )

    fun observeSummary(): Flow<DashboardSummary> {
        val now = System.currentTimeMillis()

        val financials: Flow<Financials> = combine(
            combine(
                bookingDao.observeTotalRemaining(),
                tasaheelDao.observeTotalRemaining(),
                debtDao.observeTotalOpenRemaining(),
            ) { booking, tasaheel, debt -> booking + tasaheel + debt },
            combine(
                bookingDao.observeTotalProfit(),
                tasaheelDao.observeTotalProfit(),
                paymentDao.observeTotalProfit(),
            ) { booking, tasaheel, payment -> booking + tasaheel + payment },
            paymentDao.observeTotalRefunds(),
            paymentDao.observeWalletBalance(),
        ) { remaining, profit, refunds, wallet ->
            Financials(remaining, profit, refunds, wallet)
        }

        return combine(
            financials,
            bookingDao.observeUpcomingWithin(now, now + 24 * 60 * 60 * 1000L),
            bookingDao.observePostponed(),
        ) { money, upcoming, postponed ->
            DashboardSummary(
                totalRemainingOnCustomers = money.remaining,
                totalProfit = money.profit,
                totalRefunds = money.refunds,
                walletBalance = money.wallet,
                upcoming24h = upcoming,
                postponed = postponed,
            )
        }
    }
}
