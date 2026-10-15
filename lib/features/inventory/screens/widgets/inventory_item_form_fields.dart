import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/validators.dart';

class InventoryItemIdentityFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController codeController;
  final ItemType itemType;
  final ValueChanged<ItemType> onItemTypeChanged;

  const InventoryItemIdentityFields({
    super.key,
    required this.nameController,
    required this.codeController,
    required this.itemType,
    required this.onItemTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'نام کالا / قطعه *',
            prefixIcon: Icon(EneftyIcons.box_bold),
          ),
          validator: (value) =>
              AppValidators.required(value, fieldName: 'نام کالا'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'کد کالا (یکتا) *',
            prefixIcon: Icon(EneftyIcons.code_bold),
          ),
          validator: AppValidators.code,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ItemType>(
          initialValue: itemType,
          decoration: const InputDecoration(
            labelText: 'نوع کالا',
            prefixIcon: Icon(EneftyIcons.category_bold),
          ),
          items: ItemType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onItemTypeChanged(value);
          },
        ),
      ],
    );
  }
}

class InventoryUnitField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const InventoryUnitField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  static const _units = [
    'کیلوگرم',
    'عدد',
    'میلی‌لیتر',
    'گرم',
    'لیتر',
    'بسته',
    'متر',
    'رول',
    'دستگاه',
    'سایر...',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'واحد اندازه‌گیری *',
            prefixIcon: Icon(EneftyIcons.ruler_bold),
          ),
          validator: (value) =>
              AppValidators.required(value, fieldName: 'واحد اندازه‌گیری'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _units.map((unit) {
            return ChoiceChip(
              label: Text(unit),
              selected: unit != 'سایر...' && controller.text == unit,
              onSelected: (_) {
                if (unit == 'سایر...') {
                  controller.clear();
                } else {
                  controller.text = unit;
                }
                onChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class InventoryItemStockFields extends StatelessWidget {
  final TextEditingController minimumStockController;
  final TextEditingController unitCostController;

  const InventoryItemStockFields({
    super.key,
    required this.minimumStockController,
    required this.unitCostController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: minimumStockController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'حداقل موجودی (نقطه سفارش)',
            prefixIcon: Icon(EneftyIcons.danger_bold),
          ),
          validator: (value) =>
              AppValidators.nonNegativeNumber(value, fieldName: 'حداقل موجودی'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: unitCostController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'قیمت واحد پیش‌فرض (تومان)',
            prefixIcon: Icon(EneftyIcons.money_bold),
          ),
        ),
      ],
    );
  }
}

class InventoryItemActiveTile extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const InventoryItemActiveTile({
    super.key,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: SwitchListTile(
        value: isActive,
        onChanged: onChanged,
        title: const Text(
          'وضعیت فعال بودن کالا',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          isActive
              ? 'کالا فعال و آماده بهره‌برداری در سیستم است'
              : 'کالا غیرفعال شده است',
        ),
        secondary: Icon(
          isActive
              ? EneftyIcons.tick_circle_bold
              : EneftyIcons.close_circle_bold,
          color: isActive
              ? Colors.green
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
