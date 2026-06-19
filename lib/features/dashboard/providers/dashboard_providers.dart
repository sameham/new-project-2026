// lib/features/dashboard/providers/dashboard_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/bookings_table.dart';

final customerCountProvider = StreamProvider<int>((ref) {
  return ref.watch(databaseProvider).customersDao.watchCount();
});

final todayRevenueProvider = StreamProvider<double>((ref) {
  return ref.watch(databaseProvider).paymentsDao.watchTodayTotal();
});

final monthRevenueProvider = StreamProvider<double>((ref) {
  return ref.watch(databaseProvider).paymentsDao.watchMonthTotal();
});

final upcomingBookingsProvider = StreamProvider<List<Booking>>((ref) {
  return ref.watch(databaseProvider).bookingsDao.watchUpcoming();
});

final bookingStatusCountsProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(databaseProvider).bookingsDao.watchStatusCounts();
});

final monthExpensesProvider = StreamProvider<double>((ref) {
  return ref.watch(databaseProvider).expensesDao.watchMonthTotal();
});
