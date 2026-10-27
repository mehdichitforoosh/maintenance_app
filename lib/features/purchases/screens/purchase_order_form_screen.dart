import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_body.dart';
import '../../../core/widgets/app_form_submit_button.dart';
import '../../facilities/providers/facility_providers.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../models/purchase_order.dart';
import '../providers/purchase_providers.dart';

class PurchaseOrderFormScreen extends ConsumerStatefulWidget {
  final String? purchaseOrderId;

  const PurchaseOrderFormScreen({super.key, this.purchaseOrderId});

  @override
  ConsumerState<PurchaseOrderFormScreen> createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState
    extends ConsumerState<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();
  final List<_PurchaseOrderLineDraft> _lines = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;
  PurchaseOrder? _existingOrder;

  @override
  void initState() {
    super.initState();
    if (widget.purchaseOrderId != null) {
      _loadOrder();
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final repo = ref.read(purchaseRepositoryProvider);
      final po = await repo.getPurchaseOrderById(widget.purchaseOrderId!);
      if (po == null) {
        _loadError = 'سفارش خرید موردنظر پیدا نشد.';
      } else if (mounted) {
        _existingOrder = po;
        _supplierController.text = po.supplierName ?? '';
        _notesController.text = po.notes ?? '';
        final orderItems = await repo.getOrderItems(po.id);
        final receivedQuantities = await repo.getReceivedQuantities(po.id);
        if (!mounted) return;
        _lines.addAll(
          orderItems.map(
            (item) => _PurchaseOrderLineDraft(
              itemId: item.itemId,
              quantity: item.orderedQuantity.toString(),
              unitPrice: item.unitPrice.toString(),
              receivedQuantity: receivedQuantities[item.id] ?? 0,
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) _loadError = 'بارگذاری سفارش خرید ناموفق بود: $error';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _notesController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  bool get _canEditOrderLines =>
      _existingOrder == null ||
      _existingOrder!.status == PurchaseOrderStatus.draft ||
      _existingOrder!.status == PurchaseOrderStatus.ordered ||
      _existingOrder!.status == PurchaseOrderStatus.partiallyReceived;

  bool get _isTerminalOrder =>
      _existingOrder?.status == PurchaseOrderStatus.received ||
      _existingOrder?.status == PurchaseOrderStatus.cancelled;

  void _addLine(List<InventoryItem> items) {
    final selectedIds = _lines.map((line) => line.itemId).whereType<String>();
    final availableItem = items
        .where((item) => item.isActive && !selectedIds.contains(item.id))
        .firstOrNull;
    if (availableItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کالای دیگری برای افزودن وجود ندارد.')),
      );
      return;
    }
    setState(() {
      _lines.add(_PurchaseOrderLineDraft(itemId: availableItem.id));
    });
  }

  void _removeLine(int index) {
    final line = _lines.removeAt(index);
    line.dispose();
    setState(() {});
  }

  Widget _buildLineForm(
    BuildContext context,
    int index,
    _PurchaseOrderLineDraft line,
    List<InventoryItem> items, {
    required bool enabled,
  }) {
    final otherSelectedIds = _lines
        .where((other) => !identical(other, line))
        .map((other) => other.itemId)
        .whereType<String>()
        .toSet();
    final selectableItems = items
        .where(
          (item) =>
              (item.isActive || item.id == line.itemId) &&
              (!otherSelectedIds.contains(item.id) || item.id == line.itemId),
        )
        .toList();
    final canEditItem = enabled && line.receivedQuantity == 0;
    final canEditQuantity = enabled;
    final quantity =
        double.tryParse(line.quantityController.text) ?? line.receivedQuantity;
    final remainingQuantity = (quantity - line.receivedQuantity).clamp(
      0,
      double.infinity,
    );

    return Card(
      color: line.receivedQuantity > 0
          ? Theme.of(
              context,
            ).colorScheme.secondaryContainer.withValues(alpha: 0.28)
          : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'قلم ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (line.receivedQuantity > 0)
                  const Chip(
                    avatar: Icon(Icons.check_circle_outline, size: 16),
                    label: Text('رسید ثبت شده'),
                    visualDensity: VisualDensity.compact,
                  ),
                if (enabled && line.receivedQuantity == 0 && _lines.length > 1)
                  IconButton(
                    tooltip: 'حذف این قلم',
                    onPressed: () => _removeLine(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            DropdownButtonFormField<String>(
              key: ValueKey(line),
              initialValue:
                  selectableItems.any((item) => item.id == line.itemId)
                  ? line.itemId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'انتخاب کالا *',
                prefixIcon: Icon(EneftyIcons.box_bold),
                border: OutlineInputBorder(),
              ),
              items: selectableItems
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text('${item.name} (${item.code})'),
                    ),
                  )
                  .toList(),
              onChanged: canEditItem
                  ? (value) => setState(() => line.itemId = value)
                  : null,
              validator: (value) =>
                  value == null ? 'انتخاب کالا الزامی است.' : null,
            ),
            if (line.receivedQuantity > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'به‌دلیل ثبت رسید، این کالا قابل تعویض یا حذف نیست.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.quantityController,
                    enabled: canEditQuantity,
                    onChanged: canEditQuantity ? (_) => setState(() {}) : null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'مقدار سفارش *',
                      prefixIcon: const Icon(EneftyIcons.ruler_bold),
                      border: const OutlineInputBorder(),
                      helperText: line.receivedQuantity > 0
                          ? 'دریافت‌شده: ${AppNumberFormat.decimal(line.receivedQuantity)} · باقی‌مانده: ${AppNumberFormat.decimal(remainingQuantity)}'
                          : null,
                    ),
                    validator: (value) {
                      final error = AppValidators.positiveNumber(
                        value,
                        fieldName: 'مقدار',
                      );
                      if (error != null) return error;
                      final entered = double.parse(value!.trim());
                      if (entered < line.receivedQuantity) {
                        return 'مقدار نمی‌تواند کمتر از ${line.receivedQuantity} دریافت‌شده باشد.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: line.unitPriceController,
                    enabled: enabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'قیمت واحد (تومان) *',
                      prefixIcon: const Icon(EneftyIcons.money_bold),
                      border: const OutlineInputBorder(),
                      helperText: line.receivedQuantity > 0
                          ? 'قیمت جدید فقط برای رسیدهای بعدی اعمال می‌شود.'
                          : null,
                    ),
                    validator: (value) => AppValidators.nonNegativeNumber(
                      value,
                      fieldName: 'قیمت واحد',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSubmitting || _loadError != null) return;
    if (!_formKey.currentState!.validate() ||
        _lines.isEmpty ||
        _lines.any((line) => line.itemId == null)) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final facility = await ref.read(primaryFacilityProvider.future);
      if (facility == null) {
        throw StateError('ابتدا اطلاعات کارگاه را ثبت کنید.');
      }
      final actions = ref.read(purchaseActionsProvider);
      final items = _lines
          .map(
            (line) => {
              'item_id': line.itemId,
              'ordered_quantity': double.parse(line.quantityController.text),
              'unit_price': double.parse(line.unitPriceController.text),
            },
          )
          .toList();

      if (_existingOrder != null) {
        final updated = _existingOrder!.copyWith(
          supplierName: _supplierController.text.trim().isEmpty
              ? null
              : _supplierController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        await actions.updatePurchaseOrder(updated, items: items);
      } else {
        await actions.createPurchaseOrder(
          facilityId: facility.id,
          supplierName: _supplierController.text.trim(),
          orderDate: AppDateUtils.formatDateOnly(DateTime.now()),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          items: items,
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
    final isEditing = widget.purchaseOrderId != null;
    final invItemsAsync = ref.watch(allInventoryItemsProvider);
    final supplierNamesAsync = ref.watch(purchaseSupplierNamesProvider);
    final items = invItemsAsync.asData?.value ?? [];
    if (_lines.isEmpty && !isEditing && items.isNotEmpty) {
      final firstActiveItem = items.where((item) => item.isActive).firstOrNull;
      if (firstActiveItem != null) {
        _lines.add(_PurchaseOrderLineDraft(itemId: firstActiveItem.id));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'ویرایش سفارش خرید' : 'ثبت سفارش خرید جدید',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: AppFormBody(
        formKey: _formKey,
        isLoading:
            (_isLoading && isEditing && _existingOrder == null) ||
            invItemsAsync.isLoading,
        loadError:
            _loadError ??
            (invItemsAsync.hasError
                ? 'بارگذاری کالاهای انبار ناموفق بود: ${invItemsAsync.error}'
                : null),
        onRetry: _loadError != null
            ? _loadOrder
            : () => ref.invalidate(allInventoryItemsProvider),
        children: items.where((item) => item.isActive).isEmpty && !isEditing
            ? [const Text('ابتدا باید کالای فعالی در انبار تعریف کنید.')]
            : [
                Autocomplete<String>(
                  key: ValueKey(_existingOrder?.id ?? 'new'),
                  initialValue: TextEditingValue(
                    text: _supplierController.text,
                  ),
                  optionsBuilder: (value) {
                    final query = value.text.trim().toLowerCase();
                    final names = supplierNamesAsync.asData?.value ?? const [];
                    return names.where(
                      (name) =>
                          query.isEmpty || name.toLowerCase().contains(query),
                    );
                  },
                  onSelected: (name) => _supplierController.text = name,
                  fieldViewBuilder:
                      (
                        context,
                        textEditingController,
                        focusNode,
                        onFieldSubmitted,
                      ) => TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        onChanged: (value) => _supplierController.text = value,
                        onFieldSubmitted: (_) => onFieldSubmitted(),
                        decoration: InputDecoration(
                          labelText: 'نام تأمین‌کننده *',
                          prefixIcon: const Icon(EneftyIcons.user_bold),
                          border: const OutlineInputBorder(),
                          helperText: supplierNamesAsync.hasError
                              ? 'دریافت نام‌های قبلی ناموفق بود؛ نام تأمین‌کننده را دستی وارد کنید.'
                              : supplierNamesAsync.isLoading
                              ? 'در حال بارگذاری تأمین‌کنندگان قبلی...'
                              : null,
                        ),
                        validator: (value) => AppValidators.required(
                          value,
                          fieldName: 'تأمین‌کننده',
                        ),
                      ),
                  optionsViewBuilder: (context, onSelected, options) => Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: options
                              .map(
                                (name) => ListTile(
                                  dense: true,
                                  leading: const Icon(EneftyIcons.user_bold),
                                  title: Text(name),
                                  onTap: () => onSelected(name),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Text('اقلام سفارش')),
                    if (_canEditOrderLines)
                      TextButton.icon(
                        onPressed: () => _addLine(items),
                        icon: const Icon(Icons.add),
                        label: const Text('افزودن کالا'),
                      ),
                  ],
                ),
                if (_isTerminalOrder)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'این سفارش تکمیل یا لغو شده است؛ اقلام آن قابل تغییر نیستند.',
                    ),
                  ),
                if (!_isTerminalOrder &&
                    _lines.any((line) => line.receivedQuantity > 0))
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'برای اقلام دارای رسید، کالا ثابت می‌ماند و مقدار سفارش نباید از مقدار دریافت‌شده کمتر شود.',
                    ),
                  ),
                ..._lines.asMap().entries.map(
                  (entry) => _buildLineForm(
                    context,
                    entry.key,
                    entry.value,
                    items,
                    enabled: _canEditOrderLines,
                  ),
                ),
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
                AppFormSubmitButton(
                  icon: Icon(
                    isEditing ? EneftyIcons.edit_2_bold : EneftyIcons.add_bold,
                  ),
                  onPressed: _save,
                  isSubmitting: _isSubmitting,
                  label: isEditing ? 'بروزرسانی سفارش' : 'ثبت سفارش خرید',
                ),
              ],
      ),
    );
  }
}

class _PurchaseOrderLineDraft {
  String? itemId;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final double receivedQuantity;

  _PurchaseOrderLineDraft({
    this.itemId,
    String quantity = '10',
    String unitPrice = '100000',
    this.receivedQuantity = 0,
  }) : quantityController = TextEditingController(text: quantity),
       unitPriceController = TextEditingController(text: unitPrice);

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
  }
}
