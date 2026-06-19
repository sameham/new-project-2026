// lib/features/bookings/screens/booking_form_screen.dart

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
import '../../../database/tables/bookings_table.dart';
import '../../../database/tables/customers_table.dart';
import '../../customers/providers/customers_providers.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  const BookingFormScreen({super.key, this.bookingId});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading  = false;
  bool _isEdit   = false;

  Customer? _selectedCustomer;
  String _bookingType  = 'flight';
  String _status       = 'pending';
  String _travelClass  = 'economy';

  final _originCtrl      = TextEditingController();
  final _destCtrl        = TextEditingController();
  final _airlineCtrl     = TextEditingController();
  final _flightNoCtrl    = TextEditingController();
  final _pnrCtrl         = TextEditingController();
  final _costCtrl        = TextEditingController();
  final _priceCtrl       = TextEditingController();
  final _taxCtrl         = TextEditingController();
  final _notesCtrl       = TextEditingController();

  int _adults   = 1;
  int _children = 0;
  int _infants  = 0;

  DateTime? _departureDate;
  DateTime? _returnDate;

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _isEdit = true;
      _loadBooking();
    }
  }

  Future<void> _loadBooking() async {
    final db = ref.read(databaseProvider);
    final b  = await db.bookingsDao.getById(widget.bookingId!);
    if (b != null && mounted) {
      final customer = await db.customersDao.getCustomerById(b.customerId);
      setState(() {
        _selectedCustomer = customer;
        _bookingType      = b.bookingType;
        _status           = b.status;
        _travelClass      = b.travelClass ?? 'economy';
        _originCtrl.text  = b.origin ?? '';
        _destCtrl.text    = b.destination ?? '';
        _airlineCtrl.text = b.airlineName ?? '';
        _flightNoCtrl.text= b.flightNumber ?? '';
        _pnrCtrl.text     = b.pnrNumber ?? '';
        _costCtrl.text    = b.totalCost.toStringAsFixed(2);
        _priceCtrl.text   = b.sellingPrice.toStringAsFixed(2);
        _taxCtrl.text     = (b.taxAmount ?? 0).toStringAsFixed(2);
        _notesCtrl.text   = b.notes ?? '';
        _adults           = b.adultsCount;
        _children         = b.childrenCount;
        _infants          = b.infantsCount;
        _departureDate    = b.departureDate;
        _returnDate       = b.returnDate;
      });
    }
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
      final totalCost    = double.tryParse(_costCtrl.text) ?? 0;
      final sellingPrice = double.tryParse(_priceCtrl.text) ?? 0;
      final taxAmount    = double.tryParse(_taxCtrl.text);

      if (_isEdit) {
        final existing = await db.bookingsDao.getById(widget.bookingId!);
        if (existing != null) {
          await db.bookingsDao.updateBooking(existing.toCompanion(true).copyWith(
            customerId:   Value(_selectedCustomer!.id),
            bookingType:  Value(_bookingType),
            status:       Value(_status),
            origin:       Value(_originCtrl.text.trim().isEmpty ? null : _originCtrl.text.trim()),
            destination:  Value(_destCtrl.text.trim().isEmpty ? null : _destCtrl.text.trim()),
            airlineName:  Value(_airlineCtrl.text.trim().isEmpty ? null : _airlineCtrl.text.trim()),
            flightNumber: Value(_flightNoCtrl.text.trim().isEmpty ? null : _flightNoCtrl.text.trim()),
            pnrNumber:    Value(_pnrCtrl.text.trim().isEmpty ? null : _pnrCtrl.text.trim()),
            travelClass:  Value(_travelClass),
            departureDate: Value(_departureDate),
            returnDate:   Value(_returnDate),
            adultsCount:  Value(_adults),
            childrenCount: Value(_children),
            infantsCount: Value(_infants),
            totalCost:    Value(totalCost),
            sellingPrice: Value(sellingPrice),
            taxAmount:    Value(taxAmount),
            notes:        Value(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()),
            updatedAt:    Value(now),
            syncStatus:   const Value('pending'),
          ));
        }
      } else {
        final id     = const Uuid().v4();
        final number = '${AppConstants.prefixBooking}${now.millisecondsSinceEpoch.toString().substring(6)}';
        await db.bookingsDao.insertBooking(BookingsCompanion.insert(
          id:            id,
          customerId:    _selectedCustomer!.id,
          bookingNumber: number,
          bookingType:   _bookingType,
          status:        Value(_status),
          origin:        Value(_originCtrl.text.trim().isEmpty ? null : _originCtrl.text.trim()),
          destination:   Value(_destCtrl.text.trim().isEmpty ? null : _destCtrl.text.trim()),
          airlineName:   Value(_airlineCtrl.text.trim().isEmpty ? null : _airlineCtrl.text.trim()),
          flightNumber:  Value(_flightNoCtrl.text.trim().isEmpty ? null : _flightNoCtrl.text.trim()),
          pnrNumber:     Value(_pnrCtrl.text.trim().isEmpty ? null : _pnrCtrl.text.trim()),
          travelClass:   Value(_travelClass),
          departureDate: Value(_departureDate),
          returnDate:    Value(_returnDate),
          adultsCount:   Value(_adults),
          childrenCount: Value(_children),
          infantsCount:  Value(_infants),
          totalCost:     Value(totalCost),
          sellingPrice:  Value(sellingPrice),
          taxAmount:     Value(taxAmount),
          notes:         Value(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()),
        ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'تم تحديث الحجز ✅' : 'تمت إضافة الحجز ✅'),
              backgroundColor: AppColors.success),
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

  Future<void> _pickDate(bool isDeparture) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDeparture ? _departureDate : _returnDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) _departureDate = picked;
        else _returnDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _originCtrl.dispose(); _destCtrl.dispose(); _airlineCtrl.dispose();
    _flightNoCtrl.dispose(); _pnrCtrl.dispose(); _costCtrl.dispose();
    _priceCtrl.dispose(); _taxCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل حجز' : 'حجز جديد'),
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
            // ── Customer ──────────────────────────────────────
            _SectionHeader('العميل'),
            const SizedBox(height: 10),
            customersAsync.when(
              loading: () => const CircularProgressIndicator(),
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
                onChanged: (c) => setState(() => _selectedCustomer = c),
                validator: (v) => v == null ? 'يرجى اختيار العميل' : null,
              ),
            ),
            const SizedBox(height: 20),

            // ── Type & Status ──────────────────────────────────
            _SectionHeader('نوع الحجز'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: _bookingType,
                decoration: _inputDec('نوع الحجز'),
                items: const [
                  DropdownMenuItem(value: 'flight', child: Text('طيران ✈️', style: TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'hotel',  child: Text('فندق 🏨',  style: TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'tour',   child: Text('رحلة 🌍',  style: TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'visa',   child: Text('تأشيرة 📋', style: TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'other',  child: Text('أخرى 📦',  style: TextStyle(fontFamily: 'Cairo'))),
                ],
                onChanged: (v) => setState(() => _bookingType = v!),
              )),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(
                value: _status,
                decoration: _inputDec('الحالة'),
                items: const [
                  DropdownMenuItem(value: 'pending',   child: Text('معلق',   style: TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'confirmed', child: Text('مؤكد',   style: TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'completed', child: Text('مكتمل',  style: TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'cancelled', child: Text('ملغي',   style: TextStyle(fontFamily: 'Cairo'))),
                ],
                onChanged: (v) => setState(() => _status = v!),
              )),
            ]),
            const SizedBox(height: 20),

            // ── Flight Info ────────────────────────────────────
            _SectionHeader('تفاصيل الرحلة'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_originCtrl, 'مطار المغادرة')),
              const SizedBox(width: 10),
              Expanded(child: _field(_destCtrl, 'مطار الوصول')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_airlineCtrl, 'اسم الشركة')),
              const SizedBox(width: 10),
              Expanded(child: _field(_flightNoCtrl, 'رقم الرحلة')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_pnrCtrl, 'رقم PNR')),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(
                value: _travelClass,
                decoration: _inputDec('الدرجة'),
                items: const [
                  DropdownMenuItem(value: 'economy',  child: Text('اقتصاد',  style: TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'business', child: Text('أعمال',   style: TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'first',    child: Text('أولى',    style: TextStyle(fontFamily: 'Cairo'))),
                ],
                onChanged: (v) => setState(() => _travelClass = v!),
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _datePicker('تاريخ الذهاب', _departureDate, () => _pickDate(true))),
              const SizedBox(width: 10),
              Expanded(child: _datePicker('تاريخ العودة', _returnDate, () => _pickDate(false))),
            ]),
            const SizedBox(height: 20),

            // ── Passengers ────────────────────────────────────
            _SectionHeader('المسافرون'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _counter('البالغون', _adults, (v) => setState(() => _adults = v), 1)),
              const SizedBox(width: 8),
              Expanded(child: _counter('الأطفال', _children, (v) => setState(() => _children = v), 0)),
              const SizedBox(width: 8),
              Expanded(child: _counter('الرضّع', _infants, (v) => setState(() => _infants = v), 0)),
            ]),
            const SizedBox(height: 20),

            // ── Pricing ───────────────────────────────────────
            _SectionHeader('التسعير'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_costCtrl, 'تكلفة الشركة (ج.م)', keyboard: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _field(_priceCtrl, 'سعر البيع (ج.م) *', required: true, keyboard: TextInputType.number)),
            ]),
            const SizedBox(height: 10),
            _field(_taxCtrl, 'الضرائب والرسوم (ج.م)', keyboard: TextInputType.number),
            const SizedBox(height: 20),

            // ── Notes ─────────────────────────────────────────
            _SectionHeader('ملاحظات'),
            const SizedBox(height: 10),
            _field(_notesCtrl, 'ملاحظات', maxLines: 3),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          decoration: _inputDec(label).copyWith(
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
          ),
          controller: TextEditingController(
            text: date != null ? DateFormat('dd/MM/yyyy').format(date) : '',
          ),
        ),
      ),
    );
  }

  Widget _counter(String label, int value, ValueChanged<int> onChanged, int min) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: () { if (value > min) onChanged(value - 1); },
            child: Container(
              decoration: BoxDecoration(color: AppColors.neutralLight, borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.remove, size: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('$value', style: AppTextStyles.titleSmall),
          ),
          GestureDetector(
            onTap: () => onChanged(value + 1),
            child: Container(
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.add, size: 16, color: AppColors.primary),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, TextInputType? keyboard, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: _inputDec(label),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null : null,
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
