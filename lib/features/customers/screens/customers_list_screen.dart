// lib/features/customers/screens/customers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/tables/customers_table.dart';
import '../../../database/app_database.dart';
import '../providers/customers_providers.dart';

class CustomersListScreen extends ConsumerWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(filteredCustomersProvider);
    final searchCtrl = TextEditingController(text: ref.read(customerSearchProvider));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('العملاء'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: searchCtrl,
              onChanged: (v) => ref.read(customerSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الهاتف أو رقم الجواز...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: ref.watch(customerSearchProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchCtrl.clear();
                          ref.read(customerSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: customers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 72, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('لا يوجد عملاء', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('اضغط + لإضافة عميل جديد', style: TextStyle(color: AppColors.textHint)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) => _CustomerTile(customer: list[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customers/new'),
        icon: const Icon(Icons.person_add),
        label: const Text('عميل جديد'),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    final initials =
        '${customer.firstName.isNotEmpty ? customer.firstName[0] : ''}${customer.lastName.isNotEmpty ? customer.lastName[0] : ''}';
    final balance = customer.balance;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/customers/${customer.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(initials,
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${customer.firstName} ${customer.lastName}',
                        style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.phone, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(customer.phone, style: AppTextStyles.bodySmall),
                      if (customer.customerCode.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.tag, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(customer.customerCode, style: AppTextStyles.bodySmall),
                      ],
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: balance >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
