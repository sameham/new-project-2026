// lib/shared/widgets/booking_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../database/app_database.dart';
import '../../features/customers/providers/customers_providers.dart';
import 'status_badge.dart';

class BookingCard extends ConsumerWidget {
  final Booking booking;
  final VoidCallback? onTap;

  const BookingCard({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(booking.customerId));
    final customerName = customerAsync.maybeWhen(
      data: (c) => c != null ? '${c.firstName} ${c.lastName}' : '—',
      orElse: () => '...',
    );

    final profit = booking.sellingPrice - booking.totalCost;
    final remaining = booking.sellingPrice - booking.paidAmount;
    final progress = booking.sellingPrice > 0
        ? (booking.paidAmount / booking.sellingPrice).clamp(0.0, 1.0)
        : 0.0;

    final fmt = NumberFormat('#,##0', 'ar');
    final dateFmt = DateFormat('dd/MM/yyyy', 'ar');

    final origin = booking.origin ?? '?';
    final dest = booking.destination ?? '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top row: route + status
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  Text(
                    '$origin → $dest',
                    style: AppTextStyles.cardTitle,
                  ),
                  const Spacer(),
                  StatusBadge(status: booking.status),
                ],
              ),
            ),
            // Row 2: customer + airline + PNR
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customerName,
                      style: AppTextStyles.cardSubtitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (booking.airlineName != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.flight, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(booking.airlineName!, style: AppTextStyles.cardSubtitle),
                  ],
                  if (booking.pnrNumber != null) ...[
                    const SizedBox(width: 8),
                    _PnrChip(pnr: booking.pnrNumber!),
                  ],
                ],
              ),
            ),
            // Row 3: date + class
            if (booking.departureDate != null || booking.travelClass != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Row(
                  children: [
                    if (booking.departureDate != null) ...[
                      Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(dateFmt.format(booking.departureDate!), style: AppTextStyles.cardSubtitle),
                    ],
                    if (booking.travelClass != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          booking.travelClass!,
                          style: AppTextStyles.labelXSmall.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Divider(height: 1),
            ),
            // Financial row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Row(
                children: [
                  _FinStat(label: 'البيع', value: fmt.format(booking.sellingPrice), color: AppColors.textPrimary),
                  _FinStat(label: 'التكلفة', value: fmt.format(booking.totalCost), color: AppColors.textSecondary),
                  _FinStat(label: 'الربح', value: fmt.format(profit), color: profit >= 0 ? AppColors.success : AppColors.error),
                ],
              ),
            ),
            // Paid / remaining + progress
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 13, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('${fmt.format(booking.paidAmount)} ج.م',
                          style: AppTextStyles.amountSmall.copyWith(color: AppColors.success)),
                      const Spacer(),
                      if (remaining > 0) ...[
                        Icon(Icons.schedule_outlined, size: 13, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text('${fmt.format(remaining)} ج.م',
                            style: AppTextStyles.amountSmall.copyWith(color: AppColors.error)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PnrChip extends StatelessWidget {
  final String pnr;
  const _PnrChip({required this.pnr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(pnr, style: AppTextStyles.labelXSmall.copyWith(color: AppColors.info, fontWeight: FontWeight.w700)),
    );
  }
}

class _FinStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FinStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelXSmall.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 2),
          Text('$value ج.م', style: AppTextStyles.amountSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
