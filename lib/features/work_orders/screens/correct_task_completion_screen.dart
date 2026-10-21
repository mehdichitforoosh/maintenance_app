import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../models/work_order_material.dart';
import '../models/work_order_task.dart';
import '../providers/work_order_providers.dart';

class CorrectTaskCompletionScreen extends ConsumerStatefulWidget {
  final String workOrderId;
  final String taskId;

  const CorrectTaskCompletionScreen({
    super.key,
    required this.workOrderId,
    required this.taskId,
  });

  @override
  ConsumerState<CorrectTaskCompletionScreen> createState() =>
      _CorrectTaskCompletionScreenState();
}

class _CorrectTaskCompletionScreenState
    extends ConsumerState<CorrectTaskCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _findingsController = TextEditingController();
  final _laborController = TextEditingController();
  final _downtimeController = TextEditingController();
  final _newQuantityController = TextEditingController(text: '1');
  final Map<String, TextEditingController> _materialControllers = {};
  final Map<String, TextEditingController> _newMaterialControllers = {};
  TaskResult _result = TaskResult.success;
  String? _selectedItemId;
  String? _initializedTaskId;
  bool _isSaving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _findingsController.dispose();
    _laborController.dispose();
    _downtimeController.dispose();
    _newQuantityController.dispose();
    for (final controller in _materialControllers.values) {
      controller.dispose();
    }
    for (final controller in _newMaterialControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initialize(WorkOrderTask task, List<WorkOrderMaterial> materials) {
    if (_initializedTaskId == task.id) return;
    _initializedTaskId = task.id;
    _result = task.result ?? TaskResult.success;
    _findingsController.text = task.findings ?? '';
    _laborController.text = (task.laborMinutes ?? 0).toString();
    _downtimeController.text = (task.downtimeMinutes ?? 0).toString();
    for (final material in materials) {
      _materialControllers[material.itemId] = TextEditingController(
        text: (material.actualQuantity ?? 0).toString(),
      );
    }
  }

  Future<void> _save(
    WorkOrderTask task,
    List<WorkOrderMaterial> materials,
    List<InventoryItem> items,
    String? facilityId,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final desiredMaterials = <Map<String, dynamic>>[];
      for (final material in materials) {
        final quantity = double.tryParse(
          _materialControllers[material.itemId]!.text.trim(),
        );
        if (quantity == null || !quantity.isFinite || quantity < 0) {
          throw ArgumentError('مقدار مصرف باید صفر یا بیشتر باشد.');
        }
        desiredMaterials.add({
          'item_id': material.itemId,
          'quantity': quantity,
        });
      }
      for (final entry in _newMaterialControllers.entries) {
        final quantity = double.tryParse(entry.value.text.trim());
        if (quantity == null || !quantity.isFinite || quantity < 0) {
          throw ArgumentError('مقدار مصرف باید صفر یا بیشتر باشد.');
        }
        desiredMaterials.add({'item_id': entry.key, 'quantity': quantity});
      }

      await ref
          .read(workOrderActionsProvider)
          .correctCompletedTask(
            workOrderId: widget.workOrderId,
            taskId: task.id,
            facilityId: facilityId,
            reason: _reasonController.text.trim(),
            result: _result,
            findings: _findingsController.text.trim().isEmpty
                ? null
                : _findingsController.text.trim(),
            laborMinutes: int.parse(_laborController.text.trim()),
            downtimeMinutes: int.parse(_downtimeController.text.trim()),
            actualMaterials: desiredMaterials,
          );

      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در اصلاح اطلاعات: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(workOrderTasksProvider(widget.workOrderId));
    final materialsAsync = ref.watch(workOrderMaterialsProvider(widget.taskId));
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final workOrderAsync = ref.watch(
      workOrderDetailProvider(widget.workOrderId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('اصلاح اطلاعات تکمیل وظیفه')),
      body: tasksAsync.when(
        data: (tasks) {
          final matches = tasks.where((task) => task.id == widget.taskId);
          if (matches.isEmpty || matches.first.status != TaskStatus.completed) {
            return const Center(
              child: Text('وظیفه تکمیل‌شده برای اصلاح یافت نشد.'),
            );
          }
          final task = matches.first;
          return materialsAsync.when(
            data: (materials) {
              _initialize(task, materials);
              return inventoryAsync.when(
                data: (items) => _buildForm(
                  task,
                  materials,
                  items,
                  workOrderAsync.value?.facilityId,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('بارگذاری اقلام انبار ناموفق بود: $error'),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('بارگذاری متریال ناموفق بود: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('بارگذاری وظیفه ناموفق بود: $error')),
      ),
    );
  }

  Widget _buildForm(
    WorkOrderTask task,
    List<WorkOrderMaterial> materials,
    List<InventoryItem> items,
    String? facilityId,
  ) {
    final itemById = {for (final item in items) item.id: item};
    final availableItems = items
        .where(
          (item) =>
              !materials.any((material) => material.itemId == item.id) &&
              !_newMaterialControllers.containsKey(item.id),
        )
        .toList();
    if (_selectedItemId != null &&
        !availableItems.any((item) => item.id == _selectedItemId)) {
      _selectedItemId = null;
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('اصلاحات با دلیل ثبت می‌شوند و سوابق قبلی حفظ خواهد شد.'),
          const SizedBox(height: 16),
          DropdownButtonFormField<TaskResult>(
            initialValue: _result,
            decoration: const InputDecoration(
              labelText: 'نتیجه انجام کار',
              border: OutlineInputBorder(),
            ),
            items: TaskResult.values
                .map(
                  (result) => DropdownMenuItem(
                    value: result,
                    child: Text(result.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _result = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _findingsController,
            decoration: const InputDecoration(
              labelText: 'یافته‌ها و گزارش کار',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _laborController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'زمان کار (دقیقه)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _minutesValidator(value, fieldName: 'زمان کار'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _downtimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'زمان توقف (دقیقه)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _minutesValidator(value, fieldName: 'زمان توقف'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'اصلاح متریال و مصرف واقعی',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'اختلاف مقدار اصلاح‌شده با دفتر انبار، با تراکنش مصرف یا برگشت ثبت می‌شود؛ تراکنش قبلی حذف نمی‌شود.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          ...materials.map((material) {
            final item = itemById[material.itemId];
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextFormField(
                controller: _materialControllers[material.itemId],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '${item?.name ?? 'کالای حذف‌شده'} · مقدار واقعی',
                  suffixText: item?.unit,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => _quantityValidator(value),
              ),
            );
          }),
          if (availableItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedItemId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'افزودن کالای مصرف‌شده',
                border: OutlineInputBorder(),
              ),
              items: availableItems
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text('${item.name} (${item.unit})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedItemId = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newQuantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'مقدار مصرف واقعی',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'افزودن به اصلاح متریال',
                  onPressed: _selectedItemId == null
                      ? null
                      : () {
                          final quantity = double.tryParse(
                            _newQuantityController.text.trim(),
                          );
                          if (quantity == null ||
                              !quantity.isFinite ||
                              quantity < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'مقدار باید عددی صفر یا بیشتر باشد.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _newMaterialControllers[_selectedItemId!] =
                                TextEditingController(
                                  text: quantity.toString(),
                                );
                            _selectedItemId = null;
                            _newQuantityController.text = '1';
                          });
                        },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
          ..._newMaterialControllers.entries.map((entry) {
            final item = itemById[entry.key];
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: entry.value,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '${item?.name ?? 'کالا'} · مقدار واقعی',
                        suffixText: item?.unit,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => _quantityValidator(value),
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف از اصلاح',
                    onPressed: () {
                      setState(() {
                        _newMaterialControllers.remove(entry.key)?.dispose();
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'دلیل اصلاح *',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'لطفاً دلیل اصلاح را وارد کنید.'
                : null,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving
                ? null
                : () => _save(task, materials, items, facilityId),
            child: _isSaving
                ? const CircularProgressIndicator()
                : const Text('ثبت اصلاحات'),
          ),
        ],
      ),
    );
  }

  String? _quantityValidator(String? value) {
    final quantity = double.tryParse(value?.trim() ?? '');
    if (quantity == null || !quantity.isFinite || quantity < 0) {
      return 'مقدار باید صفر یا بیشتر باشد.';
    }
    return null;
  }

  String? _minutesValidator(String? value, {required String fieldName}) {
    final minutes = int.tryParse(value?.trim() ?? '');
    if (minutes == null || minutes < 0) {
      return '$fieldName باید عدد صحیح صفر یا بیشتر باشد.';
    }
    return null;
  }
}
