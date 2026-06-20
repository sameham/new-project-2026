// lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/dao/bookings_dao.dart';
import '../providers/dashboard_providers.dart';
import '../../bookings/providers/bookings_providers.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/quick_action_grid.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayRevenue   = ref.watch(todayRevenueProvider);
    final monthRevenue   = ref.watch(monthRevenueProvider);
    final monthProfits   = ref.watch(monthProfitsProvider);
    final totalDebts     = ref.watch(totalDebtsProvider);
    final upcomingCount  = ref.watch(upcomingCountProvider);
    final upcoming       = ref.watch(upcomingBookingsProvider);
    final yearlyStats    = ref.watch(yearlyStatsProvider(DateTime.now().year));
    final statusCounts   = ref.watch(bookingStatusCountsProvider);
    final fmt            = NumberFormat('#,##0', 'ar');

    String fmtAmount(AsyncValue<double> av) =>
        av.when(data: (v) => '${fmt.format(v)} ج.م', loading: () => '...', error: (_, __) => '—');

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
            const Text('صباح الخير، سامح', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            todayRevenue.when(
              data: (v) => Text('إيرادات اليوم: ${fmt.format(v)} ج.م',
                  style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
              loading: () => Text('...', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: 'مساعد الذكاء الاصطناعي',
            onPressed: () => context.push('/ai'),
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
          ref.invalidate(todayRevenueProvider);
          ref.invalidate(monthRevenueProvider);
          ref.invalidate(monthProfitsProvider);
          ref.invalidate(totalDebtsProvider);
          ref.invalidate(upcomingCountProvider);
          ref.invalidate(upcomingBookingsProvider);
          ref.invalidate(yearlyStatsProvider(DateTime.now().year));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Section 1: KPI Grid ────────────────────────────
              Row(children: [
                Expanded(
                  child: KpiCard(
                    label: 'إيرادات اليوم',
                    value: fmtAmount(todayRevenue),
                    icon: Icons.today_outlined,
                    color: AppColors.success,
                    onTap: () => context.push('/finance'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    label: 'إيرادات الشهر',
                    value: fmtAmount(monthRevenue),
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.primary,
                    onTap: () => context.push('/finance'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: KpiCard(
                    label: 'ديون مستحقة',
                    value: fmtAmount(totalDebts),
                    icon: Icons.money_off_outlined,
                    color: AppColors.error,
                    trendPositive: false,
                    onTap: () => context.push('/reports/debtors'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    label: 'رحلات قادمة',
                    value: upcomingCount.when(data: (v) => '$v', loading: () => '...', error: (_, __) => '—'),
                    icon: Icons.flight_takeoff_outlined,
                    color: AppColors.info,
                    onTap: () => context.go('/bookings'),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Section 2: Business Health ─────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text('صحة الأعمال', style: AppTextStyles.sectionTitle),
                    ]),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MiniStat(label: 'ربح الشهر', value: monthProfits.when(data: (v) => '${fmt.format(v)} ج.م', loading: () => '...', error: (_, __) => '—'), color: AppColors.success),
                        _MiniStat(label: 'مؤكد', value: statusCounts.when(data: (m) => '${m['confirmed'] ?? 0}', loading: () => '...', error: (_, __) => '—'), color: AppColors.info),
                        _MiniStat(label: 'معلق', value: statusCounts.when(data: (m) => '${m['pending'] ?? 0}', loading: () => '...', error: (_, __) => '—'), color: AppColors.warning),
                        _MiniStat(label: 'مكتمل', value: statusCounts.when(data: (m) => '${m['completed'] ?? 0}', loading: () => '...', error: (_, __) => '—'), color: AppColors.completed),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Chart
                    yearlyStats.when(
                      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stats) {
                        final maxRev = stats.map((e) => e.revenue).fold<double>(0, (m, e) => e > m ? e : m);
                        final maxY = maxRev > 0 ? maxRev * 1.2 : 100.0;
                        return SizedBox(
                          height: 200,
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
                                      const m = ['1','2','3','4','5','6','7','8','9','10','11','12'];
                                      if (value < 1 || value > 12) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(m[value.toInt() - 1], style: const TextStyle(fontSize: 10)),
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
                              barGroups: stats.map((stat) => BarChartGroupData(
                                x: stat.month,
                                barRods: [
                                  BarChartRodData(toY: stat.revenue, color: AppColors.primary, width: 6, borderRadius: BorderRadius.circular(3)),
                                  BarChartRodData(toY: stat.profit, color: AppColors.success, width: 6, borderRadius: BorderRadius.circular(3)),
                                ],
                              )).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ChartLegend(color: AppColors.primary, label: 'الإيرادات'),
                        const SizedBox(width: 16),
                        _ChartLegend(color: AppColors.success, label: 'الأرباح'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Section 3: Upcoming Flights ────────────────────
              SectionHeader(
                title: 'رحلات قادمة',
                actionLabel: 'عرض الكل ←',
                onAction: () => context.go('/bookings'),
              ),
              const SizedBox(height: 12),
              upcoming.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (list) => list.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.flight_takeoff, size: 40, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text('لا رحلات في الـ 48 ساعة القادمة', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                            Text('استرح قليلاً 😊', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                          ],
                        ),
                      )
                    : Column(
                        children: list.take(3).map((b) => BookingCard(
                          booking: b,
                          onTap: () => context.push('/bookings/${b.id}'),
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 24),

              // ── Section 4: Quick Actions ────────────────────────
              SectionHeader(title: 'إجراءات سريعة'),
              const SizedBox(height: 12),
              QuickActionGrid(
                actions: [
                  QuickAction(icon: Icons.flight_takeoff, label: 'حجز جديد', color: AppColors.primary, onTap: () => context.push('/bookings/new')),
                  QuickAction(icon: Icons.person_add_outlined, label: 'إضافة عميل', color: AppColors.success, onTap: () => context.push('/customers/new')),
                  QuickAction(icon: Icons.add_card_outlined, label: 'تحصيل دفعة', color: AppColors.info, onTap: () => context.push('/payments/new')),
                  QuickAction(icon: Icons.people_outline, label: 'العملاء', color: AppColors.secondary, onTap: () => context.go('/customers')),
                  QuickAction(icon: Icons.bar_chart_outlined, label: 'التقارير', color: AppColors.warning, onTap: () => context.push('/reports')),
                  QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'الحسابات', color: AppColors.tagVip, onTap: () => context.go('/finance')),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.kpiValue.copyWith(fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.kpiLabel, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
