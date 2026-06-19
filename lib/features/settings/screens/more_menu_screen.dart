import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المزيد', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuItem(context, 'العملاء', Icons.people, '/customers', AppColors.primary),
          _buildMenuItem(context, 'التقارير', Icons.bar_chart, '/reports', AppColors.info),
          _buildMenuItem(context, 'المصروفات', Icons.money_off, '/expenses', AppColors.error),
          _buildMenuItem(context, 'الخزينة (Ledger)', Icons.account_balance, '/ledger', AppColors.warning),
          const Divider(height: 32),
          _buildMenuItem(context, 'المزامنة السحابية', Icons.cloud_sync, '/settings/sync', AppColors.secondary),
          _buildMenuItem(context, 'النسخ الاحتياطي', Icons.backup, '/settings/backup', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, String route, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => context.push(route),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
