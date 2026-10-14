import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../providers/work_order_providers.dart';

class WorkOrderMaterialFormScreen extends ConsumerStatefulWidget {
  final String workOrderId;

  const WorkOrderMaterialFormScreen({super.key, required this.workOrderId});

  @override
  ConsumerState<WorkOrderMaterialFormScreen> createState() => _WorkOrderMaterialFormScreenState();
}

class _WorkOrderMaterialFormScreenState extends ConsumerState<WorkOrderMaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plannedQtyController = TextEditingController(text: '1');
  final _unitCostController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedTaskId;
  String? _selectedItemId;
  bool _isLoading = false;

  @override
  void dispose() {
    _plannedQtyController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedTaskId == null || _selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً وظیفه و کالای انبار را انتخاب کنید.')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workOrderRepositoryProvider);
      await repo.addMaterialToTask(
        workOrderTaskId: _selectedTaskId!,
        itemId: _selectedItemId!,
        plannedQuantity: double.tryParse(_plannedQtyController.text.trim()),
        unitCostAtUse: _unitCostController.text.trim().isEmpty ? null : double.tryParse(_unitCostController.text.trim()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      ref.invalidate(workOrderDetailProvider(widget.workOrderId));
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
    final tasksAsync = ref.watch(workOrderTasksProvider(widget.workOrderId));
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('افزودن قطعه/متریال به دستورکار', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Task selection
              tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) return const Text('ابتدا باید حداقل یک وظیفه به این دستورکار اضافه کنید.');
                  _selectedTaskId ??= tasks.first.id;
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedTaskId,
                    decoration: const InputDecoration(
                      labelText: 'وظیفه مرتبط *',
                      prefixIcon: Icon(EneftyIcons.task_bold),
                      border: OutlineInputBorder(),
                    ),
                    items: tasks.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))).toList(),
                    onChanged: (v) => setState(() => _selectedTaskId = v),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطا: $e'),
              ),
              const SizedBox(height: 16),

              // Inventory Item selection
              inventoryAsync.when(
                data: (items) {
                  if (items.isEmpty) return const Text('کالایی در انبار ثبت نشده است.');
                  _selectedItemId ??= items.first.id;
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedItemId,
                    decoration: const InputDecoration(
                      labelText: 'کالای انبار / قطعه یدکی *',
                      prefixIcon: Icon(EneftyIcons.box_bold),
                      border: OutlineInputBorder(),
                    ),
                    items: items.map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.code})'))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedItemId = v;
                        final selectedItem = items.firstWhere((i) => i.id == v);
                        if (selectedItem.defaultUnitCost != null) {
                          _unitCostController.text = selectedItem.defaultUnitCost.toString();
                        }
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطا: $e'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _plannedQtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'مقدار برنامه‌ریزی شده *',
                  prefixIcon: Icon(EneftyIcons.ruler_bold),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => AppValidators.nonNegativeNumber(v, fieldName: 'مقدار برنامه‌ریزی شده'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _unitCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'قیمت واحد به هنگام مصرف (تومان)',
                  prefixIcon: Icon(EneftyIcons.money_bold),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'یادداشت‌ها',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                icon: const Icon(EneftyIcons.add_bold),
                onPressed: _isLoading ? null : _save,
                label: const Text('ثبت متریال برای دستورکار'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
