// lib/features/reports/screens/sales_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
// Imports removed
import '../../../database/app_database.dart';
import '../../bookings/providers/bookings_providers.dart';

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  String _period = 'month'; // 'week', 'month', 'year'

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(allBookingsProvider);
    final fmt = NumberFormat('#,##0.00', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تقرير المبيعات'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _PeriodChip(label: 'أسبوع', value: 'week', groupValue: _period, onChanged: (v) => setState(() => _period = v)),
                const SizedBox(width: 8),
                _PeriodChip(label: 'شهر', value: 'month', groupValue: _period, onChanged: (v) => setState(() => _period = v)),
                const SizedBox(width: 8),
                _PeriodChip(label: 'سنة', value: 'year', groupValue: _period, onChanged: (v) => setState(() => _period = v)),
              ],
            ),
          ),
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (List<Booking> bookings) {
          // Filter by period
          final now = DateTime.now();
          DateTime startDate;
          if (_period == 'week') {
            startDate = now.subtract(const Duration(days: 7));
          } else if (_period == 'month') {
            startDate = DateTime(now.year, now.month, 1);
          } else {
            startDate = DateTime(now.year, 1, 1);
          }

          final filtered = bookings.where((Booking b) {
            final d = b.createdAt;
            return d.isAfter(startDate) || d.isAtSameMomentAs(startDate);
          }).toList();

          double totalSales = 0;
          double totalCost = 0;
          for (final Booking b in filtered) {
            totalSales += b.sellingPrice;
            totalCost += b.totalCost;
          }
          final totalProfit = totalSales - totalCost;

          // Prepare chart data
          Map<int, double> salesByDayOrMonth = {};
          for (final Booking b in filtered) {
            int key;
            if (_period == 'year') {
              key = b.createdAt.month;
            } else {
              key = b.createdAt.day;
            }
            salesByDayOrMonth[key] = (salesByDayOrMonth[key] ?? 0) + b.sellingPrice;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── KPI Summary ───────────────────────────────
              Row(children: [
                Expanded(child: _Kpi(label: 'المبيعات', amount: totalSales, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _Kpi(label: 'التكلفة', amount: totalCost, color: AppColors.error)),
                const SizedBox(width: 12),
                Expanded(child: _Kpi(label: 'الربح', amount: totalProfit, color: AppColors.success)),
              ]),
              const SizedBox(height: 24),

              // ── Chart ───────────────────────────────────────
              if (filtered.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('لا توجد مبيعات في هذه الفترة', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo')),
                ))
              else ...[
                Text('الرسم البياني للمبيعات', style: AppTextStyles.titleMedium),
                const SizedBox(height: 16),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: salesByDayOrMonth.values.isEmpty ? 100 : salesByDayOrMonth.values.reduce((a, b) => a > b ? a : b) * 1.2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(value.toInt().toString(), style: AppTextStyles.labelSmall),
                            ),
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: salesByDayOrMonth.entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value,
                              color: AppColors.primary,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // ── Breakdown ──────────────────────────────────
                Text('حجوزات الفترة', style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                ...filtered.map((Booking b) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.infoLight,
                      child: Icon(Icons.flight, color: AppColors.info, size: 20),
                    ),
                    title: Text(b.bookingNumber, style: AppTextStyles.titleSmall),
                    subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(b.createdAt), style: AppTextStyles.bodySmall),
                    trailing: Text('${fmt.format(b.sellingPrice)} ج.م',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _Kpi({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'ar');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 4),
        Text('${fmt.format(amount)}',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: color),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _PeriodChip({required this.label, required this.value, required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sel = value == groupValue;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontFamily: 'Cairo', color: sel ? Colors.white : AppColors.textPrimary)),
      selected: sel,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      onSelected: (_) => onChanged(value),
    );
  }
}
