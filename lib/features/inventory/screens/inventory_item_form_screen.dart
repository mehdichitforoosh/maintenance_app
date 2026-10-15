import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_loading.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_providers.dart';
import 'widgets/inventory_item_form_fields.dart';

class InventoryItemFormScreen extends ConsumerStatefulWidget {
  final String? itemId;

  const InventoryItemFormScreen({super.key, this.itemId});

  @override
  ConsumerState<InventoryItemFormScreen> createState() =>
      _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState
    extends ConsumerState<InventoryItemFormScreen> {
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
          defaultUnitCost: _costController.text.trim().isEmpty
              ? null
              : double.tryParse(_costController.text.trim()),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
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
          defaultUnitCost: _costController.text.trim().isEmpty
              ? null
              : double.tryParse(_costController.text.trim()),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          isActive: _isActive,
        );
      }

      ref.invalidate(inventoryItemsProvider);
      ref.invalidate(allInventoryItemsProvider);
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
    final isEditing = widget.itemId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'ویرایش قلم انبار' : 'تعریف قلم انبار جدید',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading && isEditing && _existingItem == null
            ? const AppLoading()
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    InventoryItemIdentityFields(
                      nameController: _nameController,
                      codeController: _codeController,
                      itemType: _itemType,
                      onItemTypeChanged: (type) =>
                          setState(() => _itemType = type),
                    ),
                    const SizedBox(height: 16),
                    InventoryUnitField(
                      controller: _unitController,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    InventoryItemStockFields(
                      minimumStockController: _minStockController,
                      unitCostController: _costController,
                    ),
                    const SizedBox(height: 16),
                    InventoryItemActiveTile(
                      isActive: _isActive,
                      onChanged: (active) => setState(() => _isActive = active),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'توضیحات'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: Icon(
                        isEditing
                            ? EneftyIcons.edit_2_bold
                            : EneftyIcons.add_bold,
                      ),
                      onPressed: _isLoading ? null : _save,
                      label: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEditing
                                  ? 'بروزرسانی قلم انبار'
                                  : 'ذخیره قلم انبار',
                            ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
