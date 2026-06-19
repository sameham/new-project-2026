// lib/database/app_database.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'tables/customers_table.dart';
import 'tables/bookings_table.dart';
import 'tables/payments_table.dart';
import 'tables/expenses_table.dart';
import 'tables/ledger_table.dart';
import 'tables/sync_queue_table.dart';
import 'dao/customers_dao.dart';
import 'dao/bookings_dao.dart';
import 'dao/payments_dao.dart';
import 'dao/expenses_dao.dart';
import 'dao/ledger_dao.dart';
import 'dao/sync_queue_dao.dart';
import 'dao/settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Customers,
    Bookings,
    Payments,
    ExpenseCategories,
    Expenses,
    LedgerEntries,
    SyncQueue,
    Settings,
  ],
  daos: [
    CustomersDao,
    BookingsDao,
    PaymentsDao,
    ExpensesDao,
    LedgerDao,
    SyncQueueDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _insertDefaultData();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<void> _insertDefaultData() async {
    const defaultCategories = [
      ('rent',        'إيجار المكتب',    '🏢', '#1565C0'),
      ('utilities',   'كهرباء وإنترنت',  '💡', '#0288D1'),
      ('salaries',    'رواتب',           '👥', '#2E7D32'),
      ('marketing',   'تسويق وإعلانات',  '📢', '#F57F17'),
      ('supplies',    'مستلزمات مكتبية', '🖊', '#6A1B9A'),
      ('travel',      'مصروفات سفر',     '✈', '#0277BD'),
      ('maintenance', 'صيانة',           '🔧', '#E65100'),
      ('taxes',       'ضرائب ورسوم',     '📋', '#C62828'),
      ('other',       'أخرى',            '💼', '#757575'),
    ];

    for (final cat in defaultCategories) {
      await expensesDao.insertCategory(
        ExpenseCategoriesCompanion.insert(
          id:        const Uuid().v4(),
          name:      cat.$1,
          nameAr:    cat.$2,
          icon:      Value(cat.$3),
          color:     Value(cat.$4),
          isDefault: const Value(true),
        ),
      );
    }

    const defaults = {
      'agency_name':      'Sameh Abdullah Travel & Tourism',
      'agency_name_ar':   'وكالة سامح عبدالله للسفر والسياحة',
      'agency_address':   'Cairo, Egypt',
      'default_currency': 'EGP',
      'auto_sync':        'true',
      'sync_interval':    '5',
      'theme_mode':       'light',
      'language':         'ar',
    };

    for (final entry in defaults.entries) {
      await settingsDao.set(entry.key, entry.value);
    }
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(
        p.join(dbFolder.path, 'elmahdi_travel.db'),
      );
      return NativeDatabase.createInBackground(file);
    });
  }
}

@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) => AppDatabase();
