import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_form_body.dart';
import '../../../core/widgets/app_form_submit_button.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../models/work_order_material.dart';
import '../models/work_order_task.dart';
import '../providers/work_order_providers.dart';
import 'widgets/material_form_message.dart';

class WorkOrderMaterialFormScreen extends ConsumerStatefulWidget {
  final String workOrderId;

  const WorkOrderMaterialFormScreen({super.key, required this.workOrderId});

  @override
  ConsumerState<WorkOrderMaterialFormScreen> createState() =>
      _WorkOrderMaterialFormScreenState();
}

class _WorkOrderMaterialFormScreenState
    extends ConsumerState<WorkOrderMaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plannedQtyController = TextEditingController();
  final _actualQtyController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedTaskId;
  String? _selectedItemId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _plannedQtyController.dispose();
    _actualQtyController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTaskId == null || _selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً وظیفه و کالای انبار را انتخاب کنید.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(workOrderActionsProvider)
          .addMaterial(
            workOrderId: widget.workOrderId,
            taskId: _selectedTaskId!,
            itemId: _selectedItemId!,
            plannedQuantity: _parseOptional(_plannedQtyController.text),
            actualQuantity: _parseOptional(_actualQtyController.text),
            unitCostAtUse: _parseOptional(_unitCostController.text),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ثبت متریال ناموفق بود: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  double? _parseOptional(String value) {
    if (value.trim().isEmpty) return null;
    return double.parse(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(workOrderTasksProvider(widget.workOrderId));
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('افزودن قطعه یا متریال')),
      body: SafeArea(
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AppErrorState(message: error.toString()),
          data: (tasks) {
            final availableTasks = tasks
                .where(
                  (task) =>
                      task.status == TaskStatus.pending ||
                      task.status == TaskStatus.inProgress,
                )
                .toList();
            if (availableTasks.isEmpty) {
              return const MaterialFormMessage(
                icon: EneftyIcons.task_bold,
                message: 'برای افزودن متریال، ابتدا یک وظیفه باز ثبت کنید.',
              );
            }
            _keepSelection(
              availableTasks.map((task) => task.id),
              _selectedTaskId,
              (id) => _selectedTaskId = id,
            );
            final selectedTask = availableTasks.firstWhere(
              (task) => task.id == _selectedTaskId,
            );
            final taskMaterialsAsync = ref.watch(
              workOrderMaterialsProvider(selectedTask.id),
            );

            return inventoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorState(message: error.toString()),
              data: (items) {
                return taskMaterialsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => AppErrorState(
                    message: 'بارگذاری متریال ثبت‌شده ناموفق بود: $error',
                    onRetry: () => ref.invalidate(
                      workOrderMaterialsProvider(selectedTask.id),
                    ),
                  ),
                  data: (taskMaterials) =>
                      _buildForm(availableTasks, items, taskMaterials),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _keepSelection(
    Iterable<String> ids,
    String? selectedId,
    ValueChanged<String> setSelection,
  ) {
    if (selectedId == null || !ids.contains(selectedId)) {
      setSelection(ids.first);
    }
  }

  Widget _buildForm(
    List<WorkOrderTask> tasks,
    List<InventoryItem> allItems,
    List<WorkOrderMaterial> taskMaterials,
  ) {
    final existingItemIds = {
      for (final material in taskMaterials) material.itemId,
    };
    final items = allItems
        .where((item) => !existingItemIds.contains(item.id))
        .toList();

    if (items.isEmpty) {
      return _buildNoMaterialForm(
        tasks,
        allItems.isEmpty
            ? 'هنوز کالای فعالی در انبار ثبت نشده است.'
            : 'همه کالاهای فعال انبار قبلاً برای این وظیفه ثبت شده‌اند.',
        taskMaterials: taskMaterials,
        allItems: allItems,
      );
    }

    _keepSelection(items.map((item) => item.id), _selectedItemId, (id) {
      _selectedItemId = id;
      _plannedQtyController.clear();
      _actualQtyController.clear();
      _unitCostController.clear();
    });
    final selectedItem = items.firstWhere((item) => item.id == _selectedItemId);
    if (_unitCostController.text.isEmpty &&
        selectedItem.defaultUnitCost != null) {
      _unitCostController.text = selectedItem.defaultUnitCost.toString();
    }

    return AppFormBody(
      formKey: _formKey,
      children: [
        _taskSelector(tasks),
        if (taskMaterials.isNotEmpty) ...[
          const SizedBox(height: 12),
          _existingMaterials(taskMaterials, allItems),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedItemId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'کالای انبار / قطعه یدکی *',
            helperText:
                'می‌توانید هر کالای فعال انبار را انتخاب کنید؛ کالاهای ثبت‌شده برای این وظیفه نمایش داده نمی‌شوند.',
            prefixIcon: Icon(EneftyIcons.box_outline),
            border: OutlineInputBorder(),
          ),
          items: items
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
              : (value) {
                  setState(() {
                    _selectedItemId = value;
                    final item = items.firstWhere((item) => item.id == value);
                    _plannedQtyController.clear();
                    _actualQtyController.clear();
                    _unitCostController.text =
                        item.defaultUnitCost?.toString() ?? '';
                  });
                },
        ),
        const SizedBox(height: 20),
        Text(
          'مقادیر متریال',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _plannedQtyController,
          enabled: !_isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'مقدار برنامه‌ریزی‌شده',
            prefixIcon: const Icon(EneftyIcons.ruler_outline),
            suffixText: selectedItem.unit,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final error = _optionalNonNegative(
              value,
              fieldName: 'مقدار برنامه‌ریزی‌شده',
            );
            if (error != null) return error;
            if ((value == null || value.trim().isEmpty) &&
                _actualQtyController.text.trim().isEmpty) {
              return 'مقدار برنامه‌ریزی‌شده یا مقدار مصرف واقعی را وارد کنید.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _actualQtyController,
          enabled: !_isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'مقدار مصرف واقعی',
            helperText: 'موجودی پس از تکمیل وظیفه به‌صورت اتمی کسر می‌شود.',
            prefixIcon: const Icon(EneftyIcons.ruler_pen_outline),
            suffixText: selectedItem.unit,
            border: const OutlineInputBorder(),
          ),
          validator: (value) =>
              _optionalNonNegative(value, fieldName: 'مقدار مصرف واقعی'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _unitCostController,
          enabled: !_isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'بهای واحد هنگام مصرف',
            helperText: 'به‌صورت پیش‌فرض از بهای پیش‌فرض کالا استفاده می‌شود.',
            prefixIcon: Icon(EneftyIcons.money_outline),
            suffixText: 'تومان',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              _optionalNonNegative(value, fieldName: 'بهای واحد'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'یادداشت',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          minLines: 2,
        ),
        const SizedBox(height: 24),
        AppFormSubmitButton(
          isSubmitting: _isSubmitting,
          onPressed: _save,
          label: 'ثبت متریال برای وظیفه',
        ),
      ],
    );
  }

  Widget _buildNoMaterialForm(
    List<WorkOrderTask> tasks,
    String message, {
    List<WorkOrderMaterial> taskMaterials = const [],
    List<InventoryItem> allItems = const [],
  }) {
    return AppFormBody(
      formKey: _formKey,
      children: [
        _taskSelector(tasks),
        const SizedBox(height: 16),
        MaterialFormMessage(icon: EneftyIcons.box_bold, message: message),
        if (taskMaterials.isNotEmpty) ...[
          const SizedBox(height: 12),
          _existingMaterials(taskMaterials, allItems),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.center,
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _openInventoryForm,
            icon: const Icon(EneftyIcons.box_add_bold),
            label: const Text('ثبت کالای جدید در انبار'),
          ),
        ),
      ],
    );
  }

  Widget _existingMaterials(
    List<WorkOrderMaterial> materials,
    List<InventoryItem> items,
  ) {
    final itemById = {for (final item in items) item.id: item};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'متریال ثبت‌شده برای این وظیفه',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...materials.map((material) {
              final item = itemById[material.itemId];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(EneftyIcons.box_bold),
                title: Text(item?.name ?? 'کالای غیرفعال یا حذف‌شده'),
                subtitle: Text(
                  material.plannedQuantity == null
                      ? 'مقدار برنامه‌ریزی‌شده ثبت نشده است.'
                      : 'برنامه‌ریزی‌شده: ${AppNumberFormat.decimal(material.plannedQuantity!)} ${item?.unit ?? ''}',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _openInventoryForm() async {
    await context.push('/inventory/new');
    if (mounted) ref.invalidate(inventoryItemsProvider);
  }

  Widget _taskSelector(List<WorkOrderTask> tasks) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedTaskId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'وظیفه مرتبط *',
        prefixIcon: Icon(EneftyIcons.task_bold),
        border: OutlineInputBorder(),
      ),
      items: tasks
          .map(
            (task) => DropdownMenuItem(
              value: task.id,
              child: Text(task.title, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: _isSubmitting
          ? null
          : (value) {
              setState(() {
                _selectedTaskId = value;
                _selectedItemId = null;
                _plannedQtyController.clear();
                _actualQtyController.clear();
                _unitCostController.clear();
                _notesController.clear();
              });
            },
    );
  }

  String? _optionalNonNegative(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    if (number == null || !number.isFinite || number < 0) {
      return '$fieldName باید عددی معتبر و صفر یا بزرگ‌تر باشد.';
    }
    return null;
  }
}
