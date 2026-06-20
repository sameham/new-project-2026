// lib/features/bookings/screens/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/bookings_table.dart';
import '../../../database/tables/payments_table.dart';
import '../../customers/providers/customers_providers.dart';
import '../../payments/providers/payments_providers.dart';
import '../providers/bookings_providers.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/timeline_widget.dart';
import '../../../shared/widgets/status_badge.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));

    return bookingAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('خطأ: $e'))),
      data: (booking) {
        if (booking == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('الحجز غير موجود')));
        }
        return _BookingWorkspace(booking: booking);
      },
    );
  }
}

class _BookingWorkspace extends ConsumerStatefulWidget {
  final Booking booking;
  const _BookingWorkspace({required this.booking});

  @override
  ConsumerState<_BookingWorkspace> createState() => _BookingWorkspaceState();
}

class _BookingWorkspaceState extends ConsumerState<_BookingWorkspace> {
  Future<void> _changeStatus(String newStatus) async {
    final db = ref.read(databaseProvider);
    await db.bookingsDao.updateBooking(widget.booking.toCompanion(true).copyWith(
      status: Value(newStatus),
      updatedAt: Value(DateTime.now()),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('تم تغيير الحالة'), backgroundColor: AppColors.success),
      );
      ref.invalidate(bookingByIdProvider(widget.booking.id));
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('https://wa.me/$clean');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح واتساب')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final fmt = NumberFormat('#,##0', 'ar');
    final dateFmt = DateFormat('dd/MM/yyyy', 'ar');
    final timeFmt = DateFormat('dd MMM، HH:mm', 'ar');

    final profit = b.sellingPrice - b.totalCost;
    final remaining = b.sellingPrice - b.paidAmount;
    final paidPct = b.sellingPrice > 0 ? (b.paidAmount / b.sellingPrice).clamp(0.0, 1.0) : 0.0;

    final customerAsync = ref.watch(customerByIdProvider(b.customerId));
    final paymentsAsync = ref.watch(paymentsByBookingProvider(b.id));

    final origin = b.origin ?? '?';
    final dest   = b.destination ?? '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
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
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'pending',   child: Text('معلق')),
                  PopupMenuItem(value: 'confirmed', child: Text('مؤكد')),
                  PopupMenuItem(value: 'completed', child: Text('مكتمل')),
                  PopupMenuItem(value: 'cancelled', child: Text('ملغي')),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$origin → $dest',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      StatusBadge(status: b.status),
                      const SizedBox(width: 8),
                      if (b.pnrNumber != null) _HeroPnrChip(pnr: b.pnrNumber!),
                      if (b.airlineName != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.flight, size: 13, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(b.airlineName!, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 13)),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Section 1: Customer Info ───────────────────
                  customerAsync.when(
                    loading: () => const _InfoCard(children: [LinearProgressIndicator()]),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (customer) {
                      if (customer == null) return const SizedBox.shrink();
                      return _InfoCard(children: [
                        Row(children: [
                          _SectionLabel(Icons.person_outline, 'معلومات العميل'),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.push('/customers/${customer.id}'),
                            child: const Text('عرض الملف'),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text('${customer.firstName} ${customer.lastName}',
                            style: AppTextStyles.cardTitle.copyWith(fontSize: 17)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(customer.phone, style: AppTextStyles.cardSubtitle),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _launchWhatsApp(customer.phone),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(children: const [
                                Icon(Icons.chat_outlined, size: 14, color: Color(0xFF25D366)),
                                SizedBox(width: 4),
                                Text('واتساب', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF25D366), fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ]),
                        if (customer.passportNumber != null) ...[
                          const SizedBox(height: 4),
                          _InfoRow(Icons.credit_card_outlined, 'جواز السفر', customer.passportNumber!),
                        ],
                        if (customer.nationality != null) ...[
                          const SizedBox(height: 4),
                          _InfoRow(Icons.flag_outlined, 'الجنسية', customer.nationality!),
                        ],
                        const SizedBox(height: 4),
                        _InfoRow(Icons.tag_outlined, 'كود العميل', customer.customerCode),
                      ]);
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Section 2: Flight Details ──────────────────
                  _InfoCard(children: [
                    _SectionLabel(Icons.flight_outlined, 'تفاصيل الرحلة'),
                    const SizedBox(height: 12),
                    if (b.airlineName != null) _InfoRow(Icons.airlines_outlined, 'شركة الطيران', b.airlineName!),
                    if (b.flightNumber != null) _InfoRow(Icons.tag_outlined, 'رقم الرحلة', b.flightNumber!),
                    if (b.pnrNumber != null) GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: b.pnrNumber!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ رقم PNR')),
                        );
                      },
                      child: _InfoRow(Icons.confirmation_number_outlined, 'PNR',
                        '${b.pnrNumber!} 📋'),
                    ),
                    if (b.travelClass != null) _InfoRow(Icons.airline_seat_recline_normal, 'الدرجة', _classLabel(b.travelClass!)),
                    if (b.departureDate != null) _InfoRow(Icons.calendar_today_outlined, 'تاريخ الذهاب', dateFmt.format(b.departureDate!)),
                    if (b.returnDate != null) _InfoRow(Icons.calendar_month_outlined, 'تاريخ العودة', dateFmt.format(b.returnDate!)),
                    _InfoRow(Icons.people_outline, 'المسافرون', '${b.adultsCount} بالغ • ${b.childrenCount} طفل • ${b.infantsCount} رضيع'),
                  ]),
                  const SizedBox(height: 12),

                  // ── Section 3: Financial Summary ───────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(right: BorderSide(color: AppColors.primary, width: 4)),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _SectionLabel(Icons.account_balance_wallet_outlined, 'الملخص المالي'),
                        const SizedBox(height: 14),
                        Row(children: [
                          _FinCol(label: 'سعر البيع', value: '${fmt.format(b.sellingPrice)} ج.م', color: AppColors.textPrimary),
                          _FinCol(label: 'التكلفة', value: '${fmt.format(b.totalCost)} ج.م', color: AppColors.textSecondary),
                          _FinCol(
                            label: 'الربح',
                            value: '${fmt.format(profit)} ج.م',
                            color: profit >= 0 ? AppColors.success : AppColors.error,
                          ),
                        ]),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text('تم تحصيل: ', style: AppTextStyles.bodySmall),
                          Text('${fmt.format(b.paidAmount)} ج.م',
                              style: AppTextStyles.amountSmall.copyWith(color: AppColors.success)),
                          const Spacer(),
                          if (remaining > 0) ...[
                            Icon(Icons.schedule_outlined, size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text('متبقي: ', style: AppTextStyles.bodySmall),
                            Text('${fmt.format(remaining)} ج.م',
                                style: AppTextStyles.amountSmall.copyWith(color: AppColors.error)),
                          ],
                        ]),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: paidPct,
                            minHeight: 10,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              paidPct >= 1.0 ? AppColors.success : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            'تم تحصيل ${(paidPct * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Section 4: Documents ───────────────────────
                  _InfoCard(children: [
                    _SectionLabel(Icons.folder_outlined, 'المستندات'),
                    const SizedBox(height: 12),
                    ...[
                      ('تذكرة PDF', Icons.airplane_ticket_outlined),
                      ('صورة الجواز', Icons.credit_card_outlined),
                      ('التأشيرة', Icons.verified_user_outlined),
                      ('مرفقات', Icons.attach_file_outlined),
                    ].map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(item.$2, color: AppColors.primary, size: 20),
                      title: Text(item.$1, style: AppTextStyles.bodyMedium),
                      trailing: TextButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('هذه الميزة قريباً')),
                        ),
                        child: const Text('إضافة'),
                      ),
                    )),
                  ]),
                  const SizedBox(height: 12),

                  // ── Section 5: Activity Timeline ───────────────
                  SectionHeader(title: 'سجل النشاط'),
                  const SizedBox(height: 12),
                  paymentsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (payments) {
                      final List<({String title, String? subtitle, DateTime date, IconData icon, Color color})> events = [];

                      events.add((
                        title: 'تم إنشاء الحجز',
                        subtitle: b.bookingNumber,
                        date: b.createdAt,
                        icon: Icons.add_circle_outline,
                        color: AppColors.primary,
                      ));

                      for (final p in (payments as List<Payment>)) {
                        events.add((
                          title: 'تم استلام دفعة',
                          subtitle: '${fmt.format(p.amount)} ج.م',
                          date: p.paymentDate,
                          icon: Icons.payments_outlined,
                          color: AppColors.success,
                        ));
                      }

                      if (b.status == 'confirmed') {
                        events.add((
                          title: 'تم تأكيد الحجز',
                          subtitle: null,
                          date: b.updatedAt,
                          icon: Icons.check_circle_outline,
                          color: AppColors.confirmed,
                        ));
                      } else if (b.status == 'completed') {
                        events.add((
                          title: 'اكتملت الرحلة',
                          subtitle: null,
                          date: b.updatedAt,
                          icon: Icons.flight_land_outlined,
                          color: AppColors.completed,
                        ));
                      } else if (b.status == 'cancelled') {
                        events.add((
                          title: 'تم الإلغاء',
                          subtitle: null,
                          date: b.updatedAt,
                          icon: Icons.cancel_outlined,
                          color: AppColors.cancelled,
                        ));
                      }

                      events.sort((a, b) => b.date.compareTo(a.date));

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: events.asMap().entries.map((e) => TimelineItem(
                            title: e.value.title,
                            subtitle: e.value.subtitle,
                            time: timeFmt.format(e.value.date),
                            icon: e.value.icon,
                            color: e.value.color,
                            isLast: e.key == events.length - 1,
                          )).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Section 6: Quick Actions ────────────────────
                  SectionHeader(title: 'إجراءات سريعة'),
                  const SizedBox(height: 12),
                  _ActionsGrid(
                    booking: b,
                    onWhatsApp: () {
                      final phone = customerAsync.valueOrNull?.phone ?? '';
                      if (phone.isNotEmpty) _launchWhatsApp(phone);
                    },
                    onEdit: () => context.push('/bookings/${b.id}/edit').then((_) {
                      ref.invalidate(bookingByIdProvider(b.id));
                    }),
                    onAddPayment: () => context.push('/payments/new'),
                    onRefund: () => _showRefundDialog(context),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRefundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الاسترداد', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل تريد تغيير حالة الحجز إلى "ملغي"؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _changeStatus('cancelled'); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('نعم، إلغاء الحجز', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  String _classLabel(String c) {
    const m = {'economy': 'اقتصاد', 'business': 'أعمال', 'first': 'درجة أولى'};
    return m[c] ?? c;
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 6),
      Text(label, style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(value,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end),
        ),
      ]),
    );
  }
}

