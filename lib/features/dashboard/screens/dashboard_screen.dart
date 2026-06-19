// lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerCount  = ref.watch(customerCountProvider);
    final profits        = ref.watch(profitsProvider);
    final monthRevenue   = ref.watch(monthRevenueProvider);
    final totalDebts     = ref.watch(totalDebtsProvider);
    final statusCounts   = ref.watch(bookingStatusCountsProvider);
    final upcoming       = ref.watch(upcomingBookingsProvider);
    final fmt = NumberFormat('#,##0.00', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('وكالة سامح عبدالله', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('للسفر والسياحة', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_outlined),
            tooltip: 'المزامنة',
            onPressed: () => context.push('/settings/sync'),
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
          ref.invalidate(monthRevenueProvider);
          ref.invalidate(totalDebtsProvider);
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
                  label: 'العملاء',
                  value: customerCount.when(data: (v) => '$v', loading: () => '...', error: (_, __) => '—'),
                  icon: Icons.people,
                  color: AppColors.primary,
                  onTap: () => context.go('/customers'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _KpiCard(
                  label: 'الأرباح',
                  value: profits.when(data: (v) => '${fmt.format(v)} ج.م', loading: () => '...', error: (_, __) => '—'),
                  icon: Icons.monetization_on,
                  color: AppColors.success,
                  onTap: () => context.push('/reports/sales'),
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _KpiCard(
                  label: 'إيرادات الشهر',
                  value: monthRevenue.when(data: (v) => '${fmt.format(v)} ج.م', loading: () => '...', error: (_, __) => '—'),
                  icon: Icons.trending_up,
                  color: AppColors.info,
                  onTap: () => context.push('/reports/sales'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _KpiCard(
                  label: 'المتبقي على العملاء',
                  value: totalDebts.when(data: (v) => '${fmt.format(v)} ج.م', loading: () => '...', error: (_, __) => '—'),
                  icon: Icons.account_balance_wallet,
                  color: AppColors.warning,
                  onTap: () => context.push('/reports/debtors'),
                )),
              ]),
              const SizedBox(height: 20),

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

              // ── Quick Actions ──────────────────────────────────
              Text('الإجراءات السريعة', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
                children: [
                  _ActionItem(icon: Icons.person_add, label: 'عميل جديد', color: AppColors.primary,    onTap: () => context.push('/customers/new')),
                  _ActionItem(icon: Icons.flight_takeoff, label: 'حجز جديد', color: AppColors.info,   onTap: () => context.push('/bookings/new')),
                  _ActionItem(icon: Icons.add_card,    label: 'تسجيل دفعة', color: AppColors.success,  onTap: () => context.push('/payments/new')),
                  _ActionItem(icon: Icons.receipt,     label: 'مصروف جديد', color: AppColors.warning,  onTap: () => context.push('/expenses')),
                  _ActionItem(icon: Icons.people,      label: 'العملاء',   color: AppColors.primary,   onTap: () => context.go('/customers')),
                  _ActionItem(icon: Icons.flight,      label: 'الحجوزات',  color: AppColors.info,      onTap: () => context.go('/bookings')),
                  _ActionItem(icon: Icons.book_outlined, label: 'الدفتر', color: AppColors.secondary,  onTap: () => context.push('/ledger')),
                  _ActionItem(icon: Icons.bar_chart,   label: 'التقارير',  color: AppColors.error,     onTap: () => context.go('/reports')),
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
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ]),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.titleLarge.copyWith(color: color, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.bodySmall),
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
