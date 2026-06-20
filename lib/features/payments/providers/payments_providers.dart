// lib/features/payments/providers/payments_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/payments_table.dart';

final allPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(databaseProvider).paymentsDao.watchAll();
});

final paymentsByCustomerProvider =
    StreamProvider.family<List<Payment>, String>((ref, customerId) {
  return ref.watch(databaseProvider).paymentsDao.watchByCustomer(customerId);
});

final paymentsByCustomerStreamProvider =
    StreamProvider.family<List<Payment>, String>((ref, customerId) {
  return ref
      .watch(databaseProvider)
      .paymentsDao
      .watchByCustomer(customerId);
});

final paymentByIdProvider = FutureProvider.family<Payment?, String>((ref, id) {
  return ref.watch(databaseProvider).paymentsDao.getById(id);
});

final paymentsByBookingProvider =
    StreamProvider.family<List<Payment>, String>((ref, bookingId) {
  return ref.watch(databaseProvider).paymentsDao.watchByBooking(bookingId);
});
