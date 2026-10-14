import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/validators.dart';
import '../../assets/providers/asset_providers.dart';
import '../../facilities/providers/facility_providers.dart';
import '../providers/work_order_providers.dart';

class WorkOrderTaskFormScreen extends ConsumerStatefulWidget {
  final String workOrderId;

  const WorkOrderTaskFormScreen({super.key, required this.workOrderId});

  @override
  ConsumerState<WorkOrderTaskFormScreen> createState() => _WorkOrderTaskFormScreenState();
}

class _WorkOrderTaskFormScreenState extends ConsumerState<WorkOrderTaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dueDateController = TextEditingController();

  String? _selectedAssetId;
  ActivityType _activityType = ActivityType.inspection;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.now(),
      firstDate: Jalali.now(),
      lastDate: Jalali(1450, 12),
    );
    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _dueDateController.text = formatted);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedAssetId == null) {
      if (_selectedAssetId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً تجهیز مرتبط با وظیفه را انتخاب کنید.')));
      }
      return;
    }
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workOrderRepositoryProvider);
      await repo.addTaskToWorkOrder(
        workOrderId: widget.workOrderId,
        assetId: _selectedAssetId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        activityType: _activityType,
        plannedDueAt: _dueDateController.text.trim().isEmpty ? null : _dueDateController.text.trim(),
      );

      ref.invalidate(workOrderTasksProvider(widget.workOrderId));
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
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('افزودن وظیفه جدید به دستورکار', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Asset Selection
              facilityAsync.when(
                data: (facility) {
                  if (facility == null) return const SizedBox.shrink();
                  final assetsAsync = ref.watch(assetsProvider(facility.id));
                  return assetsAsync.when(
                    data: (assets) {
                      if (assets.isEmpty) return const Text('ابتدا باید تجهیزی در سیستم ثبت کنید.');
                      _selectedAssetId ??= assets.first.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedAssetId,
                          decoration: const InputDecoration(
                            labelText: 'تجهیز هدف *',
                            prefixIcon: Icon(EneftyIcons.cpu_bold),
                            border: OutlineInputBorder(),
                          ),
                          items: assets.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.code})'))).toList(),
                          onChanged: (v) => setState(() => _selectedAssetId = v),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('خطا: $e'),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان وظیفه *',
                  prefixIcon: Icon(EneftyIcons.task_bold),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => AppValidators.required(v, fieldName: 'عنوان وظیفه'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivityType>(
                initialValue: _activityType,
                decoration: const InputDecoration(
                  labelText: 'نوع فعالیت',
                  prefixIcon: Icon(EneftyIcons.setting_bold),
                  border: OutlineInputBorder(),
                ),
                items: ActivityType.values.map((a) => DropdownMenuItem(value: a, child: Text(a.displayName))).toList(),
                onChanged: (v) => setState(() => _activityType = v ?? ActivityType.inspection),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                onTap: _selectDueDate,
                decoration: const InputDecoration(
                  labelText: 'تاریخ سررسید برنامه (شمسی)',
                  prefixIcon: Icon(EneftyIcons.calendar_2_bold),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'توضیحات و دستورالعمل وظیفه',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(EneftyIcons.add_bold),
                onPressed: _isLoading ? null : _save,
                label: const Text('افزودن وظیفه به دستورکار'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
