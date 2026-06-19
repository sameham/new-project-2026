// lib/features/reports/screens/reports_menu_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ReportsMenuScreen extends ConsumerWidget {
  const ReportsMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReportCard(
            icon: Icons.trending_up,
            title: 'تقرير المبيعات',
            subtitle: 'الإيرادات والأرباح حسب الفترة الزمنية',
            color: AppColors.primary,
            onTap: () => context.push('/reports/sales'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.money_off,
            title: 'تقرير المدينين',
            subtitle: 'قائمة العملاء أصحاب الأرصدة المدينة',
            color: AppColors.error,
            onTap: () => context.push('/reports/debtors'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.receipt_long,
            title: 'تقرير المصروفات',
            subtitle: 'مصروفات المكتب حسب الفئة',
            color: AppColors.warning,
            onTap: () => context.push('/expenses'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.book,
            title: 'الدفتر المحاسبي',
            subtitle: 'القيود المحاسبية والرصيد الجاري',
            color: AppColors.secondary,
            onTap: () => context.push('/ledger'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.flight,
            title: 'تقرير الحجوزات',
            subtitle: 'ملخص الحجوزات حسب الحالة والنوع',
            color: AppColors.info,
            onTap: () => context.go('/bookings'),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ])),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ]),
        ),
      ),
    );
  }
}
