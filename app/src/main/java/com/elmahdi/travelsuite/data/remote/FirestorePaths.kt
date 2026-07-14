package com.elmahdi.travelsuite.data.remote

/**
 * بنية البيانات في Firestore:
 *
 * users/{uid}                       ← ملف تعريف عام: workspaceId الخاص بالمستخدم
 * workspaces/{wid}/customers/{id}
 * workspaces/{wid}/bookings/{id}
 * workspaces/{wid}/tasaheel/{id}
 * workspaces/{wid}/payments/{id}
 * workspaces/{wid}/debts/{id}
 * workspaces/{wid}/users/{uid}      ← أعضاء مساحة العمل وأدوارهم وصلاحياتهم
 * workspaces/{wid}/audit_logs/{id}
 *
 * وفي Firebase Storage:
 * workspaces/{wid}/transfers/{debtId}.jpg  ← صور التحويلات
 * workspaces/{wid}/backups/{name}.json     ← النسخ الاحتياطية
 *
 * كل بيانات مساحة العمل (حساب المدير) معزولة تحت workspaceId، وبذلك
 * تُحفظ بيانات كل حساب بشكل منفصل ويشارك الموظفون نفس مساحة المدير.
 */
object FirestorePaths {
    const val PROFILES = "users"
    const val WORKSPACES = "workspaces"

    const val CUSTOMERS = "customers"
    const val BOOKINGS = "bookings"
    const val TASAHEEL = "tasaheel"
    const val PAYMENTS = "payments"
    const val DEBTS = "debts"
    const val USERS = "users"
    const val AUDIT_LOGS = "audit_logs"

    val ALL_COLLECTIONS = listOf(CUSTOMERS, BOOKINGS, TASAHEEL, PAYMENTS, DEBTS, USERS, AUDIT_LOGS)
}
