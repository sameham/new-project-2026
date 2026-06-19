// lib/features/expenses/screens/expenses_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/expenses_table.dart';
import '../providers/expenses_providers.dart';

class ExpensesListScreen extends ConsumerStatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  ConsumerState<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends ConsumerState<ExpensesListScreen> {
  // Quick add form state
  final _descCtrl    = TextEditingController();
  final _amountCtrl  = TextEditingController();
  String? _selCatId;
  String _method     = 'cash';
  DateTime _date     = DateTime.now();
  bool _showForm     = false;
  bool _saving       = false;

  Future<void> _quickSave(List<ExpenseCategory> categories) async {
    if (_descCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty || _selCatId == null) return;
    setState(() => _saving = true);
    final db  = ref.read(databaseProvider);
    final now = DateTime.now();
    try {
      await db.expensesDao.insertExpense(ExpensesCompanion.insert(
        id:            const Uuid().v4(),
        categoryId:    _selCatId!,
        expenseNumber: '${AppConstants.prefixExpense}${now.millisecondsSinceEpoch.toString().substring(6)}',
        description:   _descCtrl.text.trim(),
        amount:        double.tryParse(_amountCtrl.text.trim()) ?? 0,
        expenseDate:   _date,
        paymentMethod: Value(_method),
      ));
      _descCtrl.clear();
      _amountCtrl.clear();
      setState(() { _showForm = false; _saving = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة المصروف ✅'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete(Expense e) async {
    await ref.read(databaseProvider).expensesDao.deleteExpense(e.id);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync    = ref.watch(allExpensesProvider);
    final categoriesAsync  = ref.watch(expenseCategoriesProvider);
    final fmt = NumberFormat('#,##0.00', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المصروفات'),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close : Icons.add),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: Column(children: [
        // ── Quick Add Form ──────────────────────────────────
        if (_showForm)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(14),
            child: categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
              data: (cats) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('إضافة مصروف', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
                const SizedBox(height: 10),
                // Category
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: cats.map((c) => GestureDetector(
                      onTap: () => setState(() => _selCatId = c.id),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selCatId == c.id ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _selCatId == c.id ? AppColors.primary : AppColors.border),
                        ),
                        child: Text('${c.icon ?? ''} ${c.nameAr}',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12,
                                color: _selCatId == c.id ? Colors.white : AppColors.textPrimary)),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _descCtrl,
                      decoration: _inputDec('الوصف *'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDec('المبلغ *'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: () => setState(() { _showForm = false; }), child: const Text('إلغاء')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : () => _quickSave(cats),
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save, size: 16),
                    label: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ]),
              ]),
            ),
          ),

        // ── Expenses List ───────────────────────────────────
        Expanded(
          child: expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
            data: (expenses) {
              if (expenses.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.receipt_long_outlined, size: 72, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text('لا توجد مصروفات', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showForm = true),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة مصروف', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ]),
                );
              }

              final totalThisMonth = expenses
                  .where((e) {
                    final now = DateTime.now();
                    return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
                  })
                  .fold(0.0, (s, e) => s + e.amount);

              return Column(children: [
                // Month total banner
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_month, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text('مصروفات هذا الشهر', style: AppTextStyles.bodyMedium),
                    const Spacer(),
                    Text('${fmt.format(totalThisMonth)} ج.م',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 16,
                            fontWeight: FontWeight.w700, color: AppColors.error)),
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: expenses.length,
                    itemBuilder: (_, i) {
                      final exp = expenses[i];
                      return Dismissible(
                        key: Key(exp.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete, color: AppColors.error),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('حذف المصروف', style: TextStyle(fontFamily: 'Cairo')),
                              content: const Text('هل تريد حذف هذا المصروف؟', style: TextStyle(fontFamily: 'Cairo')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                TextButton(onPressed: () => Navigator.pop(context, true),
                                    child: const Text('حذف', style: TextStyle(color: AppColors.error))),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (_) => _delete(exp),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.error.withOpacity(0.1),
                              child: const Icon(Icons.receipt_long, color: AppColors.error, size: 20),
                            ),
                            title: Text(exp.description, style: AppTextStyles.titleSmall),
                            subtitle: Text(
                              '${DateFormat('dd/MM/yyyy').format(exp.expenseDate)} • ${exp.expenseNumber}',
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: Text(
                              '${fmt.format(exp.amount)} ج.م',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14,
                                  fontWeight: FontWeight.w600, color: AppColors.error),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );
}
