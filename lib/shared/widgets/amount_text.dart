// lib/shared/widgets/amount_text.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AmountText extends StatelessWidget {
  final double  amount;
  final String  currency;
  final bool    showSign;
  final bool    colorize;
  final TextStyle? style;

  const AmountText({
    super.key,
    required this.amount,
    this.currency = 'EGP',
    this.showSign = false,
    this.colorize = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final fmt    = NumberFormat('#,##0.00', 'ar_EG');
    final isPos  = amount >= 0;
    final sign   = showSign ? (isPos ? '+' : '-') : '';
    final color  = colorize
        ? (isPos ? AppColors.credit : AppColors.debit)
        : AppColors.textPrimary;

    return Text(
      '$sign${fmt.format(amount.abs())} $currency',
      style: (style ?? AppTextStyles.amountMedium).copyWith(
        color: color,
      ),
    );
  }
}
