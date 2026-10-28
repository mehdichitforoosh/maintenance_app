import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_responsive_container.dart';
import '../../../core/widgets/section_header.dart';
import '../../inventory/providers/inventory_providers.dart';

class PurchaseReceiptDetailScreen extends ConsumerWidget {
  final String receiptId;

  const PurchaseReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(purchaseReceiptDetailProvider(receiptId));

    return Scaffold(
      appBar: AppBar(title: const Text('جزئیات رسید خرید')),
      body: receiptAsync.when(
        data: (receipt) {
          if (receipt == null) {
            return const Center(child: Text('رسید خرید یافت نشد.'));
          }
          return AppResponsiveContainer(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(title: 'اطلاعات رسید'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ReceiptInfoRow(
                          label: 'قلم انبار',
                          value: '${receipt.itemName} (${receipt.itemCode})',
                        ),
                        _ReceiptInfoRow(
                          label: 'مقدار دریافتی',
                          value:
                              '${AppNumberFormat.decimal(receipt.quantity)} ${receipt.unit}',
                        ),
                        _ReceiptInfoRow(
                          label: 'تاریخ دریافت',
                          value: AppDateUtils.formatDisplay(
                            receipt.transactionDate,
                          ),
                        ),
                        if (receipt.unitCost != null)
                          _ReceiptInfoRow(
                            label: 'قیمت واحد',
                            value:
                                '${AppNumberFormat.decimal(receipt.unitCost!)} تومان',
                          ),
                        _ReceiptInfoRow(
                          label: 'تأمین‌کننده',
                          value: receipt.supplierName?.isNotEmpty == true
                              ? receipt.supplierName!
                              : '—',
                        ),
                        if (receipt.notes?.trim().isNotEmpty == true)
                          _ReceiptInfoRow(
                            label: 'یادداشت',
                            value: receipt.notes!,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/purchases/${receipt.purchaseOrderId}'),
                    icon: const Icon(EneftyIcons.receipt_search_outline),
                    label: Text(
                      'مشاهده سفارش خرید ${receipt.purchaseOrderNumber}',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorState(message: error.toString()),
      ),
    );
  }
}

class _ReceiptInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
