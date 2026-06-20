// lib/features/expenses/providers/expenses_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/expenses_table.dart';

final allExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(databaseProvider).expensesDao.watchAll();
});

final expenseCategoriesProvider =
    StreamProvider<List<ExpenseCategory>>((ref) {
  return ref.watch(databaseProvider).expensesDao.watchCategories();
});

final selectedExpenseCategoryProvider = StateProvider<String?>((ref) => null);

final monthExpensesProvider = StreamProvider<double>((ref) {
  return ref.watch(databaseProvider).expensesDao.watchMonthTotal();
});
