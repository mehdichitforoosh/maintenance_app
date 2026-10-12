import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/section_header.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../providers/purchase_providers.dart';

class PurchaseOrderDetailScreen extends ConsumerWidget {
  final String purchaseOrderId;

  const PurchaseOrderDetailScreen({super.key, required this.purchaseOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);
    final itemsAsync = ref.watch(purchaseOrderItemsProvider(purchaseOrderId));
    final inventoryItemsAsync = ref.watch(inventoryItemsProvider);

    return FutureBuilder(
      future: purchaseRepo.getPurchaseOrderById(purchaseOrderId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: AppLoading());
        final po = snapshot.data;
        if (po == null) return const Scaffold(body: Center(child: Text('سفارش خرید یافت نشد')));

        return Scaffold(
          appBar: AppBar(
            title: Text('سفارش خرید ${po.purchaseOrderNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(EneftyIcons.edit_2_outline),
                tooltip: 'ویرایش سفارش',
                onPressed: () => context.push('/purchases/$purchaseOrderId/edit'),
              ),
            ],
          ),
          body: ListView(
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
                          Text('اطلاعات سفارش', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(po.status.displayName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _row('تأمین‌کننده', po.supplierName ?? '-'),
                      _row('تاریخ سفارش', po.orderDate),
                      if (po.notes != null && po.notes!.isNotEmpty) _row('یادداشت', po.notes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (po.status != PurchaseOrderStatus.received && po.status != PurchaseOrderStatus.cancelled)
                FilledButton.icon(
                  onPressed: () => context.push('/purchases/$purchaseOrderId/receive'),
                  icon: const Icon(EneftyIcons.box_bold),
                  label: const Text('ثبت رسید دریافت کالا (Goods Receipt)'),
                ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'اقلام سفارش‌داده شده'),
              itemsAsync.when(
                data: (lines) {
                  if (lines.isEmpty) return const Text('قلمی در این سفارش نیست.');
                  return inventoryItemsAsync.when(
                    data: (invItems) {
                      return Column(
                        children: lines.map((line) {
                          final invItem = invItems.where((i) => i.id == line.itemId).firstOrNull;
                          return Card(
                            child: ListTile(
                              leading: const Icon(EneftyIcons.box_bold, color: Color(0xFF2563EB)),
                              title: Text(invItem?.name ?? 'کالای نامشخص', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('مقدار: ${line.orderedQuantity} ${invItem?.unit ?? ''} | قیمت واحد: ${line.unitPrice} تومان'),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const AppLoading(),
                    error: (e, _) => Text('خطا: $e'),
                  );
                },
                loading: () => const AppLoading(),
                error: (e, _) => Text('خطا: $e'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
