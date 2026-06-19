import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/dashboard_providers.dart';
import 'package:intl/intl.dart';

class FinanceDashboardScreen extends ConsumerWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profits = ref.watch(profitsProvider);
    final totalDebts = ref.watch(totalDebtsProvider);
    final fmt = NumberFormat('#,##0', 'ar');

    return Scaffold(
      appBar: AppBar(
        title: const Text('المالية', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نظرة عامة', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildFinanceCard('الأرباح', profits.asData?.value != null ? '${fmt.format(profits.asData!.value)} ج.م' : '-', Icons.trending_up, AppColors.success),
                _buildFinanceCard('المصروفات', '0 ج.م', Icons.money_off, AppColors.error),
                _buildFinanceCard('المستحقات', totalDebts.asData?.value != null ? '${fmt.format(totalDebts.asData!.value)} ج.م' : '-', Icons.account_balance_wallet, AppColors.warning),
                _buildFinanceCard('الاسترجاعات', '0 ج.م', Icons.assignment_return, AppColors.info),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value, style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
