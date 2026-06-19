// lib/features/payments/screens/payment_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/payments_providers.dart';
import '../../customers/providers/customers_providers.dart';

class PaymentDetailScreen extends ConsumerWidget {
  final String paymentId;
  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(paymentByIdProvider(paymentId));
    final fmt = NumberFormat('#,##0.00', 'ar');

    return paymentAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('خطأ: $e'))),
      data: (payment) {
        if (payment == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('الدفعة غير موجودة')));
        }

        final isIn = payment.direction == 'in';
        final color = isIn ? AppColors.success : AppColors.error;
        final customerAsync = ref.watch(customerByIdProvider(payment.customerId));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text(payment.paymentNumber)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Amount Banner ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${isIn ? '+' : '-'}${fmt.format(payment.amount)} ${payment.currency}',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w700, color: color),
                  ),
                  Text(isIn ? 'دفعة وارد (قبض)' : 'دفعة صادر (دفع)',
                      style: AppTextStyles.bodyMedium.copyWith(color: color)),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Details ────────────────────────────────────
              _card(children: [
                const Text('تفاصيل الدفعة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                const Divider(),
                _row(Icons.tag, 'رقم الدفعة', payment.paymentNumber),
                _row(Icons.calendar_today, 'تاريخ الدفع',
                    DateFormat('dd MMMM yyyy', 'ar').format(payment.paymentDate)),
                _row(Icons.payment, 'طريقة الدفع', _methodLabel(payment.paymentMethod)),
                if (payment.referenceNumber != null)
                  _row(Icons.confirmation_number, 'رقم المرجع', payment.referenceNumber!),
                _row(Icons.person, 'العميل',
                    customerAsync.when(
                      data: (c) => c != null ? '${c.firstName} ${c.lastName}' : payment.customerId,
                      loading: () => '...',
                      error: (_, __) => payment.customerId,
                    )),
              ]),
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _card(children: [
                  _row(Icons.note, 'ملاحظات', payment.notes!),
                ]),
              ],
              const SizedBox(height: 12),
              _card(children: [
                _row(Icons.access_time, 'تاريخ الإنشاء',
                    DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
                textAlign: TextAlign.end),
          ),
        ]),
      );

  String _methodLabel(String m) {
    const map = {'cash': 'نقداً', 'bank_transfer': 'تحويل بنكي',
      'credit_card': 'بطاقة ائتمان', 'instapay': 'إنستاباي',
      'vodafone_cash': 'فودافون كاش', 'other': 'أخرى'};
    return map[m] ?? m;
  }
}
