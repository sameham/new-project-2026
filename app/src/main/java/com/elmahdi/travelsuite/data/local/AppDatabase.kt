package com.elmahdi.travelsuite.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import com.elmahdi.travelsuite.data.local.dao.AuditLogDao
import com.elmahdi.travelsuite.data.local.dao.BookingDao
import com.elmahdi.travelsuite.data.local.dao.CustomerDao
import com.elmahdi.travelsuite.data.local.dao.DebtDao
import com.elmahdi.travelsuite.data.local.dao.PaymentDao
import com.elmahdi.travelsuite.data.local.dao.TasaheelDao
import com.elmahdi.travelsuite.data.local.dao.UserDao
import com.elmahdi.travelsuite.data.local.entity.AuditLogEntity
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.local.entity.CustomerEntity
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.data.local.entity.PaymentEntity
import com.elmahdi.travelsuite.data.local.entity.TasaheelEntity
import com.elmahdi.travelsuite.data.local.entity.UserEntity

/**
 * قاعدة البيانات المحلية (المصدر الأساسي للحقيقة — Offline First).
 *
 * عند تعديل أي جدول مستقبلًا:
 * 1. ارفع رقم [DB_VERSION].
 * 2. أضف Migration جديدة إلى [AppDatabase.MIGRATIONS] (انظر docs/UPGRADING.md).
 * 3. مخططات كل إصدار تُحفظ تلقائيًا في app/schemas/ لمراجعة الفروق.
 */
const val DB_VERSION = 1
const val DB_NAME = "travel_suite.db"

@Database(
    version = DB_VERSION,
    exportSchema = true,
    entities = [
        CustomerEntity::class,
        BookingEntity::class,
        TasaheelEntity::class,
        PaymentEntity::class,
        DebtEntity::class,
        UserEntity::class,
        AuditLogEntity::class,
    ],
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun customerDao(): CustomerDao
    abstract fun bookingDao(): BookingDao
    abstract fun tasaheelDao(): TasaheelDao
    abstract fun paymentDao(): PaymentDao
    abstract fun debtDao(): DebtDao
    abstract fun userDao(): UserDao
    abstract fun auditLogDao(): AuditLogDao

    /** يمسح كل الجداول (تُستدعى فقط من شاشة المدير بعد أخذ نسخة احتياطية) */
    suspend fun wipeAllTables() {
        customerDao().wipe()
        bookingDao().wipe()
        tasaheelDao().wipe()
        paymentDao().wipe()
        debtDao().wipe()
        auditLogDao().wipe()
        // جدول users لا يُمسح حتى لا يفقد المدير صلاحية الدخول محليًا
    }

    companion object {
        /**
         * مثال لإضافة ترحيل مستقبلي:
         * val MIGRATION_1_2 = object : Migration(1, 2) {
         *     override fun migrate(db: SupportSQLiteDatabase) {
         *         db.execSQL("ALTER TABLE bookings ADD COLUMN pnr TEXT NOT NULL DEFAULT ''")
         *     }
         * }
         */
        val MIGRATIONS: Array<Migration> = arrayOf()
    }
}
