package com.elmahdi.travelsuite.domain.model

/** نوع الرحلة */
enum class TripType(val arabic: String) {
    ONE_WAY("ذهاب فقط"),
    ROUND_TRIP("ذهاب وعودة");
}

/** حالة الحجز */
enum class BookingStatus(val arabic: String) {
    UPCOMING("قادم"),
    POSTPONED("مؤجل"),
    COMPLETED("مكتمل"),
    CANCELLED("ملغي");
}

/** تصنيف المدفوعات */
enum class PaymentCategory(val arabic: String) {
    FLIGHT("طيران"),
    TASAHEEL("تساهيل"),
    GENERAL_EXPENSE("مصاريف عامة"),
    WALLET("محفظة"),
    REFUND("استرداد");
}

/** نوع الدين */
enum class DebtType(val arabic: String) {
    WALLET("محفظة"),
    CASH("مبلغ مالي"),
    INSTA("إنستا");
}

/** حالة الدين */
enum class DebtStatus(val arabic: String) {
    OPEN("مفتوح"),
    PARTIALLY_PAID("مدفوع جزئيًا"),
    CLOSED("مغلق");

    companion object {
        /** تُحسب حالة الدين تلقائيًا من المدفوع مقابل قيمة الدين */
        fun from(amount: Double, paid: Double): DebtStatus = when {
            paid <= 0.0 -> OPEN
            paid >= amount -> CLOSED
            else -> PARTIALLY_PAID
        }
    }
}

/** نوع العميل */
enum class CustomerType(val arabic: String) {
    INDIVIDUAL("فرد"),
    COMPANY("شركة");
}

/** أدوار المستخدمين */
enum class UserRole(val arabic: String) {
    ADMIN("مدير كامل الصلاحيات"),
    STAFF("مستخدم عادي"),
    VIEWER("مستخدم عرض فقط");
}

/** الصلاحيات المتاحة في النظام */
enum class Permission(val arabic: String) {
    VIEW_DATA("عرض البيانات"),
    ADD_DATA("إضافة بيانات"),
    EDIT_DATA("تعديل بيانات"),
    DELETE_DATA("حذف بيانات"),
    VIEW_PROFITS("عرض الأرباح"),
    MANAGE_USERS("إدارة المستخدمين"),
    CREATE_BACKUP("إنشاء نسخة احتياطية"),
    WIPE_DATABASE("حذف قاعدة البيانات");

    companion object {
        /** الصلاحيات الافتراضية لكل دور، ويمكن للمدير تخصيصها لكل مستخدم */
        fun defaultsFor(role: UserRole): Set<Permission> = when (role) {
            UserRole.ADMIN -> entries.toSet()
            UserRole.STAFF -> setOf(VIEW_DATA, ADD_DATA, EDIT_DATA)
            UserRole.VIEWER -> setOf(VIEW_DATA)
        }
    }
}

/** أنواع العمليات المسجلة في سجل النظام */
enum class AuditAction(val arabic: String) {
    CREATE_BOOKING("إنشاء حجز"),
    UPDATE_BOOKING("تعديل حجز"),
    DELETE_ENTITY("حذف عملية"),
    CREATE_DEBT("تسجيل مديونية"),
    UPDATE_PERMISSIONS("تعديل صلاحيات"),
    CREATE_BACKUP("إنشاء نسخة احتياطية"),
    RESTORE_BACKUP("استرجاع نسخة احتياطية"),
    WIPE_DATABASE("حذف قاعدة البيانات"),
    USER_MANAGEMENT("إدارة مستخدم"),
    LOGIN("تسجيل دخول");
}
