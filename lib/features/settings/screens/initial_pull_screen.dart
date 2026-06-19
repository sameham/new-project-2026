// lib/features/settings/screens/initial_pull_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class InitialPullScreen extends StatefulWidget {
  const InitialPullScreen({super.key});

  @override
  State<InitialPullScreen> createState() => _InitialPullScreenState();
}

class _InitialPullScreenState extends State<InitialPullScreen> {
  double _progress = 0;
  String _status = 'جاري الاتصال بالخادم...';

  @override
  void initState() {
    super.initState();
    _startPull();
  }

  void _startPull() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() { _progress = 0.2; _status = 'تحميل بيانات العملاء...'; });
    
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() { _progress = 0.5; _status = 'تحميل الحجوزات...'; });
    
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() { _progress = 0.8; _status = 'تحميل المدفوعات والمصروفات...'; });
    
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() { _progress = 1.0; _status = 'اكتملت المزامنة بنجاح!'; });
    
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_download, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'المزامنة الأولية',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_status, style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              SizedBox(
                width: 300,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 16),
              Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
