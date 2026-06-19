// lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final yearlyStats    = ref.watch(yearlyStatsProvider(DateTime.now().year));
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
          ref.invalidate(yearlyStatsProvider(DateTime.now().year));
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

              // ── Revenue Chart ─────────────────────────────────
              Text('الإيرادات والأرباح', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
              yearlyStats.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) {
                  final maxRev = stats.map((e) => e.revenue).fold<double>(0, (m, e) => e > m ? e : m);
                  final maxY = maxRev > 0 ? maxRev * 1.2 : 100.0;
                  return Container(
                    height: 300,
                    padding: const EdgeInsets.only(top: 30, bottom: 10, left: 16, right: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
                                if (value < 1 || value > 12) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(months[value.toInt() - 1], style: const TextStyle(fontSize: 10)),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: stats.map((stat) {
                          return BarChartGroupData(
                            x: stat.month,
                            barRods: [
                              BarChartRodData(toY: stat.revenue, color: AppColors.primary, width: 6, borderRadius: BorderRadius.circular(2)),
                              BarChartRodData(toY: stat.profit, color: AppColors.success, width: 6, borderRadius: BorderRadius.circular(2)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Flight Dashboard ────────────────────────────────
              Text('لوحة الطيران', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
              ref.watch(flightDashboardProvider).when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (flightStats) => Row(
                  children: [
                    Expanded(child: _ReportStatCard(icon: Icons.timer, label: 'خلال 24 ساعة', value: '${flightStats['24h']}', color: AppColors.error, onTap: () {})),
                    const SizedBox(width: 10),
                    Expanded(child: _ReportStatCard(icon: Icons.access_time, label: 'خلال 48 ساعة', value: '${flightStats['48h']}', color: AppColors.warning, onTap: () {})),
                    const SizedBox(width: 10),
                    Expanded(child: _ReportStatCard(icon: Icons.assignment_late, label: 'تحتاج متابعة', value: '${flightStats['followup']}', color: AppColors.primary, onTap: () {})),
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
                data: (counts) {
                  final pending = (counts['pending'] ?? 0).toDouble();
                  final confirmed = (counts['confirmed'] ?? 0).toDouble();
                  final completed = (counts['completed'] ?? 0).toDouble();
                  final cancelled = (counts['cancelled'] ?? 0).toDouble();
                  final total = pending + confirmed + completed + cancelled;

                  if (total == 0) {
                    return const Text('لا توجد حجوزات', style: TextStyle(color: AppColors.textSecondary));
                  }

                  return Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                if (confirmed > 0) PieChartSectionData(color: AppColors.info, value: confirmed, title: '${confirmed.toInt()}', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                if (pending > 0) PieChartSectionData(color: AppColors.warning, value: pending, title: '${pending.toInt()}', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                if (completed > 0) PieChartSectionData(color: AppColors.success, value: completed, title: '${completed.toInt()}', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                if (cancelled > 0) PieChartSectionData(color: AppColors.error, value: cancelled, title: '${cancelled.toInt()}', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LegendItem(color: AppColors.info, label: 'مؤكد', value: confirmed.toInt()),
                            const SizedBox(height: 8),
                            _LegendItem(color: AppColors.warning, label: 'معلق', value: pending.toInt()),
                            const SizedBox(height: 8),
                            _LegendItem(color: AppColors.success, label: 'مكتمل', value: completed.toInt()),
                            const SizedBox(height: 8),
                            _LegendItem(color: AppColors.error, label: 'ملغي', value: cancelled.toInt()),
                          ],
                        )
                      ],
                    ),
                  );
                },
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
              const SizedBox(height: 20),

              // ── Recent Activity ────────────────────────────────
              Text('أحدث النشاطات', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    _TimelineItem(title: 'تم إصدار تذكرة', subtitle: 'حجز طيران إلى دبي', time: 'منذ ساعتين', icon: Icons.airplane_ticket, color: AppColors.info, isLast: false),
                    _TimelineItem(title: 'تم استرجاع مبلغ', subtitle: 'إلغاء حجز فندق', time: 'منذ 3 ساعات', icon: Icons.assignment_return, color: AppColors.warning, isLast: false),
                    _TimelineItem(title: 'تم إضافة عميل', subtitle: 'أحمد محمود', time: 'أمس', icon: Icons.person_add, color: AppColors.success, isLast: false),
                    _TimelineItem(title: 'تم تعديل رحلة', subtitle: 'تأجيل موعد المغادرة', time: 'منذ يومين', icon: Icons.edit, color: AppColors.primary, isLast: true),
                  ],
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label ($value)', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary)),
      ],
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

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 16),
            ),
            if (!isLast) Container(width: 2, height: 40, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
        Text(time, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
