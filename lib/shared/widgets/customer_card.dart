// lib/shared/widgets/customer_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../database/tables/customers_table.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;

  const CustomerCard({super.key, required this.customer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'ar');
    final hasDebt = customer.balance > 0;
    final initials = _initials(customer.firstName, customer.lastName);
    final avatarColor = _colorFromName(customer.firstName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: avatarColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${customer.firstName} ${customer.lastName}',
                    style: AppTextStyles.cardTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(customer.phone, style: AppTextStyles.cardSubtitle),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: [
                      _CodeChip(code: customer.customerCode),
                      ..._tagChips(customer.tags),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Balance
            if (hasDebt)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                  const SizedBox(height: 2),
                  Text(
                    '${fmt.format(customer.balance)} ج.م',
                    style: AppTextStyles.amountSmall.copyWith(color: AppColors.error),
                  ),
                  Text('مدين', style: AppTextStyles.labelXSmall.copyWith(color: AppColors.error)),
                ],
              )
            else
              Icon(Icons.chevron_left, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0] : '';
    final l = last.isNotEmpty ? last[0] : '';
    return '$f$l';
  }

  Color _colorFromName(String name) {
    final colors = [
      AppColors.primary, AppColors.info, AppColors.success,
      AppColors.warning, AppColors.tagVip, AppColors.tagCorporate,
    ];
    if (name.isEmpty) return AppColors.primary;
    return colors[name.codeUnitAt(0) % colors.length];
  }

  List<Widget> _tagChips(String tagsJson) {
    try {
      if (tagsJson == '[]' || tagsJson.isEmpty) return [];
      final stripped = tagsJson.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
      final tags = stripped.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      return tags.take(2).map((tag) => _TagBadge(tag: tag)).toList();
    } catch (_) {
      return [];
    }
  }
}

class _CodeChip extends StatelessWidget {
  final String code;
  const _CodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(code, style: AppTextStyles.labelXSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String tag;
  const _TagBadge({required this.tag});

  Color get _color {
    switch (tag.toLowerCase()) {
      case 'vip': return AppColors.tagVip;
      case 'corporate': return AppColors.tagCorporate;
      case 'debtor': case 'مدين': return AppColors.tagDebtor;
      case 'frequent': case 'متكرر': return AppColors.tagFrequent;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(tag, style: AppTextStyles.labelXSmall.copyWith(color: _color, fontWeight: FontWeight.w600)),
    );
  }
}
