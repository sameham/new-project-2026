// lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/dashboard_providers.dart';
import '../../bookings/providers/bookings_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerCount  = ref.watch(customerCountProvider);
    final profits        = ref.watch(profitsProvider);
    final monthProfits   = ref.watch(monthProfitsProvider);
    final totalDebts     = ref.watch(totalDebtsProvider);
    final bookingsCount  = ref.watch(bookingsCountProvider);
    final statusCounts   = ref.watch(bookingStatusCountsProvider);
    final upcoming       = ref.watch(upcomingBookingsProvider);
    final fmt = NumberFormat('#,##0', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('صباح الخير، سامح 👋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            monthProfits.when(
              data: (v) => Text('إجمالي الأرباح هذا الشهر: ${fmt.format(v)} ج.م', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
              loading: () => Text('إجمالي الأرباح هذا الشهر: ...', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
              error: (_, __) => Text('إجمالي الأرباح هذا الشهر: —', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث',
            onPressed: () {
              // TODO: Implement Search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'الإشعارات',
            onPressed: () {
              // TODO: Implement Notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () => context.push('/settings/sync'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerCountProvider);
          ref.invalidate(profitsProvider);
          ref.invalidate(monthProfitsProvider);
          ref.invalidate(totalDebtsProvider);
          ref.invalidate(bookingsCountProvider);
          ref.invalidate(bookingStatusCountsProvider);
          ref.invalidate(upcomingBookingsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── KPI Cards ──────────────────────────────────────
              Row(children: [
                Expanded(child: _KpiCard(
                  label: 'الأرباح',
                  value: profits.when(data: (v) => '${fmt.format(v)} ج.م', loading: () => '...', error: (_, __) => '—'),
                  onTap: () => context.push('/reports/sales'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _KpiCard(
                  label: 'العملاء',
                  value: customerCount.when(data: (v) => '$v', loading: () => '...', error: (_, __) => '—'),
                  onTap: () => context.go('/customers'),
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _KpiCard(
                  label: 'المستحق',
                  value: totalDebts.when(data: (v) => '${fmt.format(v)} ج.م', loading: () => '...', error: (_, __) => '—'),
                  onTap: () => context.push('/reports/debtors'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _KpiCard(
                  label: 'الحجوزات',
                  value: bookingsCount.when(data: (v) => '$v', loading: () => '...', error: (_, __) => '—'),
                  onTap: () => context.go('/bookings'),
                )),
              ]),
              const SizedBox(height: 24),

              // ── Quick Actions ──────────────────────────────────
              Text('الإجراءات السريعة', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ActionItem(icon: Icons.airplane_ticket, label: 'إصدار\nتذكرة', color: AppColors.info, onTap: () => context.push('/bookings/new')),
                    const SizedBox(width: 20),
                    _ActionItem(icon: Icons.flight_takeoff, label: 'حجز\nجديد', color: AppColors.primary, onTap: () => context.push('/bookings/new')),
                    const SizedBox(width: 20),
                    _ActionItem(icon: Icons.assignment_return, label: 'استرجاع', color: AppColors.warning, onTap: () {
                      ref.read(bookingStatusFilterProvider.notifier).state = 'cancelled';
                      context.go('/bookings');
                    }),
                    const SizedBox(width: 20),
                    _ActionItem(icon: Icons.person_add, label: 'إضافة\nعميل', color: AppColors.success, onTap: () => context.push('/customers/new')),
                    const SizedBox(width: 20),
                    _ActionItem(icon: Icons.add_card, label: 'تحصيل\nدفعة', color: AppColors.secondary, onTap: () => context.push('/payments/new')),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Booking Status ─────────────────────────────────
              Text('حالة الحجوزات', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
              statusCounts.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (counts) => Row(children: [
                  _StatusChip(label: 'معلق',   count: counts['pending']   ?? 0, color: AppColors.warning),
                  const SizedBox(width: 8),
                  _StatusChip(label: 'مؤكد',   count: counts['confirmed'] ?? 0, color: AppColors.info),
                  const SizedBox(width: 8),
                  _StatusChip(label: 'مكتمل',  count: counts['completed'] ?? 0, color: AppColors.success),
                  const SizedBox(width: 8),
                  _StatusChip(label: 'ملغي',   count: counts['cancelled'] ?? 0, color: AppColors.error),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Important Reports ──────────────────────────────────
              Text('تقارير هامة', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ReportStatCard(
                      icon: Icons.money_off,
                      label: 'مبالغ مستحقة',
                      value: totalDebts.asData?.value != null ? fmt.format(totalDebts.asData!.value) : '-',
                      color: AppColors.error,
                      onTap: () => context.push('/reports/debtors')
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ReportStatCard(
                      icon: Icons.flight_land,
                      label: 'طيران مسترجع',
                      value: '${statusCounts.asData?.value['cancelled'] ?? 0}',
                      color: AppColors.warning,
                      onTap: () {
                        ref.read(bookingStatusFilterProvider.notifier).state = 'cancelled';
                        context.go('/bookings');
                      }
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ReportStatCard(
                      icon: Icons.schedule,
                      label: 'طيران مؤجل',
                      value: '${statusCounts.asData?.value['pending'] ?? 0}',
                      color: AppColors.info,
                      onTap: () {
                        ref.read(bookingStatusFilterProvider.notifier).state = 'pending';
                        context.go('/bookings');
                      }
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Upcoming Flights ───────────────────────────────
              Text('رحلات قادمة (48 ساعة)', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
              upcoming.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (list) => list.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text('لا توجد رحلات قادمة في الـ 48 ساعة القادمة',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    : Column(
                        children: list.map((b) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.infoLight,
                              child: Icon(Icons.flight_takeoff, color: AppColors.info, size: 20),
                            ),
                            title: Text(b.bookingNumber, style: AppTextStyles.titleSmall),
                            subtitle: Text(
                              '${b.origin ?? ''} ← ${b.destination ?? ''}',
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: Text(
                              b.departureDate != null
                                  ? DateFormat('dd/MM HH:mm').format(b.departureDate!)
                                  : '',
                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.info),
                            ),
                            onTap: () => context.push('/bookings/${b.id}'),
                          ),
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _KpiCard({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ReportStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ReportStatCard({required this.icon, required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
