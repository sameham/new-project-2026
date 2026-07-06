# دليل تحديث التطبيق مستقبلًا

البنية مقسمة إلى طبقات (data / domain / ui) بحيث يُضاف أي شيء جديد دون لمس الموجود.

## 1) تعديل جدول في قاعدة البيانات (Migration)

مثال: إضافة حقل `pnr` لجدول الحجوزات.

1. أضف الحقل في `BookingEntity` بقيمة افتراضية:
   ```kotlin
   val pnr: String = "",
   ```
2. ارفع رقم الإصدار في `data/local/AppDatabase.kt`:
   ```kotlin
   const val DB_VERSION = 2
   ```
3. أضف Migration في نفس الملف داخل `companion object`:
   ```kotlin
   val MIGRATION_1_2 = object : Migration(1, 2) {
       override fun migrate(db: SupportSQLiteDatabase) {
           db.execSQL("ALTER TABLE bookings ADD COLUMN pnr TEXT NOT NULL DEFAULT ''")
       }
   }
   val MIGRATIONS = arrayOf<Migration>(MIGRATION_1_2)
   ```
4. ابنِ المشروع — مخطط الإصدار الجديد يُحفظ تلقائيًا في `app/schemas/`
   (قارن ملفَي JSON للإصدارين للتأكد من صحة الـ SQL).

المزامنة تتعامل مع الحقول الجديدة تلقائيًا: الحقول الناقصة في المستندات القديمة
تأخذ القيمة الافتراضية عند السحب، ولا حاجة لأي تعديل في `SyncEngine`.

## 2) إضافة شاشة جديدة

1. **الجدول** (إن لزم): Entity جديدة بحقول المزامنة الأربعة
   (`createdAt / updatedAt / isDeleted / isSynced`) + DAO فيه
   `pendingSync / markSynced / localUpdatedAt / wipe` + سجّلها في `AppDatabase`.
2. **المزامنة**: أضف اسم المجموعة في `FirestorePaths` وسطرًا واحدًا في
   `SyncEngine.tables()`.
3. **Repository** على نمط `PaymentRepository` (حفظ ← `isSynced=false` ← `syncNow`).
4. **الواجهة**: مجلد جديد تحت `ui/screens/` فيه Screen + ViewModel،
   ثم أضف Route في `ui/navigation/AppNavigation.kt`.

## 3) إضافة تقرير جديد

دالة واحدة في `ReportsRepository` + قيمة جديدة في `ReportKind` بشاشة التقارير.

## 4) طباعة PDF لاحقًا

المكان الطبيعي: وحدة جديدة `ui/screens/reports/pdf/` تستخدم
`android.graphics.pdf.PdfDocument` (بدون مكتبات خارجية) وتقرأ من
`ReportsRepository` نفسه — البيانات جاهزة كنماذج، ولن تحتاج لمس أي طبقة أخرى.

## 5) رفع إصدار التطبيق

في `app/build.gradle.kts` ارفع `versionCode` (رقم صحيح تصاعدي)
و`versionName` (نص للعرض). ثم أنشئ tag بصيغة `vX.Y.Z` لينشر GitHub Actions
الإصدار تلقائيًا.
