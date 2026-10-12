import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../providers/inventory_providers.dart';

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('انبار و قطعات یدکی', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(EneftyIcons.setting_4_outline),
            tooltip: 'تعدیل موجودی',
            onPressed: () => context.push('/inventory/adjustment'),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              title: 'قلمی در انبار ثبت نشده است',
              message: 'قطعات یدکی یا مواد مصرفی را اضافه کنید.',
              actionLabel: 'افزودن قلم انبار',
              onActionPressed: () => context.push('/inventory/new'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDBEAFE),
                    child: Icon(EneftyIcons.box_bold, color: Color(0xFF2563EB)),
                  ),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('کد: ${item.code} | نوع: ${item.itemType.displayName} | واحد: ${item.unit}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(EneftyIcons.edit_2_outline, color: Color(0xFF2563EB)),
                        tooltip: 'ویرایش قلم انبار',
                        onPressed: () => context.push('/inventory/${item.id}/edit'),
                      ),
                      const Icon(EneftyIcons.arrow_left_3_outline, size: 18),
                    ],
                  ),
                  onTap: () => context.push('/inventory/${item.id}'),
                ),
              );
            },
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorState(message: e.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory/new'),
        child: const Icon(EneftyIcons.add_bold),
      ),
    );
  }
}
