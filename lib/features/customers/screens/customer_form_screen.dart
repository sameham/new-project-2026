// lib/features/customers/screens/customer_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/customers_table.dart';
import '../providers/customers_providers.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const CustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isEdit = false;

  final _firstNameCtrl     = TextEditingController();
  final _lastNameCtrl      = TextEditingController();
  final _firstNameEnCtrl   = TextEditingController();
  final _lastNameEnCtrl    = TextEditingController();
  final _phoneCtrl         = TextEditingController();
  final _phoneAltCtrl      = TextEditingController();
  final _emailCtrl         = TextEditingController();
  final _passportCtrl      = TextEditingController();
  final _nationalityCtrl   = TextEditingController();
  final _addressCtrl       = TextEditingController();
  final _notesCtrl         = TextEditingController();

  DateTime? _passportExpiry;
  DateTime? _dateOfBirth;
  String _gender = 'male';

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _isEdit = true;
      _loadCustomer();
    }
  }

  Future<void> _loadCustomer() async {
    final db = ref.read(databaseProvider);
    final c = await db.customersDao.getCustomerById(widget.customerId!);
    if (c != null && mounted) {
      setState(() {
        _firstNameCtrl.text   = c.firstName;
        _lastNameCtrl.text    = c.lastName;
        _firstNameEnCtrl.text = c.firstNameEn ?? '';
        _lastNameEnCtrl.text  = c.lastNameEn ?? '';
        _phoneCtrl.text       = c.phone;
        _phoneAltCtrl.text    = c.phoneAlt ?? '';
        _emailCtrl.text       = c.email ?? '';
        _passportCtrl.text    = c.passportNumber ?? '';
        _nationalityCtrl.text = c.nationality ?? '';
        _addressCtrl.text     = c.address ?? '';
        _notesCtrl.text       = c.notes ?? '';
        _passportExpiry       = c.passportExpiry;
        _dateOfBirth          = c.dateOfBirth;
        _gender               = c.gender ?? 'male';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    try {
      if (_isEdit) {
        final c = await db.customersDao.getCustomerById(widget.customerId!);
        if (c != null) {
          await db.customersDao.updateCustomer(c.toCompanion(true).copyWith(
            firstName:     Value(_firstNameCtrl.text.trim()),
            lastName:      Value(_lastNameCtrl.text.trim()),
            firstNameEn:   Value(_firstNameEnCtrl.text.trim().isEmpty ? null : _firstNameEnCtrl.text.trim()),
            lastNameEn:    Value(_lastNameEnCtrl.text.trim().isEmpty  ? null : _lastNameEnCtrl.text.trim()),
            phone:         Value(_phoneCtrl.text.trim()),
            phoneAlt:      Value(_phoneAltCtrl.text.trim().isEmpty ? null : _phoneAltCtrl.text.trim()),
            email:         Value(_emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim()),
            passportNumber: Value(_passportCtrl.text.trim().isEmpty ? null : _passportCtrl.text.trim()),
            passportExpiry: Value(_passportExpiry),
            nationality:   Value(_nationalityCtrl.text.trim().isEmpty ? null : _nationalityCtrl.text.trim()),
            dateOfBirth:   Value(_dateOfBirth),
            gender:        Value(_gender),
            address:       Value(_addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim()),
            notes:         Value(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()),
            updatedAt:     Value(now),
            syncStatus:    const Value('pending'),
          ));
        }
      } else {
        final id   = const Uuid().v4();
        final code = 'CUS${now.millisecondsSinceEpoch.toString().substring(7)}';
        await db.customersDao.insertCustomer(CustomersCompanion.insert(
          id:            id,
          customerCode:  code,
          firstName:     _firstNameCtrl.text.trim(),
          lastName:      _lastNameCtrl.text.trim(),
          firstNameEn:   Value(_firstNameEnCtrl.text.trim().isEmpty ? null : _firstNameEnCtrl.text.trim()),
          lastNameEn:    Value(_lastNameEnCtrl.text.trim().isEmpty  ? null : _lastNameEnCtrl.text.trim()),
          phone:         _phoneCtrl.text.trim(),
          phoneAlt:      Value(_phoneAltCtrl.text.trim().isEmpty ? null : _phoneAltCtrl.text.trim()),
          email:         Value(_emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim()),
          passportNumber: Value(_passportCtrl.text.trim().isEmpty ? null : _passportCtrl.text.trim()),
          passportExpiry: Value(_passportExpiry),
          nationality:   Value(_nationalityCtrl.text.trim().isEmpty ? null : _nationalityCtrl.text.trim()),
          dateOfBirth:   Value(_dateOfBirth),
          gender:        Value(_gender),
          address:       Value(_addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim()),
          notes:         Value(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()),
        ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'تم تحديث العميل ✅' : 'تمت إضافة العميل ✅'),
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

  Future<void> _pickDate(bool isExpiry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isExpiry ? _passportExpiry : _dateOfBirth) ?? DateTime.now(),
      firstDate: DateTime(1940),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) _passportExpiry = picked;
        else _dateOfBirth = picked;
      });
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _firstNameEnCtrl.dispose(); _lastNameEnCtrl.dispose();
    _phoneCtrl.dispose(); _phoneAltCtrl.dispose();
    _emailCtrl.dispose(); _passportCtrl.dispose();
    _nationalityCtrl.dispose(); _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل عميل' : 'إضافة عميل جديد'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
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
            _SectionHeader('البيانات الشخصية'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_firstNameCtrl, 'الاسم الأول *', required: true)),
              const SizedBox(width: 10),
              Expanded(child: _field(_lastNameCtrl, 'اسم العائلة *', required: true)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_firstNameEnCtrl, 'First Name (EN)')),
              const SizedBox(width: 10),
              Expanded(child: _field(_lastNameEnCtrl, 'Last Name (EN)')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: _inputDec('الجنس'),
                  items: const [
                    DropdownMenuItem(value: 'male',   child: Text('ذكر',   style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'female', child: Text('أنثى',  style: TextStyle(fontFamily: 'Cairo'))),
                  ],
                  onChanged: (v) => setState(() => _gender = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(false),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDec('تاريخ الميلاد').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      controller: TextEditingController(
                        text: _dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!) : '',
                      ),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _SectionHeader('بيانات التواصل'),
            const SizedBox(height: 10),
            _field(_phoneCtrl, 'رقم الهاتف *', required: true, keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _field(_phoneAltCtrl, 'هاتف بديل', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _field(_emailCtrl, 'البريد الإلكتروني', keyboard: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _field(_addressCtrl, 'العنوان', maxLines: 2),
            const SizedBox(height: 20),
            _SectionHeader('بيانات الجواز'),
            const SizedBox(height: 10),
            _field(_passportCtrl, 'رقم الجواز'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_nationalityCtrl, 'الجنسية')),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(true),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDec('انتهاء الجواز').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      controller: TextEditingController(
                        text: _passportExpiry != null ? DateFormat('dd/MM/yyyy').format(_passportExpiry!) : '',
                      ),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _SectionHeader('ملاحظات'),
            const SizedBox(height: 10),
            _field(_notesCtrl, 'ملاحظات', maxLines: 3),
            const SizedBox(height: 30),
          ],
        ),
      ),
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
