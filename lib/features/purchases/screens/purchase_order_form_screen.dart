import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_loading.dart';
import '../../facilities/providers/facility_providers.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../models/purchase_order.dart';
import '../providers/purchase_providers.dart';

class PurchaseOrderFormScreen extends ConsumerStatefulWidget {
  final String? purchaseOrderId;

  const PurchaseOrderFormScreen({super.key, this.purchaseOrderId});

  @override
  ConsumerState<PurchaseOrderFormScreen> createState() => _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends ConsumerState<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();
  final _qtyController = TextEditingController(text: '10');
  final _priceController = TextEditingController(text: '100000');
  String? _selectedItemId;
  bool _isLoading = false;
  PurchaseOrder? _existingOrder;

  @override
  void initState() {
    super.initState();
    if (widget.purchaseOrderId != null) {
      _loadOrder();
    }
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(purchaseRepositoryProvider);
      final po = await repo.getPurchaseOrderById(widget.purchaseOrderId!);
      if (po != null && mounted) {
        _existingOrder = po;
        _supplierController.text = po.supplierName ?? '';
        _notesController.text = po.notes ?? '';
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _notesController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || (_selectedItemId == null && _existingOrder == null)) return;
    setState(() => _isLoading = true);

    try {
      final facility = await ref.read(primaryFacilityProvider.future);
      if (facility == null) return;
      final repo = ref.read(purchaseRepositoryProvider);

      if (_existingOrder != null) {
        final updated = _existingOrder!.copyWith(
          supplierName: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        await repo.updatePurchaseOrder(updated);
      } else {
        await repo.createPurchaseOrder(
          facilityId: facility.id,
          supplierName: _supplierController.text.trim(),
          orderDate: AppDateUtils.formatDateOnly(DateTime.now()),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          items: [
            {
              'item_id': _selectedItemId,
              'ordered_quantity': double.parse(_qtyController.text.trim()),
              'unit_price': double.parse(_priceController.text.trim()),
            }
          ],
        );
      }

      ref.invalidate(purchaseOrdersProvider(facility.id));
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
    final isEditing = widget.purchaseOrderId != null;
    final invItemsAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش سفارش خرید' : 'ثبت سفارش خرید جدید', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: invItemsAsync.when(
        data: (items) {
          if (items.isEmpty && !isEditing) return const Center(child: Text('ابتدا باید کالایی در انبار تعریف کنید.'));
          if (items.isNotEmpty) _selectedItemId ??= items.first.id;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _supplierController,
                    decoration: const InputDecoration(
                      labelText: 'نام تأمین‌کننده *',
                      prefixIcon: Icon(EneftyIcons.user_bold),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => AppValidators.required(v, fieldName: 'تأمین‌کننده'),
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedItemId,
                      decoration: const InputDecoration(
                        labelText: 'انتخاب کالا *',
                        prefixIcon: Icon(EneftyIcons.box_bold),
                        border: OutlineInputBorder(),
                      ),
                      items: items.map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.code})'))).toList(),
                      onChanged: (v) => setState(() => _selectedItemId = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'مقدار سفارش *',
                              prefixIcon: Icon(EneftyIcons.ruler_bold),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => AppValidators.positiveNumber(v, fieldName: 'مقدار'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'قیمت واحد (تومان) *',
                              prefixIcon: Icon(EneftyIcons.money_bold),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => AppValidators.nonNegativeNumber(v, fieldName: 'قیمت واحد'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'یادداشت',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: Icon(isEditing ? EneftyIcons.edit_2_bold : EneftyIcons.add_bold),
                    onPressed: _isLoading ? null : _save,
                    label: Text(isEditing ? 'بروزرسانی سفارش' : 'ثبت سفارش خرید'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('خطا: $e')),
      ),
    );
  }
}
