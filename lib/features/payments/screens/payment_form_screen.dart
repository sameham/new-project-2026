// lib/features/payments/screens/payment_form_screen.dart

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
import '../../../database/tables/customers_table.dart';
import '../../../database/tables/bookings_table.dart';
import '../../../database/tables/payments_table.dart';
import '../../customers/providers/customers_providers.dart';
import '../../bookings/providers/bookings_providers.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey     = GlobalKey<FormState>();
  bool _loading      = false;
  String _direction  = 'in';
  String _method     = 'cash';
  String _currency   = 'EGP';
  DateTime _date     = DateTime.now();

  Customer? _selectedCustomer;
  Booking?  _selectedBooking;

  final _amountCtrl    = TextEditingController();
  final _refCtrl       = TextEditingController();
  final _notesCtrl     = TextEditingController();

  List<Booking> _customerBookings = [];

  Future<void> _loadBookings(String customerId) async {
    final bookings = await ref.read(databaseProvider).bookingsDao.getByCustomer(customerId);
    setState(() {
      _customerBookings = bookings;
      _selectedBooking  = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العميل'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _loading = true);
    final db  = ref.read(databaseProvider);
    final now = DateTime.now();

    try {
      final id     = const Uuid().v4();
      final number = '${AppConstants.prefixPayment}${now.millisecondsSinceEpoch.toString().substring(6)}';
      final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

      await db.paymentsDao.insertPayment(PaymentsCompanion.insert(
        id:              id,
        customerId:      _selectedCustomer!.id,
        bookingId:       Value(_selectedBooking?.id),
        paymentNumber:   number,
        amount:          amount,
        currency:        Value(_currency),
        paymentDate:     _date,
        paymentMethod:   _method,
        referenceNumber: Value(_refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim()),
        direction:       Value(_direction),
        notes:           Value(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()),
      ));

      // Update customer balance
      final sign   = _direction == 'in' ? 1 : -1;
      final newBal = _selectedCustomer!.balance - (sign * amount);
      await db.customersDao.updateBalance(_selectedCustomer!.id, newBal);

      // Update booking paid amount if linked
      if (_selectedBooking != null && _direction == 'in') {
        await db.bookingsDao.addPaymentToBooking(_selectedBooking!.id, amount);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الدفعة ✅'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تسجيل دفعة'),
        actions: [
          if (_loading)
            const Padding(padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('حفظ', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Direction ─────────────────────────────────────
            _SectionHeader('نوع الحركة'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _DirectionChip(
                label: 'وارد (قبض)',
                icon: Icons.arrow_downward,
                color: AppColors.success,
                selected: _direction == 'in',
                onTap: () => setState(() => _direction = 'in'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _DirectionChip(
                label: 'صادر (دفع)',
                icon: Icons.arrow_upward,
                color: AppColors.error,
                selected: _direction == 'out',
                onTap: () => setState(() => _direction = 'out'),
              )),
            ]),
            const SizedBox(height: 20),

            // ── Customer ──────────────────────────────────────
            _SectionHeader('العميل'),
            const SizedBox(height: 10),
            customersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
              data: (customers) => DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                decoration: _inputDec('اختر العميل *'),
                hint: const Text('اختر العميل', style: TextStyle(fontFamily: 'Cairo')),
                items: customers.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text('${c.firstName} ${c.lastName} — ${c.phone}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                )).toList(),
                onChanged: (c) {
                  setState(() => _selectedCustomer = c);
                  if (c != null) _loadBookings(c.id);
                },
                validator: (v) => v == null ? 'يرجى اختيار العميل' : null,
              ),
            ),
            const SizedBox(height: 10),
            if (_customerBookings.isNotEmpty) ...[
              DropdownButtonFormField<Booking>(
                value: _selectedBooking,
                decoration: _inputDec('الحجز المرتبط (اختياري)'),
                hint: const Text('اختر حجز (اختياري)', style: TextStyle(fontFamily: 'Cairo')),
                items: [
                  const DropdownMenuItem<Booking>(value: null, child: Text('بدون حجز', style: TextStyle(fontFamily: 'Cairo'))),
                  ..._customerBookings.map((b) => DropdownMenuItem(
                    value: b,
                    child: Text('${b.bookingNumber} — ${b.destination ?? ''}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                  )),
                ],
                onChanged: (b) => setState(() => _selectedBooking = b),
              ),
              const SizedBox(height: 10),
            ],

            // ── Amount ────────────────────────────────────────
            _SectionHeader('المبلغ'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDec('المبلغ *').copyWith(
                    prefixIcon: const Icon(Icons.monetization_on, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل المبلغ';
                    if (double.tryParse(v.trim()) == null) return 'مبلغ غير صالح';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: _inputDec('العملة'),
                  items: AppConstants.currencies.map((c) => DropdownMenuItem(
                      value: c, child: Text(c, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Method & Date ─────────────────────────────────
            _SectionHeader('طريقة الدفع والتاريخ'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: _inputDec('طريقة الدفع'),
              items: const [
                DropdownMenuItem(value: 'cash',           child: Text('نقداً 💵',          style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'bank_transfer',  child: Text('تحويل بنكي 🏦',    style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'credit_card',    child: Text('بطاقة ائتمان 💳',  style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'instapay',       child: Text('إنستاباي 📱',      style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'vodafone_cash',  child: Text('فودافون كاش 📲',   style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'other',          child: Text('أخرى',              style: TextStyle(fontFamily: 'Cairo'))),
              ],
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: _inputDec('تاريخ الدفع *').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy').format(_date),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _refCtrl,
              decoration: _inputDec('رقم المرجع / الإيصال'),
            ),
            const SizedBox(height: 20),

            // ── Notes ─────────────────────────────────────────
            _SectionHeader('ملاحظات'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: _inputDec('ملاحظات'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}

class _DirectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _DirectionChip({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Column(children: [
            Icon(icon, color: selected ? Colors.white : color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary)),
          ]),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: AppColors.border)),
      ]);
}
