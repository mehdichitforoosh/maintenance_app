import 'package:flutter/material.dart';
import '../../../../core/enums/app_enums.dart';

class InventoryFilterChips extends StatelessWidget {
  final ItemType? selectedType;
  final bool? selectedActive;
  final ValueChanged<ItemType?> onTypeChanged;
  final ValueChanged<bool?> onActiveChanged;

  const InventoryFilterChips({
    super.key,
    required this.selectedType,
    required this.selectedActive,
    required this.onTypeChanged,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('همه انواع'),
            selected: selectedType == null,
            onSelected: (_) => onTypeChanged(null),
          ),
          const SizedBox(width: 8),
          ...ItemType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(type.displayName),
                selected: selectedType == type,
                onSelected: (selected) => onTypeChanged(selected ? type : null),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 1,
              height: 24,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          FilterChip(
            label: const Text('همه وضعیت‌ها'),
            selected: selectedActive == null,
            onSelected: (_) => onActiveChanged(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('فعال'),
            selected: selectedActive == true,
            onSelected: (_) => onActiveChanged(true),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('غیرفعال'),
            selected: selectedActive == false,
            onSelected: (_) => onActiveChanged(false),
          ),
        ],
      ),
    );
  }
}
