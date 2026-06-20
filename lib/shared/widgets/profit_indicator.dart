// lib/shared/widgets/profit_indicator.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ProfitIndicator extends StatelessWidget {
  final double profit;
  final double margin;
  final bool compact;

  const ProfitIndicator({
    super.key,
    required this.profit,
    required this.margin,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = profit >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    final fmt = NumberFormat('#,##0', 'ar');
    final pct = margin.abs().toStringAsFixed(1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: compact ? 12 : 14,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          compact
              ? '${fmt.format(profit.abs())} ج.م'
              : 'الربح: ${fmt.format(profit.abs())} ج.م (+$pct%)',
          style: (compact ? AppTextStyles.amountSmall : AppTextStyles.bodySmall)
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
