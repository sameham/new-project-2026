// lib/features/ledger/providers/ledger_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/ledger_table.dart';

final allLedgerProvider = StreamProvider<List<LedgerEntry>>((ref) {
  return ref.watch(databaseProvider).ledgerDao.watchAll();
});
