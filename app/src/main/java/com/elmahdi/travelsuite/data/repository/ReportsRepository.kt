package com.elmahdi.travelsuite.data.repository

import com.elmahdi.travelsuite.data.local.AppDatabase
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.data.local.entity.PaymentEntity
import com.elmahdi.travelsuite.data.local.entity.TasaheelEntity
import kotlinx.coroutines.flow.first
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import javax.inject.Inject
import javax.inject.Singleton

data class ProfitReport(
    val bookingsProfit: Double,
    val tasaheelProfit: Double,
    val paymentsProfit: Double,
) { val total: Double get() = bookingsProfit + tasaheelProfit + paymentsProfit }

data class CustomerBalance(val customerId: String, val name: String, val remaining: Double)

data class DateRangeReport(
    val bookings: List<BookingEntity> = emptyList(),
    val tasaheel: List<TasaheelEntity> = emptyList(),
    val payments: List<PaymentEntity> = emptyList(),
    val debts: List<DebtEntity> = emptyList(),
)

/** كل تقارير التطبيق. تعمل بالكامل على القاعدة المحلية (بدون إنترنت). */
@Singleton
class ReportsRepository @Inject constructor(private val db: AppDatabase) {

    private fun dayRange(date: LocalDate): Pair<Long, Long> {
        val zone = ZoneId.systemDefault()
        val from = date.atStartOfDay(zone).toInstant().toEpochMilli()
        val to = date.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli() - 1
        return from to to
    }

    private fun monthRange(month: YearMonth): Pair<Long, Long> {
        val zone = ZoneId.systemDefault()
        val from = month.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val to = month.plusMonths(1).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli() - 1
        return from to to
    }

    /** تقرير الأرباح اليومية */
    suspend fun dailyProfit(date: LocalDate): ProfitReport = profitBetween(dayRange(date))

    /** تقرير الأرباح الشهرية */
    suspend fun monthlyProfit(month: YearMonth): ProfitReport = profitBetween(monthRange(month))

    private suspend fun profitBetween(range: Pair<Long, Long>) = ProfitReport(
        bookingsProfit = db.bookingDao().profitBetween(range.first, range.second),
        tasaheelProfit = db.tasaheelDao().profitBetween(range.first, range.second),
        paymentsProfit = db.paymentDao().profitBetween(range.first, range.second),
    )

    /** تقرير المتبقي على العملاء (حجوزات + تساهيل + ديون مربوطة بالعميل) */
    suspend fun customerBalances(): List<CustomerBalance> {
        val customers = db.customerDao().observeAll("").first()
        val bookings = db.bookingDao().observeAll("", null).first()
        val tasaheel = db.tasaheelDao().observeAll("").first()
        val debts = db.debtDao().observeAll("", null).first()

        return customers.map { customer ->
            val remaining =
                bookings.filter { it.customerId == customer.id }.sumOf { it.remaining } +
                tasaheel.filter { it.customerId == customer.id }.sumOf { it.remaining } +
                debts.filter { it.customerId == customer.id }.sumOf { it.remaining }
            CustomerBalance(customer.id, customer.name, remaining)
        }.filter { it.remaining > 0 }.sortedByDescending { it.remaining }
    }

    /** تقرير الحجوزات القادمة */
    suspend fun upcomingBookings(): List<BookingEntity> =
        db.bookingDao().upcomingFrom(System.currentTimeMillis() - 24 * 60 * 60 * 1000L)

    /** تقرير المديونيات المفتوحة */
    suspend fun openDebts(): List<DebtEntity> = db.debtDao().openDebts()

    /** تقرير المدفوعات في فترة */
    suspend fun payments(from: LocalDate, to: LocalDate): List<PaymentEntity> =
        db.paymentDao().betweenDates(dayRange(from).first, dayRange(to).second)

    /** تقرير حسب العميل: كل عملياته */
    suspend fun byCustomer(customerId: String): DateRangeReport = DateRangeReport(
        bookings = db.bookingDao().observeByCustomer(customerId).first(),
        tasaheel = db.tasaheelDao().observeByCustomer(customerId).first(),
        debts = db.debtDao().observeByCustomer(customerId).first(),
    )

    /** تقرير حسب التاريخ: كل العمليات في فترة */
    suspend fun byDateRange(from: LocalDate, to: LocalDate): DateRangeReport {
        val f = dayRange(from).first
        val t = dayRange(to).second
        return DateRangeReport(
            bookings = db.bookingDao().betweenDates(f, t),
            tasaheel = db.tasaheelDao().betweenDates(f, t),
            payments = db.paymentDao().betweenDates(f, t),
            debts = db.debtDao().betweenDates(f, t),
        )
    }
}
