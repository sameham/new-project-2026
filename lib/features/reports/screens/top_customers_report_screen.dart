// lib/features/reports/screens/top_customers_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/dao/bookings_dao.dart';
import '../providers/reports_providers.dart';

class TopCustomersReportScreen extends ConsumerWidget {
  const TopCustomersReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(topCustomersProvider);
    final fmt = NumberFormat('#,##0', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('أفضل العملاء')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (stats) {
          if (stats.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('لا توجد بيانات عملاء بعد', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
              ]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stats.length,
            itemBuilder: (_, i) {
              final s = stats[i];
              final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}';

              return GestureDetector(
                onTap: () => context.push('/customers/${s.customerId}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: i < 3 ? AppColors.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: i < 3 ? AppColors.primary.withOpacity(0.3) : AppColors.border),
                  ),
                  child: Row(children: [
                    Text(medal, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.customerId, style: AppTextStyles.cardTitle),
                        Text('${s.bookingCount} حجوزات', style: AppTextStyles.cardSubtitle),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${fmt.format(s.totalRevenue)} ج.م',
                          style: AppTextStyles.amountSmall.copyWith(color: AppColors.primary)),
                      Text('ربح: ${fmt.format(s.totalProfit)} ج.م',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                    ]),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
