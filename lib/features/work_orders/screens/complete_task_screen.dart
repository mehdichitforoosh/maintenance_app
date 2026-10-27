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
import '../../inventory/providers/inventory_providers.dart';
import '../../maintenance/models/maintenance_plan.dart';
import '../../maintenance/providers/maintenance_providers.dart';
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

  // Selected consumed material
  String? _selectedItemId;
  final _qtyController = TextEditingController(text: '1');
  final List<Map<String, dynamic>> _consumedMaterials = [];

  @override
  void dispose() {
    _findingsController.dispose();
    _laborController.dispose();
    _downtimeController.dispose();
    _completionMeterController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
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
            consumedMaterials: _consumedMaterials.isEmpty
                ? null
                : _consumedMaterials,
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
            'اگر مصرف قبلاً ثبت شده، در تکمیل اول آن را دوباره وارد نکنید. پس از بازگشایی، مقدار واردشده برای کالای قبلی به مصرف ثبت‌شده قبلی اضافه می‌شود.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),

          inventoryAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('کالایی در انبار ثبت نشده است.');
              }
              _selectedItemId ??= items.first.id;

              final selectedItem = items.firstWhere(
                (item) => item.id == _selectedItemId,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedItemId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'انتخاب کالا',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map(
                          (i) => DropdownMenuItem(
                            value: i.id,
                            child: Text(
                              '${i.name} (${i.code})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedItemId = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'مقدار مصرف',
                            suffixText: selectedItem.unit,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        tooltip: 'افزودن کالا به فهرست مصرف',
                        icon: const Icon(EneftyIcons.add_bold),
                        onPressed: () {
                          if (_selectedItemId != null) {
                            final qty = double.tryParse(
                              _qtyController.text.trim(),
                            );
                            if (qty == null || !qty.isFinite || qty <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'مقدار مصرف باید عددی بزرگ‌تر از صفر باشد.',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (_consumedMaterials.any(
                              (material) =>
                                  material['item_id'] == _selectedItemId,
                            )) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'این کالا قبلاً به فهرست مصرف افزوده شده است.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final item = items.firstWhere(
                              (i) => i.id == _selectedItemId,
                            );
                            setState(() {
                              _consumedMaterials.add({
                                'item_id': item.id,
                                'item_name': item.name,
                                'quantity': qty,
                                'unit_cost': item.defaultUnitCost ?? 0.0,
                              });
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => AppErrorState(
              message: 'بارگذاری کالاهای انبار ناموفق بود: $error',
              onRetry: () => ref.invalidate(inventoryItemsProvider),
            ),
          ),

          if (_consumedMaterials.isNotEmpty) ...[
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _consumedMaterials.length,
              itemBuilder: (context, index) {
                final mat = _consumedMaterials[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      mat['item_name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'مقدار مصرفی: ${AppNumberFormat.decimal(mat['quantity'] as num)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(EneftyIcons.trash_outline, color: Colors.red),
                      onPressed: () =>
                          setState(() => _consumedMaterials.removeAt(index)),
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 32),
          AppFormSubmitButton(
            icon: const Icon(Icons.task_alt),
            isSubmitting: _isSubmitting,
            onPressed: _complete,
            label: 'ثبت و تکمیل وظیفه',
          ),
        ],
      ),
    );
  }
}
