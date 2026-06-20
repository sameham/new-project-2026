// lib/features/reports/screens/airline_performance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/dao/bookings_dao.dart';
import '../providers/reports_providers.dart';

class AirlinePerformanceScreen extends ConsumerWidget {
  const AirlinePerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(airlineStatsStreamProvider);
    final fmt = NumberFormat('#,##0', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('أداء شركات الطيران')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (stats) {
          if (stats.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.flight, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('لا توجد بيانات طيران بعد', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
              ]),
            );
          }

          final totalRev = stats.fold<double>(0, (s, a) => s + a.revenue);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stats.length,
            itemBuilder: (_, i) {
              final a = stats[i];
              final pct = totalRev > 0 ? a.revenue / totalRev : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.airline, style: AppTextStyles.cardTitle),
                        Text('${a.count} حجز', style: AppTextStyles.cardSubtitle),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${fmt.format(a.revenue)} ج.م',
                          style: AppTextStyles.amountSmall.copyWith(color: AppColors.primary)),
                      Text('ربح: ${fmt.format(a.profit)} ج.م',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                    ]),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(pct * 100).toStringAsFixed(1)}%',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                  ]),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
