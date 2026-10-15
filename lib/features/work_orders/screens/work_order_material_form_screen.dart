import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../models/work_order_task.dart';
import '../providers/work_order_providers.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _plannedQtyController.dispose();
    _actualQtyController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTaskId == null || _selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً وظیفه و کالای انبار را انتخاب کنید.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(workOrderRepositoryProvider)
          .addMaterialToTask(
            workOrderTaskId: _selectedTaskId!,
            itemId: _selectedItemId!,
            plannedQuantity: _parseOptional(_plannedQtyController.text),
            actualQuantity: _parseOptional(_actualQtyController.text),
            unitCostAtUse: _parseOptional(_unitCostController.text),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      ref.invalidate(workOrderMaterialsProvider(_selectedTaskId!));
      ref.invalidate(workOrderTasksProvider(widget.workOrderId));
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ثبت متریال ناموفق بود: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              return const _MaterialFormMessage(
                icon: EneftyIcons.task_bold,
                message: 'برای افزودن متریال، ابتدا یک وظیفه باز ثبت کنید.',
              );
            }
            _keepSelection(
              availableTasks.map((task) => task.id),
              _selectedTaskId,
              (id) => _selectedTaskId = id,
            );

            return inventoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorState(message: error.toString()),
              data: (items) {
                if (items.isEmpty) {
                  return const _MaterialFormMessage(
                    icon: EneftyIcons.box_bold,
                    message: 'کالای فعالی در انبار ثبت نشده است.',
                  );
                }
                _keepSelection(
                  items.map((item) => item.id),
                  _selectedItemId,
                  (id) => _selectedItemId = id,
                );

                final selectedItem = items.firstWhere(
                  (item) => item.id == _selectedItemId,
                );
                if (_unitCostController.text.isEmpty &&
                    selectedItem.defaultUnitCost != null) {
                  _unitCostController.text = selectedItem.defaultUnitCost
                      .toString();
                }
                return _buildForm(availableTasks, items, selectedItem);
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
    List<InventoryItem> items,
    InventoryItem selectedItem,
  ) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          DropdownButtonFormField<String>(
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
            onChanged: _isLoading
                ? null
                : (value) => setState(() => _selectedTaskId = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedItemId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'کالای انبار / قطعه یدکی *',
              prefixIcon: Icon(EneftyIcons.box_bold),
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
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _selectedItemId = value;
                      final item = items.firstWhere((item) => item.id == value);
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
            enabled: !_isLoading,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'مقدار برنامه‌ریزی‌شده',
              prefixIcon: const Icon(EneftyIcons.ruler_bold),
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
            enabled: !_isLoading,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'مقدار مصرف واقعی',
              helperText: 'موجودی پس از تکمیل وظیفه به‌صورت اتمی کسر می‌شود.',
              prefixIcon: const Icon(EneftyIcons.box_bold),
              suffixText: selectedItem.unit,
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                _optionalNonNegative(value, fieldName: 'مقدار مصرف واقعی'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _unitCostController,
            enabled: !_isLoading,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'بهای واحد هنگام مصرف',
              helperText:
                  'به‌صورت پیش‌فرض از بهای پیش‌فرض کالا استفاده می‌شود.',
              prefixIcon: Icon(EneftyIcons.money_bold),
              suffixText: 'تومان',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                _optionalNonNegative(value, fieldName: 'بهای واحد'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            enabled: !_isLoading,
            decoration: const InputDecoration(
              labelText: 'یادداشت',
              prefixIcon: Icon(EneftyIcons.note_2_bold),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            minLines: 2,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: _isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(EneftyIcons.add_bold),
            onPressed: _isLoading ? null : _save,
            label: const Text('ثبت متریال برای وظیفه'),
          ),
        ],
      ),
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

class _MaterialFormMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MaterialFormMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
