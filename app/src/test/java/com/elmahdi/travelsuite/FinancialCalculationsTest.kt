package com.elmahdi.travelsuite

import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.data.local.entity.PaymentEntity
import com.elmahdi.travelsuite.data.local.entity.TasaheelEntity
import com.elmahdi.travelsuite.data.local.entity.UserEntity
import com.elmahdi.travelsuite.domain.model.DebtStatus
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.domain.model.UserRole
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** اختبارات منطق الحسابات المالية التلقائية */
class FinancialCalculationsTest {

    private fun booking(buy: Double, sell: Double, paid: Double) = BookingEntity(
        customerId = "c1", customerName = "عميل",
        fromAirport = "القاهرة", toAirport = "جدة",
        departAt = 0L, departTime = "10:00",
        buyPrice = buy, sellPrice = sell, paidAmount = paid,
    )

    @Test
    fun `ربح الحجز = البيع - الشراء`() {
        assertEquals(1500.0, booking(buy = 8500.0, sell = 10000.0, paid = 0.0).profit, 0.001)
    }

    @Test
    fun `متبقي الحجز = البيع - المدفوع`() {
        assertEquals(4000.0, booking(buy = 8500.0, sell = 10000.0, paid = 6000.0).remaining, 0.001)
    }

    @Test
    fun `الربح قد يكون سالبًا عند البيع بخسارة`() {
        assertEquals(-500.0, booking(buy = 10500.0, sell = 10000.0, paid = 0.0).profit, 0.001)
    }

    @Test
    fun `حسابات تساهيل`() {
        val t = TasaheelEntity(name = "n", consulate = "c", date = 0L,
            sellPrice = 3000.0, buyPrice = 2000.0, paidAmount = 1000.0)
        assertEquals(1000.0, t.profit, 0.001)
        assertEquals(2000.0, t.remaining, 0.001)
    }

    @Test
    fun `تحويل عملة الدفعة إلى المصري`() {
        val p = PaymentEntity(payeeName = "x", date = 0L,
            currency = "USD", currencyRateEgp = 50.0, amount = 100.0)
        assertEquals(5000.0, p.amountEgp, 0.001)
    }

    @Test
    fun `حالة الدين تلقائية - مفتوح ثم جزئي ثم مغلق`() {
        assertEquals(DebtStatus.OPEN, DebtStatus.from(amount = 1000.0, paid = 0.0))
        assertEquals(DebtStatus.PARTIALLY_PAID, DebtStatus.from(amount = 1000.0, paid = 400.0))
        assertEquals(DebtStatus.CLOSED, DebtStatus.from(amount = 1000.0, paid = 1000.0))
        assertEquals(DebtStatus.CLOSED, DebtStatus.from(amount = 1000.0, paid = 1200.0))
    }

    @Test
    fun `متبقي الدين`() {
        val d = DebtEntity(partyName = "شركة", date = 0L, amount = 1000.0, paidAmount = 250.0)
        assertEquals(750.0, d.remaining, 0.001)
    }
}

/** اختبارات نظام الصلاحيات */
class PermissionsTest {

    @Test
    fun `المدير يملك كل الصلاحيات`() {
        assertEquals(Permission.entries.toSet(), Permission.defaultsFor(UserRole.ADMIN))
    }

    @Test
    fun `مستخدم العرض فقط لا يملك سوى عرض البيانات`() {
        assertEquals(setOf(Permission.VIEW_DATA), Permission.defaultsFor(UserRole.VIEWER))
    }

    @Test
    fun `المستخدم العادي لا يحذف ولا يدير المستخدمين`() {
        val staff = Permission.defaultsFor(UserRole.STAFF)
        assertTrue(Permission.DELETE_DATA !in staff)
        assertTrue(Permission.MANAGE_USERS !in staff)
        assertTrue(Permission.WIPE_DATABASE !in staff)
    }

    @Test
    fun `حفظ الصلاحيات كنص واسترجاعها بلا فقد`() {
        val original = setOf(Permission.VIEW_DATA, Permission.ADD_DATA, Permission.VIEW_PROFITS)
        val user = UserEntity(id = "u1", email = "a@b.c",
            permissionsCsv = UserEntity.csvOf(original))
        assertEquals(original, user.permissions())
    }

    @Test
    fun `قيم صلاحيات تالفة تُتجاهل بدل الانهيار`() {
        val user = UserEntity(id = "u1", email = "a@b.c",
            permissionsCsv = "VIEW_DATA,GARBAGE_VALUE,,ADD_DATA")
        assertEquals(setOf(Permission.VIEW_DATA, Permission.ADD_DATA), user.permissions())
    }
}
