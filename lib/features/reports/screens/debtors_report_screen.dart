// lib/features/reports/screens/debtors_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/app_database.dart';
import '../../customers/providers/customers_providers.dart';

class DebtorsReportScreen extends ConsumerWidget {
  const DebtorsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(allCustomersProvider);
    final fmt = NumberFormat('#,##0.00', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تقرير المدينين')),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (List<Customer> customers) {
          final debtors = customers.where((Customer c) => c.balance < 0).toList()
            ..sort((Customer a, Customer b) => a.balance.compareTo(b.balance)); // most negative first

          final totalDebt = debtors.fold(0.0, (s, c) => s + c.balance.abs());

          if (debtors.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_outline, size: 72, color: AppColors.success),
                const SizedBox(height: 16),
                Text('لا يوجد عملاء مدينين', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('جميع حسابات العملاء مسددة', style: TextStyle(color: AppColors.textHint, fontFamily: 'Cairo')),
              ]),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(children: [
                  const Icon(Icons.money_off, color: AppColors.error, size: 32),
                  const SizedBox(height: 12),
                  Text('إجمالي الديون المستحقة', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text('${fmt.format(totalDebt)} ج.م',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.error)),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: debtors.length,
                  itemBuilder: (_, i) {
                    final c = debtors[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => context.push('/customers/${c.id}'),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.error.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppColors.error, size: 20),
                        ),
                        title: Text('${c.firstName} ${c.lastName}', style: AppTextStyles.titleSmall),
                        subtitle: Text(c.phone, style: AppTextStyles.bodySmall),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${fmt.format(c.balance.abs())} ج.م',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error)),
                          Text('مستحق', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
