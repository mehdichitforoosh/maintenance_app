import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_form_body.dart';
import '../../../core/widgets/app_form_submit_button.dart';
import '../../../core/widgets/app_loading.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../../maintenance/models/maintenance_plan.dart';
import '../../maintenance/providers/maintenance_providers.dart';
import '../models/work_order_material.dart';
import '../providers/work_order_providers.dart';

class CompleteTaskScreen extends ConsumerStatefulWidget {
  final String workOrderId;
  final String taskId;

  const CompleteTaskScreen({
    super.key,
    required this.workOrderId,
    required this.taskId,
  });

  @override
  ConsumerState<CompleteTaskScreen> createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends ConsumerState<CompleteTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _findingsController = TextEditingController();
  final _laborController = TextEditingController(text: '30');
  final _downtimeController = TextEditingController(text: '0');
  final _completionMeterController = TextEditingController();
  TaskResult _result = TaskResult.success;
  bool _isSubmitting = false;

  String? _selectedItemId;
  final _qtyController = TextEditingController(text: '1');
  final Map<String, TextEditingController> _materialQuantityControllers = {};
  final Set<String> _additionalItemIds = {};
  String? _initializedMaterialsTaskId;

  @override
  void dispose() {
    _findingsController.dispose();
    _laborController.dispose();
    _downtimeController.dispose();
    _completionMeterController.dispose();
    _qtyController.dispose();
    for (final controller in _materialQuantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeMaterialQuantities(
    String taskId,
    List<WorkOrderMaterial> materials,
  ) {
    if (_initializedMaterialsTaskId == taskId) return;
    for (final controller in _materialQuantityControllers.values) {
      controller.dispose();
    }
    _materialQuantityControllers.clear();
    _additionalItemIds.clear();
    for (final material in materials) {
      _materialQuantityControllers[material.itemId] = TextEditingController();
    }
    _initializedMaterialsTaskId = taskId;
  }

  Future<void> _complete() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    final consumedMaterials = _materialQuantityControllers.entries
        .map((entry) {
          final quantity =
              double.tryParse(entry.value.text.trim().replaceAll(',', '.')) ??
              0;
          return {'item_id': entry.key, 'quantity': quantity};
        })
        .where((material) => (material['quantity'] as double) > 0)
        .toList();
    setState(() => _isSubmitting = true);

    try {
      final workOrder = await ref.read(
        workOrderDetailProvider(widget.workOrderId).future,
      );
      if (workOrder == null) throw StateError('دستورکار یافت نشد.');
      final tasks = await ref.read(
        workOrderTasksProvider(widget.workOrderId).future,
      );
      final task = tasks.where((task) => task.id == widget.taskId).firstOrNull;
      MaintenancePlan? plan;
      if (task?.maintenancePlanId != null) {
        plan = await ref.read(
          maintenancePlanDetailProvider(task!.maintenancePlanId!).future,
        );
      }
      if (task == null) throw StateError('وظیفه یافت نشد.');
      final isMeterPlan =
          plan?.scheduleType == ScheduleType.meter ||
          task.plannedMeterValue != null;
      final completionMeterValue = isMeterPlan
          ? double.tryParse(_completionMeterController.text.trim())
          : null;
      if (isMeterPlan &&
          (completionMeterValue == null || !completionMeterValue.isFinite)) {
        throw ArgumentError('مقدار نهایی کارکرد معتبر نیست.');
      }
      await ref
          .read(workOrderActionsProvider)
          .completeTask(
            workOrderId: widget.workOrderId,
            taskId: widget.taskId,
            facilityId: workOrder.facilityId,
            result: _result,
            findings: _findingsController.text.trim().isEmpty
                ? null
                : _findingsController.text.trim(),
            laborMinutes: int.tryParse(_laborController.text.trim()) ?? 0,
            downtimeMinutes: int.tryParse(_downtimeController.text.trim()) ?? 0,
            consumedMaterials: consumedMaterials.isEmpty
                ? null
                : consumedMaterials,
            completionMeterValue: completionMeterValue,
            maintenancePlanId: task.maintenancePlanId,
            assetId: task.assetId,
          );

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

  Widget _buildMaterialSection(
    List<InventoryItem> items,
    List<WorkOrderMaterial> taskMaterials,
  ) {
    final itemById = {for (final item in items) item.id: item};
    final plannedItemIds = {
      for (final material in taskMaterials) material.itemId,
    };
    final additionalItems = items
        .where(
          (item) =>
              !plannedItemIds.contains(item.id) &&
              !_additionalItemIds.contains(item.id),
        )
        .toList();
    if (_selectedItemId != null &&
        !additionalItems.any((item) => item.id == _selectedItemId)) {
      _selectedItemId = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (taskMaterials.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'برای این وظیفه متریال برنامه‌ریزی‌شده‌ای وجود ندارد؛ در صورت نیاز می‌توانید اقلام مصرف‌شده را اضافه کنید.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ...taskMaterials.map((material) {
          final item = itemById[material.itemId];
          final controller = _materialQuantityControllers[material.itemId]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item?.name ?? 'کالای غیرفعال یا حذف‌شده',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (material.plannedQuantity != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        'مقدار برنامه‌ریزی‌شده: ${AppNumberFormat.decimal(material.plannedQuantity!)} ${item?.unit ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if ((material.actualQuantity ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'مصرف ثبت‌شده قبلی: ${AppNumberFormat.decimal(material.actualQuantity!)} ${item?.unit ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12,),
                  TextFormField(
                    controller: controller,
                    enabled: !_isSubmitting && item != null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'مقدار مصرف واقعی',
                      suffixText: item?.unit,
                      border: const OutlineInputBorder(),
                    ),
                    validator: _optionalQuantityValidator,
                  ),
                  if (item == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'این کالا در انبار فعال نیست و نمی‌توان مصرف جدیدی برای آن ثبت کرد.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        ..._additionalItemIds.map((itemId) {
          final item = itemById[itemId];
          final controller = _materialQuantityControllers[itemId]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item?.name ?? 'کالای غیرفعال یا حذف‌شده',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12,),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          enabled: !_isSubmitting,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'مقدار مصرف واقعی',
                            suffixText: item?.unit,
                            border: InputBorder.none,
                          ),
                          validator: _optionalQuantityValidator,
                        ),
                      ),
                      IconButton(
                        tooltip: 'حذف از فهرست مصرف',
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _additionalItemIds.remove(itemId);
                                  _materialQuantityControllers
                                      .remove(itemId)
                                      ?.dispose();
                                });
                              },
                        icon: const Icon(EneftyIcons.trash_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (additionalItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedItemId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'افزودن کالای مصرف‌شده',
              border: OutlineInputBorder(),
            ),
            items: additionalItems
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(
                      '${item.name} (${item.code}) · ${item.unit}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _selectedItemId = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyController,
                  enabled: !_isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'مقدار مصرف',
                    suffixText: items
                        .where((item) => item.id == _selectedItemId)
                        .firstOrNull
                        ?.unit,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: 'افزودن کالا به فهرست مصرف',
                icon: const Icon(EneftyIcons.add_outline),
                onPressed: _isSubmitting ? null : _addAdditionalMaterial,
              ),
            ],
          ),
        ] else if (items.isEmpty && taskMaterials.isEmpty)
          const Text('کالایی در انبار ثبت نشده است.'),
      ],
    );
  }

  void _addAdditionalMaterial() {
    final itemId = _selectedItemId;
    final quantity = double.tryParse(_qtyController.text.trim());
    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا کالای مصرف‌شده را انتخاب کنید.')),
      );
      return;
    }
    if (quantity == null || !quantity.isFinite || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مقدار مصرف باید عددی بزرگ‌تر از صفر باشد.'),
        ),
      );
      return;
    }
    if (_materialQuantityControllers.containsKey(itemId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('این کالا قبلاً در فهرست متریال وظیفه وجود دارد.'),
        ),
      );
      return;
    }
    setState(() {
      _additionalItemIds.add(itemId);
      _materialQuantityControllers[itemId] = TextEditingController(
        text: quantity.toString(),
      );
      _selectedItemId = null;
      _qtyController.text = '1';
    });
  }

  String? _optionalQuantityValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final quantity = double.tryParse(value.trim());
    if (quantity == null || !quantity.isFinite || quantity < 0) {
      return 'مقدار باید عددی صفر یا بیشتر باشد.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final tasksAsync = ref.watch(workOrderTasksProvider(widget.workOrderId));
    final task = tasksAsync.asData?.value
        .where((task) => task.id == widget.taskId)
        .firstOrNull;
    final planAsync = task?.maintenancePlanId == null
        ? null
        : ref.watch(maintenancePlanDetailProvider(task!.maintenancePlanId!));
    final plan = planAsync?.asData?.value;
    final isMeterPlan =
        task != null &&
        (plan?.scheduleType == ScheduleType.meter ||
            task.plannedMeterValue != null);
    final materialsAsync = task == null
        ? null
        : ref.watch(workOrderMaterialsProvider(task.id));

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تکمیل وظیفه تعمیراتی')),
        body: tasksAsync.when(
          loading: () => const AppLoading(),
          error: (error, _) => AppErrorState(
            message: 'بارگذاری وظایف ناموفق بود: $error',
            onRetry: () =>
                ref.invalidate(workOrderTasksProvider(widget.workOrderId)),
          ),
          data: (_) => const Center(child: Text('وظیفه موردنظر پیدا نشد.')),
        ),
      );
    }
    if (planAsync != null && !planAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(title: const Text('تکمیل وظیفه تعمیراتی')),
        body: planAsync.when(
          loading: () => const AppLoading(),
          error: (error, _) => AppErrorState(
            message: 'بارگذاری برنامه نگهداری ناموفق بود: $error',
            onRetry: () => ref.invalidate(
              maintenancePlanDetailProvider(task.maintenancePlanId!),
            ),
          ),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }
    if (materialsAsync == null || !materialsAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(title: const Text('تکمیل وظیفه تعمیراتی')),
        body:
            materialsAsync?.when(
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(
                message: 'بارگذاری متریال وظیفه ناموفق بود: $error',
                onRetry: () =>
                    ref.invalidate(workOrderMaterialsProvider(widget.taskId)),
              ),
              data: (_) => const SizedBox.shrink(),
            ) ??
            const AppLoading(),
      );
    }
    final taskMaterials = materialsAsync.value!;
    _initializeMaterialQuantities(task.id, taskMaterials);

    return Scaffold(
      appBar: AppBar(title: const Text('تکمیل وظیفه تعمیراتی و ثبت قطعات')),
      body: AppFormBody(
        formKey: _formKey,
        children: [
          DropdownButtonFormField<TaskResult>(
            initialValue: _result,
            decoration: const InputDecoration(
              labelText: 'نتیجه انجام کار *',
              border: OutlineInputBorder(),
            ),
            items: TaskResult.values
                .map(
                  (r) => DropdownMenuItem(value: r, child: Text(r.displayName)),
                )
                .toList(),
            onChanged: (v) => setState(() => _result = v ?? TaskResult.success),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _findingsController,
            decoration: const InputDecoration(
              labelText: 'یافته‌ها و گزارش کار',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
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
                  validator: (v) =>
                      AppValidators.nonNegativeNumber(v, fieldName: 'زمان کار'),
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
                  validator: (v) => AppValidators.nonNegativeNumber(
                    v,
                    fieldName: 'زمان توقف',
                  ),
                ),
              ),
            ],
          ),
          if (isMeterPlan)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextFormField(
                controller: _completionMeterController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      'خوانش نهایی${plan?.meterName == null ? '' : ' ${plan!.meterName}'} *',
                  suffixText: plan?.meterUnit,
                  helperText:
                      'مقدار باید حداقل به هدف ${AppNumberFormat.decimal(task.plannedMeterValue ?? 0)} برسد.',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (!isMeterPlan) return null;
                  final parsed = double.tryParse(value?.trim() ?? '');
                  return parsed == null ||
                          !parsed.isFinite ||
                          parsed < (task.plannedMeterValue ?? 0)
                      ? 'مقدار معتبر و حداقل برابر هدف وارد کنید.'
                      : null;
                },
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'قطعات و اقلام مصرفی انبار در این وظیفه',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'اقلام برنامه‌ریزی‌شده در ادامه آمده‌اند. مقدار واقعی مصرف را وارد کنید؛ مقدار برنامه‌ریزی‌شده به‌تنهایی از موجودی کم نمی‌شود. پس از بازگشایی، فقط مصرف جدید این نوبت را وارد کنید.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),

          inventoryAsync.when(
            data: (items) {
              return _buildMaterialSection(items, taskMaterials);
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => AppErrorState(
              message: 'بارگذاری کالاهای انبار ناموفق بود: $error',
              onRetry: () => ref.invalidate(inventoryItemsProvider),
            ),
          ),

          if (inventoryAsync.hasValue) ...[
            const SizedBox(height: 32),
            AppFormSubmitButton(
              isSubmitting: _isSubmitting,
              onPressed: _complete,
              label: 'ثبت و تکمیل وظیفه',
            ),
          ],
        ],
      ),
    );
  }
}
