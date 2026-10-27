import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../models/inventory_item.dart';
import '../../models/stock_transaction.dart';

class InventoryItemSpecificationsCard extends StatelessWidget {
  final InventoryItem item;
  final bool isLowStock;

  const InventoryItemSpecificationsCard({
    super.key,
    required this.item,
    required this.isLowStock,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLowStock ? Colors.red : Colors.green;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'مشخصات قلم انبار',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    isLowStock ? 'موجودی کم' : 'موجودی کافی',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 20),
            _InfoRow(label: 'کد کالا', value: item.code),
            _InfoRow(label: 'نوع', value: item.itemType.displayName),
            _InfoRow(label: 'واحد', value: item.unit),
            _InfoRow(
              label: 'حداقل موجودی',
              value:
                  '${AppNumberFormat.decimal(item.minimumStock)} ${item.unit}',
            ),
            if (item.defaultUnitCost != null)
              _InfoRow(
                label: 'قیمت واحد پیش‌فرض',
                value:
                    '${AppNumberFormat.decimal(item.defaultUnitCost!)} تومان',
              ),
            if (item.description?.trim().isNotEmpty ?? false)
              _InfoRow(label: 'توضیحات', value: item.description!),
          ],
        ),
      ),
    );
  }
}

class StockTransactionTile extends StatelessWidget {
  final StockTransaction transaction;
  final String unit;
  final VoidCallback? onTap;

  const StockTransactionTile({
    super.key,
    required this.transaction,
    required this.unit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final notes = transaction.notes?.trim();
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        leading: CircleAvatar(
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
          child: const Icon(Icons.inventory_2_outlined),
        ),
        title: Text(
          transaction.transactionType.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppNumberFormat.decimal(transaction.quantity)} $unit',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                AppDateUtils.formatDisplay(transaction.transactionDate),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(notes),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
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
