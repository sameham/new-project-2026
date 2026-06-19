// lib/database/dao/expenses_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/expenses_table.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [Expenses, ExpenseCategories])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {

  ExpensesDao(super.db);

  Future<List<ExpenseCategory>> getAllCategories() =>
      select(expenseCategories).get();

  Stream<List<ExpenseCategory>> watchCategories() =>
      select(expenseCategories).watch();

  Future<ExpenseCategory?> getCategoryById(String id) =>
      (select(expenseCategories)..where((c) => c.id.equals(id)))
      .getSingleOrNull();

  Future<void> insertCategory(ExpenseCategoriesCompanion c) =>
      into(expenseCategories).insert(c);

  Stream<List<Expense>> watchAll() =>
      (select(expenses)
        ..orderBy([(e) => OrderingTerm.desc(e.expenseDate)]))
      .watch();

  Future<Expense?> getById(String id) =>
      (select(expenses)..where((e) => e.id.equals(id)))
      .getSingleOrNull();

  Future<List<Expense>> getByDateRange({
    required DateTime from, required DateTime to,
  }) =>
      (select(expenses)
        ..where((e) =>
            e.expenseDate.isBiggerOrEqualValue(from) &
            e.expenseDate.isSmallerOrEqualValue(to))
        ..orderBy([(e) => OrderingTerm.desc(e.expenseDate)]))
      .get();

  Future<double> getMonthTotal({int? year, int? month}) async {
    final now  = DateTime.now();
    final y    = year  ?? now.year;
    final m    = month ?? now.month;
    final from = DateTime(y, m, 1);
    final to   = DateTime(y, m + 1, 0, 23, 59, 59);
    final sum  = expenses.amount.sum();
    final query = selectOnly(expenses)
      ..addColumns([sum])
      ..where(
        expenses.expenseDate.isBiggerOrEqualValue(from) &
        expenses.expenseDate.isSmallerOrEqualValue(to),
      );
    return (await query.getSingle()).read(sum) ?? 0.0;
  }

  Stream<double> watchMonthTotal({int? year, int? month}) {
    final now  = DateTime.now();
    final y    = year  ?? now.year;
    final m    = month ?? now.month;
    final from = DateTime(y, m, 1);
    final to   = DateTime(y, m + 1, 0, 23, 59, 59);
    final sum  = expenses.amount.sum();
    final query = selectOnly(expenses)
      ..addColumns([sum])
      ..where(
        expenses.expenseDate.isBiggerOrEqualValue(from) &
        expenses.expenseDate.isSmallerOrEqualValue(to),
      );
    return query.watchSingle().map((row) => row.read(sum) ?? 0.0);
  }

  Future<void> insertExpense(ExpensesCompanion e) async {
    await into(expenses).insert(e);
    final row = await (select(expenses)..where((tbl) => tbl.id.equals(e.id.value))).getSingleOrNull();
    if (row != null) {
      await db.syncQueueDao.enqueue(targetTable: 'expenses', recordId: row.id, operation: 'INSERT', payload: row.toJson());
    }
  }

  Future<bool> updateExpense(ExpensesCompanion e) async {
    final res = await update(expenses).replace(e);
    if (res) {
      final row = await (select(expenses)..where((tbl) => tbl.id.equals(e.id.value))).getSingleOrNull();
      if (row != null) {
        await db.syncQueueDao.enqueue(targetTable: 'expenses', recordId: row.id, operation: 'UPDATE', payload: row.toJson());
      }
    }
    return res;
  }

  Future<int> deleteExpense(String id) async {
    await db.syncQueueDao.enqueue(targetTable: 'expenses', recordId: id, operation: 'DELETE', payload: {});
    return (delete(expenses)..where((e) => e.id.equals(id))).go();
  }

  Future<void> markSynced(String id) async =>
      (update(expenses)..where((e) => e.id.equals(id)))
          .write(ExpensesCompanion(
            syncStatus: const Value('synced'),
            syncedAt:   Value(DateTime.now()),
          ));
}
