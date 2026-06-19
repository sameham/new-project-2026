// lib/features/customers/providers/customers_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/customers_table.dart';

final allCustomersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(databaseProvider).customersDao.watchAllCustomers();
});

final customerSearchProvider = StateProvider<String>((ref) => '');

final filteredCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final all = ref.watch(allCustomersProvider);
  final query = ref.watch(customerSearchProvider).trim().toLowerCase();
  if (query.isEmpty) return all;
  return all.whenData((list) => list.where((c) {
        final name = '${c.firstName} ${c.lastName}'.toLowerCase();
        return name.contains(query) ||
            c.phone.contains(query) ||
            (c.passportNumber?.toLowerCase().contains(query) ?? false);
      }).toList());
});

final customerByIdProvider =
    StreamProvider.family<Customer?, String>((ref, id) {
  return ref.watch(databaseProvider).customersDao.watchCustomerById(id);
});
