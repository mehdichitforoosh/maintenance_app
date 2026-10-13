import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/validators.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_providers.dart';

class InventoryItemFormScreen extends ConsumerStatefulWidget {
  final String? itemId;

  const InventoryItemFormScreen({super.key, this.itemId});

  @override
  ConsumerState<InventoryItemFormScreen> createState() => _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState extends ConsumerState<InventoryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _unitController = TextEditingController(text: 'عدد');
  final _minStockController = TextEditingController(text: '5');
  final _costController = TextEditingController();
  final _descController = TextEditingController();

  ItemType _itemType = ItemType.consumable;
  bool _isActive = true;
  bool _isLoading = false;
  InventoryItem? _existingItem;

  static const List<String> _presetUnits = [
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
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _loadItem();
    }
  }

  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final item = await repo.getItemById(widget.itemId!);
      if (item != null && mounted) {
        _existingItem = item;
        _nameController.text = item.name;
        _codeController.text = item.code;
        _unitController.text = item.unit;
        _minStockController.text = item.minimumStock.toString();
        _costController.text = item.defaultUnitCost?.toString() ?? '';
        _descController.text = item.description ?? '';
        _itemType = item.itemType;
        _isActive = item.isActive;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _unitController.dispose();
    _minStockController.dispose();
    _costController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(inventoryRepositoryProvider);

      if (_existingItem != null) {
        final updated = _existingItem!.copyWith(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          itemType: _itemType,
          unit: _unitController.text.trim(),
          minimumStock: double.tryParse(_minStockController.text.trim()) ?? 0.0,
          defaultUnitCost: _costController.text.trim().isEmpty ? null : double.tryParse(_costController.text.trim()),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          isActive: _isActive,
        );
        await repo.updateItem(updated);
      } else {
        await repo.createItem(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          itemType: _itemType,
          unit: _unitController.text.trim(),
          minimumStock: double.tryParse(_minStockController.text.trim()) ?? 0.0,
          defaultUnitCost: _costController.text.trim().isEmpty ? null : double.tryParse(_costController.text.trim()),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          isActive: _isActive,
        );
      }

      ref.invalidate(inventoryItemsProvider);
      ref.invalidate(lowStockItemsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش قلم انبار' : 'تعریف قلم انبار جدید', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'نام کالا / قطعه *',
                  prefixIcon: Icon(EneftyIcons.box_bold),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => AppValidators.required(v, fieldName: 'نام کالا'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'کد کالا (یکتا) *',
                  prefixIcon: Icon(EneftyIcons.code_bold),
                  border: OutlineInputBorder(),
                ),
                validator: AppValidators.code,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ItemType>(
                initialValue: _itemType,
                decoration: const InputDecoration(
                  labelText: 'نوع کالا',
                  prefixIcon: Icon(EneftyIcons.category_bold),
                  border: OutlineInputBorder(),
                ),
                items: ItemType.values.map((i) => DropdownMenuItem(value: i, child: Text(i.displayName))).toList(),
                onChanged: (v) => setState(() => _itemType = v ?? ItemType.consumable),
              ),
              const SizedBox(height: 16),

              // Unit Input & Visual Preset Unit Chips (Matching attached image)
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'واحد اندازه‌گیری *',
                  prefixIcon: Icon(EneftyIcons.ruler_bold),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => AppValidators.required(v, fieldName: 'واحد اندازه‌گیری'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetUnits.map((u) {
                  final isSelected = u != 'سایر...' && _unitController.text == u;
                  return InkWell(
                    onTap: () {
                      if (u == 'سایر...') {
                        _unitController.clear();
                      } else {
                        _unitController.text = u;
                      }
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD1FAE5) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check, size: 16, color: Color(0xFF065F46)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            u,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF065F46) : Colors.grey.shade800,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _minStockController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'حداقل موجودی (نقطه سفارش)',
                  prefixIcon: Icon(EneftyIcons.danger_bold),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => AppValidators.nonNegativeNumber(v, fieldName: 'حداقل موجودی'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'قیمت واحد پیش‌فرض (تومان)',
                  prefixIcon: Icon(EneftyIcons.money_bold),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Active / Inactive Switch
              Card(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('وضعیت فعال بودن کالا', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(_isActive ? 'کالا فعال و آماده بهره‌برداری در سیستم است' : 'کالا غیرفعال شده است'),
                  secondary: Icon(
                    _isActive ? EneftyIcons.tick_circle_bold : EneftyIcons.close_circle_bold,
                    color: _isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'توضیحات',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: Icon(isEditing ? EneftyIcons.edit_2_bold : EneftyIcons.add_bold),
                onPressed: _isLoading ? null : _save,
                label: Text(isEditing ? 'بروزرسانی قلم انبار' : 'ذخیره قلم انبار'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
