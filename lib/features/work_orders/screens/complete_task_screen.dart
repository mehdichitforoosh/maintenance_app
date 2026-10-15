import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/validators.dart';
import '../../inventory/providers/inventory_providers.dart';
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
  TaskResult _result = TaskResult.success;
  bool _isLoading = false;

  // Selected consumed material
  String? _selectedItemId;
  final _qtyController = TextEditingController(text: '1');
  final List<Map<String, dynamic>> _consumedMaterials = [];

  @override
  void dispose() {
    _findingsController.dispose();
    _laborController.dispose();
    _downtimeController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workOrderRepositoryProvider);
      await repo.completeTask(
        taskId: widget.taskId,
        result: _result,
        findings: _findingsController.text.trim().isEmpty
            ? null
            : _findingsController.text.trim(),
        laborMinutes: int.tryParse(_laborController.text.trim()) ?? 0,
        downtimeMinutes: int.tryParse(_downtimeController.text.trim()) ?? 0,
        consumedMaterials: _consumedMaterials.isEmpty
            ? null
            : _consumedMaterials,
      );

      ref.invalidate(workOrderDetailProvider(widget.workOrderId));
      ref.invalidate(workOrderTasksProvider(widget.workOrderId));
      ref.invalidate(workOrderMaterialsProvider(widget.taskId));
      ref.invalidate(inventoryItemsProvider);
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
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تکمیل وظیفه تعمیراتی و ثبت قطعات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<TaskResult>(
                initialValue: _result,
                decoration: const InputDecoration(
                  labelText: 'نتیجه انجام کار *',
                  border: OutlineInputBorder(),
                ),
                items: TaskResult.values
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _result = v ?? TaskResult.success),
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
                      validator: (v) => AppValidators.nonNegativeNumber(
                        v,
                        fieldName: 'زمان کار',
                      ),
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
              const SizedBox(height: 24),
              const Text(
                'قطعات و اقلام مصرفی انبار در این وظیفه',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'اگر مقدار مصرف را در فرم متریال ثبت کرده‌اید، اینجا دوباره همان کالا را اضافه نکنید.',
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                error: (error, _) =>
                    Text('بارگذاری کالاهای انبار ناموفق بود: $error'),
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
                        subtitle: Text('مقدار مصرفی: ${mat['quantity']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(
                            () => _consumedMaterials.removeAt(index),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _complete,
                child: const Text('ثبت و تکمیل وظیفه'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
