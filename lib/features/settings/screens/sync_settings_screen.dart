// lib/features/settings/screens/sync_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  bool _syncing = false;

  void _runSync() async {
    setState(() => _syncing = true);
    // Simulate sync
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت المزامنة مع الخادم بنجاح ✅'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('إعدادات المزامنة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cloud Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              const Icon(Icons.cloud_done, size: 64, color: AppColors.success),
              const SizedBox(height: 16),
              Text('متصل بالخادم السحابي', style: AppTextStyles.titleMedium),
              const SizedBox(height: 4),
              const Text('آخر مزامنة: منذ 5 دقائق', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _syncing ? null : _runSync,
                  icon: _syncing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                  label: const Text('مزامنة الآن', style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Settings Options
          Text('خيارات المزامنة', style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          _SettingTile(
            title: 'المزامنة التلقائية',
            subtitle: 'مزامنة البيانات فور توفر اتصال بالإنترنت',
            value: true,
            onChanged: (v) {},
          ),
          _SettingTile(
            title: 'المزامنة عبر Wi-Fi فقط',
            subtitle: 'عدم استخدام بيانات الهاتف لتوفير الباقة',
            value: false,
            onChanged: (v) {},
          ),
          const SizedBox(height: 20),
          
          // Database Actions
          Text('إدارة قاعدة البيانات', style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          ListTile(
            onTap: () => context.push('/settings/backup'),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.backup, color: AppColors.info),
            title: Text('النسخ الاحتياطي', style: AppTextStyles.bodyMedium),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title, style: AppTextStyles.bodyMedium),
        subtitle: Text(subtitle, style: AppTextStyles.labelSmall),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
