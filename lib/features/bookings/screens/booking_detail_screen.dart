// lib/features/bookings/screens/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/bookings_table.dart';
import '../../customers/providers/customers_providers.dart';
import '../../payments/providers/payments_providers.dart';
import '../providers/bookings_providers.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync  = ref.watch(bookingByIdProvider(bookingId));
    final paymentsAsync = ref.watch(paymentsByBookingProvider(bookingId));
    final fmt           = NumberFormat('#,##0.00', 'ar');

    return bookingAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('خطأ: $e'))),
      data: (booking) {
        if (booking == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('الحجز غير موجود')));
        }
        return _BookingDetailBody(booking: booking, paymentsAsync: paymentsAsync, fmt: fmt, ref: ref);
      },
    );
  }
}

class _BookingDetailBody extends ConsumerStatefulWidget {
  final Booking booking;
  final AsyncValue paymentsAsync;
  final NumberFormat fmt;
  final WidgetRef ref;

  const _BookingDetailBody({
    required this.booking,
    required this.paymentsAsync,
    required this.fmt,
    required this.ref,
  });

  @override
  ConsumerState<_BookingDetailBody> createState() => _BookingDetailBodyState();
}

class _BookingDetailBodyState extends ConsumerState<_BookingDetailBody> {
  Future<void> _changeStatus(String newStatus) async {
    final db = ref.read(databaseProvider);
    await db.bookingsDao.updateBooking(widget.booking.toCompanion(true).copyWith(
      status:    Value(newStatus),
      updatedAt: Value(DateTime.now()),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تغيير الحالة ✅'), backgroundColor: AppColors.success),
      );
      ref.invalidate(bookingByIdProvider(widget.booking.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b   = widget.booking;
    final fmt = widget.fmt;
    final statusColor = _statusColor(b.status);
    final statusLabel = _statusLabel(b.status);
    final profit = b.sellingPrice - b.totalCost;
    final paidPct = b.sellingPrice > 0 ? (b.paidAmount / b.sellingPrice).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(b.bookingNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/bookings/${b.id}/edit').then((_) {
              ref.invalidate(bookingByIdProvider(b.id));
            }),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _changeStatus,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pending',   child: Text('معلق',   style: TextStyle(fontFamily: 'Cairo'))),
              const PopupMenuItem(value: 'confirmed', child: Text('مؤكد',   style: TextStyle(fontFamily: 'Cairo'))),
              const PopupMenuItem(value: 'completed', child: Text('مكتمل',  style: TextStyle(fontFamily: 'Cairo'))),
              const PopupMenuItem(value: 'cancelled', child: Text('ملغي',   style: TextStyle(fontFamily: 'Cairo'))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Status Banner ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(_typeIcon(b.bookingType), color: statusColor),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.bookingNumber, style: AppTextStyles.titleMedium),
                Text('${_typeLabel(b.bookingType)} • ${DateFormat('dd MMMM yyyy', 'ar').format(b.createdAt)}',
                    style: AppTextStyles.bodySmall),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel,
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Customer ──────────────────────────────────────
          _card(children: [
            _row(Icons.person, 'العميل', _customerName(ref, b.customerId)),
          ]),
          const SizedBox(height: 12),

          // ── Flight Details ─────────────────────────────────
          _card(children: [
            const Text('تفاصيل الرحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14)),
            const Divider(),
            if (b.origin != null || b.destination != null)
              _row(Icons.flight, 'المسار', '${b.origin ?? ''} ← ${b.destination ?? ''}'),
            if (b.airlineName != null) _row(Icons.airlines, 'الشركة', b.airlineName!),
            if (b.flightNumber != null) _row(Icons.tag, 'رقم الرحلة', b.flightNumber!),
            if (b.pnrNumber != null) _row(Icons.confirmation_number, 'PNR', b.pnrNumber!),
            if (b.travelClass != null) _row(Icons.airline_seat_recline_normal, 'الدرجة', _classLabel(b.travelClass!)),
            if (b.departureDate != null)
              _row(Icons.calendar_today, 'تاريخ الذهاب', DateFormat('dd/MM/yyyy').format(b.departureDate!)),
            if (b.returnDate != null)
              _row(Icons.calendar_today, 'تاريخ العودة', DateFormat('dd/MM/yyyy').format(b.returnDate!)),
            _row(Icons.people, 'المسافرون',
                '${b.adultsCount} بالغ • ${b.childrenCount} طفل • ${b.infantsCount} رضيع'),
          ]),
          const SizedBox(height: 12),

          // ── Financials ────────────────────────────────────
          _card(children: [
            const Text('الماليات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14)),
            const Divider(),
            _row(Icons.sell, 'سعر البيع', '${fmt.format(b.sellingPrice)} ج.م'),
            _row(Icons.price_change, 'تكلفة الشركة', '${fmt.format(b.totalCost)} ج.م'),
            _row(Icons.trending_up, 'الربح', '${fmt.format(profit)} ج.م',
                valueColor: profit >= 0 ? AppColors.success : AppColors.error),
            if (b.taxAmount != null)
              _row(Icons.receipt, 'الضرائب', '${fmt.format(b.taxAmount!)} ج.م'),
            const SizedBox(height: 8),
            const Divider(),
            _row(Icons.check_circle, 'المدفوع', '${fmt.format(b.paidAmount)} ج.م',
                valueColor: AppColors.success),
            _row(Icons.pending, 'المتبقي',
                '${fmt.format(b.sellingPrice - b.paidAmount)} ج.م',
                valueColor: b.paidAmount >= b.sellingPrice ? AppColors.success : AppColors.error),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: paidPct,
                minHeight: 8,
                backgroundColor: AppColors.neutralLight,
                valueColor: AlwaysStoppedAnimation(
                    paidPct >= 1 ? AppColors.success : AppColors.warning),
              ),
            ),
            const SizedBox(height: 4),
            Text('${(paidPct * 100).toStringAsFixed(0)}% تم تحصيله',
                style: AppTextStyles.labelSmall),
          ]),
          const SizedBox(height: 12),

          // ── Payments ──────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('المدفوعات المرتبطة', style: AppTextStyles.titleSmall),
            TextButton.icon(
              onPressed: () => context.push('/payments/new'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('إضافة دفعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            ),
          ]),
          widget.paymentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => const SizedBox.shrink(),
            data: (payments) {
              if (payments is! List || payments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(child: Text('لا توجد مدفوعات', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo'))),
                );
              }
              return Column(
                children: payments.map<Widget>((p) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.arrow_downward, color: AppColors.success, size: 18)),
                    title: Text(p.paymentNumber ?? '', style: AppTextStyles.titleSmall),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy').format(p.paymentDate)} • ${_methodLabel(p.paymentMethod)}',
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: Text('${fmt.format(p.amount)} ج.م',
                        style: const TextStyle(fontFamily: 'Cairo', color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                )).toList(),
              );
            },
          ),

          if (b.notes != null && b.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(children: [
              _row(Icons.note, 'ملاحظات', b.notes!),
            ]),
          ],
          const SizedBox(height: 30),
        ]),
      ),
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

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary)),
        ]),
      );

  String _customerName(WidgetRef ref, String customerId) {
    final c = ref.watch(customerByIdProvider(customerId)).valueOrNull;
    return c != null ? '${c.firstName} ${c.lastName}' : customerId;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return AppColors.confirmed;
      case 'completed': return AppColors.completed;
      case 'cancelled': return AppColors.cancelled;
      default: return AppColors.pending;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed': return 'مؤكد';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      default: return 'معلق';
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'flight': return Icons.flight;
      case 'hotel': return Icons.hotel;
      case 'tour': return Icons.tour;
      case 'visa': return Icons.credit_card;
      default: return Icons.travel_explore;
    }
  }

  String _typeLabel(String t) {
    const m = {'flight': 'طيران', 'hotel': 'فندق', 'tour': 'رحلة', 'visa': 'تأشيرة', 'other': 'أخرى'};
    return m[t] ?? t;
  }

  String _classLabel(String c) {
    const m = {'economy': 'اقتصاد', 'business': 'أعمال', 'first': 'أولى'};
    return m[c] ?? c;
  }

  String _methodLabel(String m) {
    const map = {
      'cash': 'نقداً', 'bank_transfer': 'تحويل بنكي',
      'credit_card': 'بطاقة', 'instapay': 'إنستاباي',
      'vodafone_cash': 'فودافون كاش', 'other': 'أخرى',
    };
    return map[m] ?? m;
  }
}
