// lib/features/bookings/screens/bookings_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/tables/bookings_table.dart';
import '../../../database/app_database.dart';
import '../providers/bookings_providers.dart';

class BookingsListScreen extends ConsumerWidget {
  const BookingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings     = ref.watch(filteredBookingsProvider);
    final statusFilter = ref.watch(bookingStatusFilterProvider);

    const statuses = <String?, String>{
      null: 'الكل', 'pending': 'معلق', 'confirmed': 'مؤكد',
      'completed': 'مكتمل', 'cancelled': 'ملغي',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الحجوزات'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: statuses.entries.map((e) {
                final sel = statusFilter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(e.value, style: TextStyle(fontFamily: 'Cairo', color: sel ? Colors.white : AppColors.textPrimary, fontSize: 12)),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onSelected: (_) => ref.read(bookingStatusFilterProvider.notifier).state = e.key,
                    side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.flight_outlined, size: 72, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('لا توجد حجوزات', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('اضغط + لإضافة حجز جديد', style: TextStyle(color: AppColors.textHint)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) => _BookingTile(booking: list[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bookings/new'),
        icon: const Icon(Icons.add),
        label: const Text('حجز جديد'),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'ar');
    final statusColor = _statusColor(booking.status);
    final statusLabel = _statusLabel(booking.status);
    final typeIcon    = _typeIcon(booking.bookingType);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(booking.bookingNumber, style: AppTextStyles.titleSmall),
                if (booking.airlineName != null)
                  Text(booking.airlineName!, style: AppTextStyles.bodySmall),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.flight_takeoff, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(booking.origin ?? '—', style: AppTextStyles.bodySmall),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textSecondary)),
              const Icon(Icons.flight_land, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(booking.destination ?? '—', style: AppTextStyles.bodySmall),
              const Spacer(),
              if (booking.departureDate != null)
                Text(DateFormat('dd/MM/yyyy').format(booking.departureDate!),
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.info)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _infoChip(Icons.people, '${booking.adultsCount + booking.childrenCount + booking.infantsCount} أشخاص'),
              const SizedBox(width: 8),
              _infoChip(Icons.monetization_on,
                  '${fmt.format(booking.sellingPrice)} ج.م'),
              const Spacer(),
              // Progress bar for payment
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('المدفوع: ${fmt.format(booking.paidAmount)} / ${fmt.format(booking.sellingPrice)} ج.م',
                    style: AppTextStyles.labelSmall),
                const SizedBox(height: 4),
                SizedBox(
                  width: 120,
                  height: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: booking.sellingPrice > 0 ? (booking.paidAmount / booking.sellingPrice).clamp(0, 1) : 0,
                      backgroundColor: AppColors.neutralLight,
                      valueColor: AlwaysStoppedAnimation(
                          booking.paidAmount >= booking.sellingPrice ? AppColors.success : AppColors.warning),
                    ),
                  ),
                ),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) => Row(children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(text, style: AppTextStyles.labelSmall),
      ]);

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return AppColors.confirmed;
      case 'completed': return AppColors.completed;
      case 'cancelled': return AppColors.cancelled;
      case 'refunded':  return AppColors.refunded;
      default: return AppColors.pending;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed': return 'مؤكد';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      case 'refunded':  return 'مسترد';
      default: return 'معلق';
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'flight': return Icons.flight;
      case 'hotel':  return Icons.hotel;
      case 'tour':   return Icons.tour;
      case 'visa':   return Icons.credit_card;
      default: return Icons.travel_explore;
    }
  }
}
