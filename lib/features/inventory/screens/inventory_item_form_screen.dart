import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_form_body.dart';
import '../../../core/widgets/app_form_submit_button.dart';
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
  bool _isSubmitting = false;
  InventoryItem? _existingItem;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _loadItem();
    }
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final item = await ref.read(inventoryItemProvider(widget.itemId!).future);
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
      } else if (mounted) {
        _loadError = 'کالا یافت نشد.';
      }
    } catch (error) {
      if (mounted) _loadError = 'بارگذاری کالا ناموفق بود: $error';
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
    if (_isSubmitting || _loadError != null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
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
        await ref.read(inventoryActionsProvider).updateItem(updated);
      } else {
        await ref
            .read(inventoryActionsProvider)
            .createItem(
              name: _nameController.text.trim(),
              code: _codeController.text.trim(),
              itemType: _itemType,
              unit: _unitController.text.trim(),
              minimumStock:
                  double.tryParse(_minStockController.text.trim()) ?? 0.0,
              defaultUnitCost: _costController.text.trim().isEmpty
                  ? null
                  : double.tryParse(_costController.text.trim()),
              description: _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
              isActive: _isActive,
            );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      body: AppFormBody(
        formKey: _formKey,
        isLoading: _isLoading && isEditing && _existingItem == null,
        loadError: _loadError,
        onRetry: _loadItem,
        children: [
          InventoryItemIdentityFields(
            nameController: _nameController,
            codeController: _codeController,
            itemType: _itemType,
            onItemTypeChanged: (type) => setState(() => _itemType = type),
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
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'توضیحات'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          InventoryItemActiveTile(
            isActive: _isActive,
            onChanged: (active) => setState(() => _isActive = active),
          ),
          const SizedBox(height: 24),
          AppFormSubmitButton(
            icon: Icon(
              isEditing ? EneftyIcons.edit_2_bold : EneftyIcons.add_bold,
            ),
            label: isEditing ? 'بروزرسانی قلم انبار' : 'ذخیره قلم انبار',
            isSubmitting: _isSubmitting,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
