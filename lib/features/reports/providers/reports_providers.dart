// lib/features/reports/providers/reports_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../database/dao/bookings_dao.dart';

final airlineStatsProvider = FutureProvider<List<AirlineStat>>((ref) {
  return ref.watch(databaseProvider).bookingsDao.watchAirlineStats().first;
});

final topDestinationsProvider = FutureProvider<List<DestinationStat>>((ref) {
  return ref.watch(databaseProvider).bookingsDao.getTopDestinations(10);
});

final topCustomersProvider = FutureProvider<List<CustomerRevenueStat>>((ref) {
  return ref.watch(databaseProvider).bookingsDao.getTopCustomers(10);
});

final airlineStatsStreamProvider = StreamProvider<List<AirlineStat>>((ref) {
  return ref.watch(databaseProvider).bookingsDao.watchAirlineStats();
});
