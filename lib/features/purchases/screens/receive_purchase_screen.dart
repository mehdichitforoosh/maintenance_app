import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../providers/purchase_providers.dart';

class ReceivePurchaseScreen extends ConsumerStatefulWidget {
  final String purchaseOrderId;

  const ReceivePurchaseScreen({super.key, required this.purchaseOrderId});

  @override
  ConsumerState<ReceivePurchaseScreen> createState() =>
      _ReceivePurchaseScreenState();
}

class _ReceivePurchaseScreenState extends ConsumerState<ReceivePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _qtyControllers = {};
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _receive(List items) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(purchaseRepositoryProvider);
      final lines = <Map<String, dynamic>>[];

      for (final item in items) {
        final ctrl = _qtyControllers[item.id];
        if (ctrl != null && ctrl.text.trim().isNotEmpty) {
          final qty = double.tryParse(ctrl.text.trim()) ?? 0.0;
          if (qty > 0) {
            lines.add({
              'purchase_order_item_id': item.id,
              'received_quantity': qty,
            });
          }
        }
      }

      if (lines.isNotEmpty) {
        await repo.receiveItems(
          purchaseOrderId: widget.purchaseOrderId,
          receivedLines: lines,
        );
      }

      ref.invalidate(purchaseOrderItemsProvider(widget.purchaseOrderId));
      ref.invalidate(inventoryItemsProvider);
      ref.invalidate(lowStockItemsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(
      purchaseOrderItemsProvider(widget.purchaseOrderId),
    );
    final inventoryItemsAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ثبت رسید دریافت کالا')),
      body: itemsAsync.when(
        data: (orderItems) {
          for (final item in orderItems) {
            _qtyControllers.putIfAbsent(
              item.id,
              () =>
                  TextEditingController(text: item.orderedQuantity.toString()),
            );
          }

          return inventoryItemsAsync.when(
            data: (invItems) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text(
                        'مقادیر دریافتی اقلام را وارد کنید:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...orderItems.map((item) {
                        final invItem = invItems
                            .where((i) => i.id == item.itemId)
                            .firstOrNull;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invItem?.name ?? 'کالا',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'مقدار سفارش‌داده شده: ${AppNumberFormat.decimal(item.orderedQuantity)} ${invItem?.unit ?? ''}',
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _qtyControllers[item.id],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'مقدار دریافتی *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      AppValidators.nonNegativeNumber(
                                        v,
                                        fieldName: 'مقدار دریافتی',
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () => _receive(orderItems),
                        child: const Text('ثبت و به‌روزرسانی موجودی انبار'),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const AppLoading(),
            error: (e, _) => Center(child: Text('خطا: $e')),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('خطا: $e')),
      ),
    );
  }
}
