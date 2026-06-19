// lib/features/payments/screens/payments_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/tables/payments_table.dart';
import '../../../database/app_database.dart';
import '../providers/payments_providers.dart';

class PaymentsListScreen extends ConsumerWidget {
  const PaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allPaymentsProvider);
    final fmt = NumberFormat('#,##0.00', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المدفوعات')),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (payments) {
          final totalIn  = payments.where((p) => p.direction == 'in').fold(0.0,  (s, p) => s + p.amount);
          final totalOut = payments.where((p) => p.direction == 'out').fold(0.0, (s, p) => s + p.amount);

          return Column(
            children: [
              // ── Summary ─────────────────────────────────────
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: _SummaryCard(
                    label: 'إجمالي الوارد',
                    amount: totalIn,
                    color: AppColors.success,
                    icon: Icons.arrow_downward,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: 'إجمالي الصادر',
                    amount: totalOut,
                    color: AppColors.error,
                    icon: Icons.arrow_upward,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: 'الصافي',
                    amount: totalIn - totalOut,
                    color: (totalIn - totalOut) >= 0 ? AppColors.info : AppColors.error,
                    icon: Icons.account_balance,
                  )),
                ]),
              ),
              const Divider(height: 1),
              // ── List ────────────────────────────────────────
              Expanded(
                child: payments.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.payment_outlined, size: 72, color: AppColors.textHint),
                          const SizedBox(height: 16),
                          Text('لا توجد مدفوعات', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: payments.length,
                        itemBuilder: (_, i) => _PaymentTile(payment: payments[i], fmt: fmt),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/payments/new'),
        icon: const Icon(Icons.add_card),
        label: const Text('تسجيل دفعة'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.amount, required this.color, required this.icon});

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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text('${fmt.format(amount)} ج.م',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: color),
            textAlign: TextAlign.center),
        Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
      ]),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final NumberFormat fmt;

  const _PaymentTile({required this.payment, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isIn = payment.direction == 'in';
    final color = isIn ? AppColors.success : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/payments/${payment.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(payment.paymentNumber, style: AppTextStyles.titleSmall),
              const SizedBox(height: 2),
              Text(
                '${DateFormat('dd/MM/yyyy').format(payment.paymentDate)} • ${_methodLabel(payment.paymentMethod)}',
                style: AppTextStyles.bodySmall,
              ),
              if (payment.referenceNumber != null)
                Text('مرجع: ${payment.referenceNumber!}', style: AppTextStyles.labelSmall),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '${isIn ? '+' : '-'}${fmt.format(payment.amount)} ج.م',
                style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 15,
                    fontWeight: FontWeight.w700, color: color),
              ),
              Text(payment.currency,
                  style: AppTextStyles.labelSmall.copyWith(color: color.withOpacity(0.7))),
            ]),
          ]),
        ),
      ),
    );
  }

  String _methodLabel(String m) {
    const map = {'cash': 'نقداً', 'bank_transfer': 'تحويل بنكي',
      'credit_card': 'بطاقة', 'instapay': 'إنستاباي',
      'vodafone_cash': 'فودافون كاش', 'other': 'أخرى'};
    return map[m] ?? m;
  }
}
