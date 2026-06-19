// lib/shared/widgets/status_badge.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10, vertical: 4,
      ),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color:      color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) _resolve(String s) {
    switch (s) {
      case 'pending':   return ('معلق',   AppColors.pending);
      case 'confirmed': return ('مؤكد',   AppColors.confirmed);
      case 'completed': return ('مكتمل',  AppColors.completed);
      case 'cancelled': return ('ملغي',   AppColors.cancelled);
      case 'refunded':  return ('مسترد',  AppColors.refunded);
      case 'synced':    return ('متزامن', AppColors.success);
      case 'pending_sync': return ('معلق المزامنة', AppColors.warning);
      default:          return (s,        AppColors.textSecondary);
    }
  }
}
