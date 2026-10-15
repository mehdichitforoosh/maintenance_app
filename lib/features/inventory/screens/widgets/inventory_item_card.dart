import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const InventoryItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activeColor = item.isActive ? Colors.green : colors.onSurfaceVariant;

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.secondaryContainer,
                child: Icon(
                  EneftyIcons.box_outline,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'کد: ${item.code} | واحد: ${item.unit}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _ItemChip(
                          label: item.itemType.displayName,
                          foreground: colors.onPrimaryContainer,
                          background: colors.primaryContainer,
                          bold: true,
                        ),
                        _ItemChip(
                          label: item.isActive ? 'فعال' : 'غیرفعال',
                          foreground: activeColor,
                          background: item.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : colors.surfaceContainerHighest,
                          bold: true,
                        ),
                        _ItemChip(
                          label:
                              'نقطه سفارش: ${item.minimumStock} ${item.unit}',
                          foreground: colors.onSecondaryContainer,
                          background: colors.secondaryContainer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final bool bold;

  const _ItemChip({
    required this.label,
    required this.foreground,
    required this.background,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
      ),
      backgroundColor: background,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
