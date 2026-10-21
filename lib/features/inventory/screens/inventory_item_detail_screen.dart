import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/section_header.dart';
import '../providers/inventory_providers.dart';
import 'widgets/inventory_current_stock_gauge.dart';
import 'widgets/inventory_item_detail_sections.dart';
import 'widgets/inventory_movement_chart.dart';
import 'widgets/inventory_stock_history_chart.dart';

class InventoryItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const InventoryItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(allInventoryItemsProvider);
    final txsAsync = ref.watch(stockTransactionsProvider(itemId));
    final stockAsync = ref.watch(inventoryCurrentStockProvider(itemId));

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
          body: stockAsync.when(
            data: (stock) {
              final isLow = stock <= item.minimumStock;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  InventoryItemSpecificationsCard(
                    item: item,
                    isLowStock: isLow,
                  ),
                  InventoryCurrentStockGauge(
                    stock: stock,
                    minimumStock: item.minimumStock,
                    unit: item.unit,
                  ),
                  txsAsync.when(
                    data: (transactions) => Column(
                      children: [
                        InventoryStockHistoryChart(
                          transactions: transactions,
                          minimumStock: item.minimumStock,
                          unit: item.unit,
                        ),
                        InventoryMovementChart(
                          transactions: transactions,
                          unit: item.unit,
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(title: 'تاریخچه گردش انبار'),
                  txsAsync.when(
                    data: (txs) {
                      if (txs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('تراکنشی ثبت نشده است.'),
                        );
                      }
                      return Column(
                        children: txs
                            .map(
                              (transaction) => StockTransactionTile(
                                transaction: transaction,
                                unit: item.unit,
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const AppLoading(),
                    error: (e, _) => AppErrorState(message: e.toString()),
                  ),
                ],
              );
            },
            loading: () => const AppLoading(),
            error: (error, _) => AppErrorState(message: error.toString()),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
