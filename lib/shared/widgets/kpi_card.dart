// lib/shared/widgets/kpi_card.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool? trendPositive;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (trend != null) _TrendChip(trend: trend!, positive: trendPositive),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.kpiValue),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.kpiLabel.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final String trend;
  final bool? positive;

  const _TrendChip({required this.trend, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = positive == null
        ? AppColors.textSecondary
        : positive!
            ? AppColors.success
            : AppColors.error;
    final icon = positive == null
        ? null
        : positive!
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 10, color: color),
          Text(trend, style: AppTextStyles.kpiTrend.copyWith(color: color)),
        ],
      ),
    );
  }
}
