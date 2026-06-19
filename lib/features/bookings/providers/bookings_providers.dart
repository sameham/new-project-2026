// lib/features/bookings/providers/bookings_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/bookings_table.dart';

final allBookingsProvider = StreamProvider<List<Booking>>((ref) {
  return ref.watch(databaseProvider).bookingsDao.watchAll();
});

final bookingStatusFilterProvider = StateProvider<String?>((ref) => null);

final filteredBookingsProvider = Provider<AsyncValue<List<Booking>>>((ref) {
  final all = ref.watch(allBookingsProvider);
  final filter = ref.watch(bookingStatusFilterProvider);
  if (filter == null) return all;
  return all.whenData(
      (list) => list.where((b) => b.status == filter).toList());
});

final bookingByIdProvider = StreamProvider.family<Booking?, String>((ref, id) {
  return ref.watch(databaseProvider).bookingsDao.watchById(id);
});

final bookingsByCustomerProvider =
    StreamProvider.family<List<Booking>, String>((ref, customerId) {
  return ref.watch(databaseProvider).bookingsDao.watchByCustomer(customerId);
});
