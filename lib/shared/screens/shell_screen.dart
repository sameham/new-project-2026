// lib/shared/screens/shell_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/bookings'))  return 1;
    if (location.startsWith('/finance'))   return 2;
    if (location.startsWith('/more'))      return 3;
    return 0; // dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/');         break;
      case 1: context.go('/bookings'); break;
      case 2: context.go('/finance');  break;
      case 3: context.go('/more');     break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 32),
        height: 60,
        width: 60,
        child: FloatingActionButton(
          backgroundColor: AppColors.secondary,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onPressed: () {
            _showQuickActions(context);
          },
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, -4)),
          ],
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, idx, Icons.dashboard_outlined, Icons.dashboard, 'الرئيسية'),
              _buildNavItem(context, 1, idx, Icons.flight_outlined, Icons.flight, 'الحجوزات'),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(context, 2, idx, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'المالية'),
              _buildNavItem(context, 3, idx, Icons.more_horiz_outlined, Icons.more_horiz, 'المزيد'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, int currentIndex, IconData iconOutlined, IconData iconSolid, String label) {
    final isSelected = index == currentIndex;
    final color = isSelected ? AppColors.secondary : AppColors.textHint;
    final icon = isSelected ? iconSolid : iconOutlined;

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إجراء سريع', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.infoLight, child: Icon(Icons.flight_takeoff, color: AppColors.info)),
              title: const Text('إصدار تذكرة / حجز جديد'),
              onTap: () { Navigator.pop(c); context.push('/bookings/new'); },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.successLight, child: Icon(Icons.person_add, color: AppColors.success)),
              title: const Text('إضافة عميل جديد'),
              onTap: () { Navigator.pop(c); context.push('/customers/new'); },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.warningLight, child: Icon(Icons.add_card, color: AppColors.warning)),
              title: const Text('تحصيل دفعة'),
              onTap: () { Navigator.pop(c); context.push('/payments/new'); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
