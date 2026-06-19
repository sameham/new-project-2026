// lib/features/customers/screens/customer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/tables/bookings_table.dart';
import '../../../database/tables/payments_table.dart';
import '../../bookings/providers/bookings_providers.dart';
import '../../payments/providers/payments_providers.dart';
import '../../../database/app_database.dart';
import '../providers/customers_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync  = ref.watch(customerByIdProvider(customerId));
    final bookingsAsync  = ref.watch(bookingsByCustomerProvider(customerId));
    final paymentsStream = ref.watch(paymentsByCustomerStreamProvider(customerId));
    final fmt = NumberFormat('#,##0.00', 'ar');

    return customerAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('خطأ: $e'))),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('العميل')),
            body: const Center(child: Text('لم يتم العثور على العميل')),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text('${customer.firstName} ${customer.lastName}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/customers/${customerId}/edit'),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'الحجوزات', icon: Icon(Icons.flight, size: 18)),
                  Tab(text: 'المدفوعات', icon: Icon(Icons.payment, size: 18)),
                ],
              ),
            ),
            body: Column(
              children: [
                // ── Profile Header ──────────────────────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            child: Text(
                              '${customer.firstName.isNotEmpty ? customer.firstName[0] : ''}${customer.lastName.isNotEmpty ? customer.lastName[0] : ''}',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${customer.firstName} ${customer.lastName}',
                                    style: AppTextStyles.titleLarge),
                                const SizedBox(height: 2),
                                Text(customer.customerCode,
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                                const SizedBox(height: 2),
                                Row(children: [
                                  const Icon(Icons.phone, size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(customer.phone, style: AppTextStyles.bodySmall),
                                ]),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('الرصيد', style: AppTextStyles.labelSmall),
                              Text(
                                '${fmt.format(customer.balance)} ج.م',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: customer.balance >= 0 ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Quick info row
                      Row(
                        children: [
                          if (customer.nationality != null) _InfoChip(Icons.flag, customer.nationality!),
                          if (customer.passportNumber != null) _InfoChip(Icons.credit_card, customer.passportNumber!),
                          if (customer.email != null) _InfoChip(Icons.email, customer.email!),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ── Tabs ─────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    children: [
                      // Bookings tab
                      bookingsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('خطأ: $e')),
                        data: (bookings) => bookings.isEmpty
                            ? _emptyTab('لا توجد حجوزات', Icons.flight_outlined)
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: bookings.length,
                                itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
                              ),
                      ),
                      // Payments tab
                      paymentsStream.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('خطأ: $e')),
                        data: (payments) => payments.isEmpty
                            ? _emptyTab('لا توجد مدفوعات', Icons.payment_outlined)
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: payments.length,
                                itemBuilder: (_, i) => _PaymentCard(payment: payments[i]),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'booking',
                  backgroundColor: AppColors.info,
                  onPressed: () => context.push('/bookings/new'),
                  child: const Icon(Icons.flight_takeoff, size: 18),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'payment',
                  onPressed: () => context.push('/payments/new'),
                  icon: const Icon(Icons.add_card),
                  label: const Text('دفعة'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyTab(String msg, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo')),
          ],
        ),
      );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.labelSmall),
        ]),
      );
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.pending;
    if (booking.status == 'confirmed')  statusColor = AppColors.confirmed;
    if (booking.status == 'completed')  statusColor = AppColors.completed;
    if (booking.status == 'cancelled')  statusColor = AppColors.cancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 4, height: 50,
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(booking.bookingNumber, style: AppTextStyles.titleSmall),
              const SizedBox(height: 2),
              Text(
                '${booking.origin ?? ''} ← ${booking.destination ?? ''}',
                style: AppTextStyles.bodySmall,
              ),
              if (booking.departureDate != null)
                Text(DateFormat('dd/MM/yyyy').format(booking.departureDate!),
                    style: AppTextStyles.labelSmall),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${booking.sellingPrice.toStringAsFixed(0)} ج.م',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3))),
                child: Text(_statusLabel(booking.status),
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: statusColor)),
              ),
            ]),
          ]),
        ),
      ),
    );
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
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isIn = payment.direction == 'in';
    final fmt  = NumberFormat('#,##0.00', 'ar');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isIn ? AppColors.success : AppColors.error).withOpacity(0.1),
          child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIn ? AppColors.success : AppColors.error, size: 20),
        ),
        title: Text(payment.paymentNumber, style: AppTextStyles.titleSmall),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy').format(payment.paymentDate)} • ${_methodLabel(payment.paymentMethod)}',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Text(
          '${isIn ? '+' : '-'}${fmt.format(payment.amount)} ج.م',
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isIn ? AppColors.success : AppColors.error),
        ),
      ),
    );
  }

  String _methodLabel(String m) {
    const map = {
      'cash': 'نقداً', 'bank_transfer': 'تحويل بنكي',
      'credit_card': 'بطاقة ائتمان', 'instapay': 'إنستاباي',
      'vodafone_cash': 'فودافون كاش', 'other': 'أخرى',
    };
    return map[m] ?? m;
  }
}
