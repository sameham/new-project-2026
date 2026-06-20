// lib/database/dao/bookings_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/bookings_table.dart';

part 'bookings_dao.g.dart';

@DriftAccessor(tables: [Bookings])
class BookingsDao extends DatabaseAccessor<AppDatabase>
    with _$BookingsDaoMixin {

  BookingsDao(super.db);

  Stream<List<Booking>> watchAll() =>
      (select(bookings)
        ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
      .watch();

  Future<Booking?> getById(String id) =>
      (select(bookings)..where((b) => b.id.equals(id)))
      .getSingleOrNull();

  Stream<Booking?> watchById(String id) =>
      (select(bookings)..where((b) => b.id.equals(id)))
      .watchSingleOrNull();

  Future<List<Booking>> getByCustomer(String customerId) =>
      (select(bookings)
        ..where((b) => b.customerId.equals(customerId)))
      .get();

  Stream<List<Booking>> watchByCustomer(String customerId) =>
      (select(bookings)
        ..where((b) => b.customerId.equals(customerId)))
      .watch();

  Stream<int> watchCount() {
    final count = bookings.id.count();
    final q = selectOnly(bookings)..addColumns([count]);
    return q.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<List<Booking>> getUpcoming() async {
    final now     = DateTime.now();
    final cutoff  = now.add(const Duration(hours: 48));
    return (select(bookings)
      ..where((b) =>
          b.departureDate.isBiggerOrEqualValue(now) &
          b.departureDate.isSmallerOrEqualValue(cutoff) &
          b.status.equals('confirmed')))
    .get();
  }

  Stream<List<Booking>> watchUpcoming() {
    final now     = DateTime.now();
    final cutoff  = now.add(const Duration(hours: 48));
    return (select(bookings)
      ..where((b) =>
          b.departureDate.isBiggerOrEqualValue(now) &
          b.departureDate.isSmallerOrEqualValue(cutoff) &
          b.status.equals('confirmed')))
    .watch();
  }

  Future<Map<String, int>> getStatusCounts() async {
    final rows = await select(bookings).get();
    final map  = <String, int>{};
    for (final b in rows) {
      map[b.status] = (map[b.status] ?? 0) + 1;
    }
    return map;
  }

  Stream<Map<String, int>> watchStatusCounts() {
    return select(bookings).watch().map((rows) {
      final map  = <String, int>{};
      for (final b in rows) {
        map[b.status] = (map[b.status] ?? 0) + 1;
      }
      return map;
    });
  }

  Future<double> getTotalRevenue({DateTime? from, DateTime? to}) async {
    final sum   = bookings.sellingPrice.sum();
    final query = selectOnly(bookings)..addColumns([sum]);
    if (from != null) query.where(bookings.createdAt.isBiggerOrEqualValue(from));
    if (to   != null) query.where(bookings.createdAt.isSmallerOrEqualValue(to));
    return (await query.getSingle()).read(sum) ?? 0.0;
  }

  Future<double> getTotalProfit({DateTime? from, DateTime? to}) async {
    final rows = await select(bookings).get();
    return rows.fold<double>(0.0, (s, b) => s + (b.sellingPrice - b.totalCost));
  }

  Stream<double> watchTotalProfits() {
    final profitSum = CustomExpression<double>('SUM(selling_price - total_cost)');
    final q = selectOnly(bookings)..addColumns([profitSum]);
    return q.watchSingle().map((row) => row.read(profitSum) ?? 0.0);
  }

  Stream<double> watchMonthProfits() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final profitSum = CustomExpression<double>('SUM(selling_price - total_cost)');
    final q = selectOnly(bookings)
      ..addColumns([profitSum])
      ..where(bookings.createdAt.isBiggerOrEqualValue(start));
    return q.watchSingle().map((row) => row.read(profitSum) ?? 0.0);
  }

  Stream<List<MonthlyStat>> watchYearlyStats(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);

    return (select(bookings)..where((b) => b.createdAt.isBetweenValues(start, end)))
      .watch()
      .map((rows) {
        final map = <int, MonthlyStat>{};
        for (int i = 1; i <= 12; i++) {
          map[i] = MonthlyStat(i, 0, 0);
        }
        for (final row in rows) {
          final m = row.createdAt.month;
          final rev = map[m]!.revenue + row.sellingPrice;
          final prof = map[m]!.profit + (row.sellingPrice - row.totalCost);
          map[m] = MonthlyStat(m, rev, prof);
        }
        return map.values.toList()..sort((a, b) => a.month.compareTo(b.month));
      });
  }

  Stream<Map<String, int>> watchFlightDashboardStats() {
    final now = DateTime.now();
    return (select(bookings)..where((b) => b.status.equals('pending') | b.status.equals('confirmed')))
      .watch()
      .map((rows) {
        int within24 = 0;
        int within48 = 0;
        int needsFollowup = 0;
        for (final row in rows) {
          if (row.status == 'pending') needsFollowup++;
          if (row.departureDate != null) {
            final diff = row.departureDate!.difference(now).inHours;
            if (diff >= 0 && diff <= 24) within24++;
            if (diff > 24 && diff <= 48) within48++;
          }
        }
        return {
          '24h': within24,
          '48h': within48,
          'followup': needsFollowup,
        };
      });
  }

  Future<void> insertBooking(BookingsCompanion b) async {
    await into(bookings).insert(b);
    final row = await (select(bookings)..where((tbl) => tbl.id.equals(b.id.value))).getSingleOrNull();
    if (row != null) {
      await db.syncQueueDao.enqueue(targetTable: 'bookings', recordId: row.id, operation: 'INSERT', payload: row.toJson());
    }
  }

  Future<bool> updateBooking(BookingsCompanion b) async {
    final res = await update(bookings).replace(b);
    if (res) {
      final row = await (select(bookings)..where((tbl) => tbl.id.equals(b.id.value))).getSingleOrNull();
      if (row != null) {
        await db.syncQueueDao.enqueue(targetTable: 'bookings', recordId: row.id, operation: 'UPDATE', payload: row.toJson());
      }
    }
    return res;
  }

  Future<void> addPaymentToBooking(String id, double amount) async {
    final b = await getById(id);
    if (b == null) return;
    final newPaid = b.paidAmount + amount;
    await (update(bookings)..where((tbl) => tbl.id.equals(id))).write(BookingsCompanion(paidAmount: Value(newPaid)));
    final row = await (select(bookings)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row != null) {
      await db.syncQueueDao.enqueue(targetTable: 'bookings', recordId: row.id, operation: 'UPDATE', payload: row.toJson());
    }
  }

  Future<int> deleteBooking(String id) async {
    await db.syncQueueDao.enqueue(targetTable: 'bookings', recordId: id, operation: 'DELETE', payload: {});
    return (delete(bookings)..where((b) => b.id.equals(id))).go();
  }

  Future<void> markSynced(String id) async =>
      (update(bookings)..where((b) => b.id.equals(id)))
          .write(BookingsCompanion(
            syncStatus: const Value('synced'),
            syncedAt:   Value(DateTime.now()),
          ));

  Stream<double> watchTotalRevenue() {
    final sum = bookings.sellingPrice.sum();
    final q = selectOnly(bookings)..addColumns([sum]);
    return q.watchSingle().map((row) => row.read(sum) ?? 0.0);
  }

  Stream<List<AirlineStat>> watchAirlineStats() {
    return watchAll().map((rows) {
      final map = <String, AirlineStat>{};
      for (final b in rows.where((r) => r.airlineName != null && r.airlineName!.isNotEmpty)) {
        final name = b.airlineName!;
        final s = map[name] ?? AirlineStat(name, 0, 0, 0);
        map[name] = AirlineStat(
          name, s.count + 1,
          s.revenue + b.sellingPrice,
          s.profit + (b.sellingPrice - b.totalCost),
        );
      }
      final list = map.values.toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));
      return list;
    });
  }

  Future<List<CustomerRevenueStat>> getTopCustomers(int limit) async {
    final rows = await select(bookings).get();
    final map = <String, CustomerRevenueStat>{};
    for (final b in rows) {
      final s = map[b.customerId] ?? CustomerRevenueStat(b.customerId, 0, 0, 0);
      map[b.customerId] = CustomerRevenueStat(
        b.customerId,
        s.bookingCount + 1,
        s.totalRevenue + b.sellingPrice,
        s.totalProfit + (b.sellingPrice - b.totalCost),
      );
    }
    final list = map.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    return list.take(limit).toList();
  }

  Future<List<DestinationStat>> getTopDestinations(int limit) async {
    final rows = await select(bookings).get();
    final map = <String, DestinationStat>{};
    for (final b in rows.where((r) => r.destination != null && r.destination!.isNotEmpty)) {
      final d = b.destination!;
      final s = map[d] ?? DestinationStat(d, 0);
      map[d] = DestinationStat(d, s.count + 1);
    }
    final list = map.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(limit).toList();
  }
}

class MonthlyStat {
  final int month;
  final double revenue;
  final double profit;
  MonthlyStat(this.month, this.revenue, this.profit);
}

class AirlineStat {
  final String airline;
  final int count;
  final double revenue;
  final double profit;
  AirlineStat(this.airline, this.count, this.revenue, this.profit);
}

class CustomerRevenueStat {
  final String customerId;
  final int bookingCount;
  final double totalRevenue;
  final double totalProfit;
  CustomerRevenueStat(this.customerId, this.bookingCount, this.totalRevenue, this.totalProfit);
}

class DestinationStat {
  final String destination;
  final int count;
  DestinationStat(this.destination, this.count);
}
