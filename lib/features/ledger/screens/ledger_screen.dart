// lib/features/ledger/screens/ledger_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/ledger_providers.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(allLedgerProvider);
    final fmt = NumberFormat('#,##0.00', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الدفتر المحاسبي')),
      body: ledgerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.book_outlined, size: 72, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('لا توجد قيود محاسبية', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('ستظهر هنا القيود عند إضافة مدفوعات وحجوزات',
                    style: TextStyle(color: AppColors.textHint, fontFamily: 'Cairo'),
                    textAlign: TextAlign.center),
              ]),
            );
          }

          final totalDebit  = entries.fold(0.0, (s, e) => s + e.debit);
          final totalCredit = entries.fold(0.0, (s, e) => s + e.credit);
          final netBalance  = totalCredit - totalDebit;

          return Column(
            children: [
              // ── Summary Header ─────────────────────────────
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  _LedgerStat('إجمالي المدين', totalDebit, AppColors.error),
                  const SizedBox(width: 12),
                  _LedgerStat('إجمالي الدائن', totalCredit, AppColors.success),
                  const SizedBox(width: 12),
                  _LedgerStat('الرصيد الصافي', netBalance, netBalance >= 0 ? AppColors.info : AppColors.error),
                ]),
              ),
              const Divider(height: 1),

              // ── Table Header ────────────────────────────────
              Container(
                color: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  const Expanded(flex: 2, child: Text('التاريخ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                  const Expanded(flex: 3, child: Text('البيان', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                  const Expanded(flex: 2, child: Text('مدين', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                  const Expanded(flex: 2, child: Text('دائن', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                  const Expanded(flex: 2, child: Text('الرصيد', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
                ]),
              ),

              // ── Entries ────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final isEven = i % 2 == 0;
                    return Container(
                      color: isEven ? AppColors.surface : AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            DateFormat('dd/MM/yy').format(e.entryDate),
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.description,
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (e.referenceType != null)
                              Text(e.referenceType!, style: AppTextStyles.labelSmall),
                          ]),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.debit > 0 ? fmt.format(e.debit) : '',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.credit > 0 ? fmt.format(e.credit) : '',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.success),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            fmt.format(e.balance),
                            style: TextStyle(
                              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600,
                              color: e.balance >= 0 ? AppColors.success : AppColors.error,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ]),
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

class _LedgerStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _LedgerStat(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'ar');
    return Expanded(
      child: Column(children: [
        Text('${fmt.format(amount)} ج.م',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
      ]),
    );
  }
}
