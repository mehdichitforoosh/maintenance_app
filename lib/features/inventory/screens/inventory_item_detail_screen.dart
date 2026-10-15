import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../providers/inventory_providers.dart';

class InventoryItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const InventoryItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final txsAsync = ref.watch(stockTransactionsProvider(itemId));
    final repo = ref.watch(inventoryRepositoryProvider);

    return itemsAsync.when(
      data: (items) {
        final item = items.where((i) => i.id == itemId).firstOrNull;
        if (item == null) {
          return const Scaffold(body: Center(child: Text('کالا یافت نشد')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(EneftyIcons.edit_2_outline),
                tooltip: 'ویرایش قلم انبار',
                onPressed: () => context.push('/inventory/$itemId/edit'),
              ),
            ],
          ),
          body: FutureBuilder<double>(
            future: repo.getCurrentStock(itemId),
            builder: (context, snapshot) {
              final stock = snapshot.data ?? 0.0;
              final isLow = stock <= item.minimumStock;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'اطلاعات کالا',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (isLow ? Colors.red : Colors.green)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isLow ? 'کمبود موجودی' : 'موجودی کافی',
                                  style: TextStyle(
                                    color: isLow ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _row(context, 'کد کالا', item.code),
                          _row(context, 'نوع', item.itemType.displayName),
                          _row(context, 'موجودی فعلی', '$stock ${item.unit}'),
                          _row(
                            context,
                            'حداقل موجودی',
                            '${item.minimumStock} ${item.unit}',
                          ),
                          if (item.defaultUnitCost != null)
                            _row(
                              context,
                              'قیمت واحد پیش‌فرض',
                              '${item.defaultUnitCost} تومان',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'تاریخچه گردش انبار (Ledger)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  txsAsync.when(
                    data: (txs) {
                      if (txs.isEmpty) {
                        return const Text('تراکنشی ثبت نشده است.');
                      }
                      return Column(
                        children: txs
                            .map(
                              (tx) => Card(
                                child: ListTile(
                                  leading: const Icon(
                                    EneftyIcons.box_bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                  title: Text(
                                    '${tx.transactionType.displayName}: ${tx.quantity} ${item.unit}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'تاریخ: ${tx.transactionDate}${tx.notes != null ? ' | ${tx.notes}' : ''}',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const AppLoading(),
                    error: (e, _) => Text('خطا: $e'),
                  ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
