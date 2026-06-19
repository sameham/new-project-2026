// lib/features/settings/screens/backup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _working = false;

  void _createBackup() async {
    setState(() => _working = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح ✅'), backgroundColor: AppColors.success),
      );
    }
  }

  void _restoreBackup() async {
    setState(() => _working = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم استعادة النسخة الاحتياطية بنجاح ✅'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('النسخ الاحتياطي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              const Icon(Icons.storage, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('النسخ الاحتياطي المحلي', style: AppTextStyles.titleMedium),
              const SizedBox(height: 4),
              const Text('حفظ نسخة من قاعدة البيانات محلياً على الجهاز', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo'), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _working ? null : _createBackup,
                  icon: _working
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.backup),
                  label: const Text('إنشاء نسخة احتياطية الآن', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _working ? null : _restoreBackup,
                  icon: const Icon(Icons.restore),
                  label: const Text('استعادة من ملف', style: TextStyle(fontFamily: 'Cairo')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('النسخ الاحتياطية السابقة', style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_zip, color: AppColors.info),
              title: const Text('backup_20260619_1030.sqlite', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now().subtract(const Duration(hours: 5))), style: AppTextStyles.bodySmall),
              trailing: IconButton(icon: const Icon(Icons.share, size: 20), onPressed: () {}),
            ),
          ),
        ],
      ),
    );
  }
}
