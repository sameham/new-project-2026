// lib/features/dashboard/providers/dashboard_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../database/dao/bookings_dao.dart';
import '../../../database/tables/bookings_table.dart';

final customerCountProvider = StreamProvider<int>((ref) {
  return ref.watch(databaseProvider).customersDao.watchCount();
});

final profitsProvider = StreamProvider<double>((ref) {
  return ref.watch(databaseProvider).bookingsDao.watchTotalProfits();
});

final monthProfitsProvider = StreamProvider<double>((ref) {
  return ref.watch(databaseProvider).bookingsDao.watchMonthProfits();
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

final totalDebtsProvider = StreamProvider<double>((ref) {
  return ref.watch(databaseProvider).customersDao.watchTotalDebts();
});

final bookingsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(databaseProvider).bookingsDao.watchCount();
});

final yearlyStatsProvider = StreamProvider.family<List<MonthlyStat>, int>((ref, year) {
  return ref.watch(databaseProvider).bookingsDao.watchYearlyStats(year);
});

final flightDashboardProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(databaseProvider).bookingsDao.watchFlightDashboardStats();
});