class _FinCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FinCol({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(label, style: AppTextStyles.kpiLabel.copyWith(color: AppColors.textHint)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.amountSmall.copyWith(color: color), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _HeroPnrChip extends StatelessWidget {
  final String pnr;
  const _HeroPnrChip({required this.pnr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(pnr, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  final Booking booking;
  final VoidCallback onWhatsApp;
  final VoidCallback onEdit;
  final VoidCallback onAddPayment;
  final VoidCallback onRefund;

  const _ActionsGrid({
    required this.booking,
    required this.onWhatsApp,
    required this.onEdit,
    required this.onAddPayment,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.chat_outlined, 'واتساب', const Color(0xFF25D366), onWhatsApp),
      (Icons.print_outlined, 'طباعة', AppColors.info, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الطباعة قريباً')))),
      (Icons.share_outlined, 'مشاركة', AppColors.secondary, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المشاركة قريباً')))),
      (Icons.edit_outlined, 'تعديل', AppColors.primary, onEdit),
      (Icons.add_card_outlined, 'إضافة دفعة', AppColors.success, onAddPayment),
      (Icons.undo_outlined, 'استرداد', AppColors.error, onRefund),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: actions.map((a) => GestureDetector(
        onTap: a.$4,
        child: Container(
          decoration: BoxDecoration(
            color: a.$3.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: a.$3.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(a.$1, color: a.$3, size: 22),
              const SizedBox(height: 6),
              Text(a.$2, style: AppTextStyles.labelSmall.copyWith(color: a.$3, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
