import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/validators.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/work_order.dart';
import '../providers/work_order_providers.dart';

class WorkOrderFormScreen extends ConsumerStatefulWidget {
  final String? workOrderId;

  const WorkOrderFormScreen({super.key, this.workOrderId});

  @override
  ConsumerState<WorkOrderFormScreen> createState() =>
      _WorkOrderFormScreenState();
}

class _WorkOrderFormScreenState extends ConsumerState<WorkOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _scheduledAtController = TextEditingController();
  final _notesController = TextEditingController();

  WorkOrderType _workOrderType = WorkOrderType.corrective;
  Priority _priority = Priority.medium;
  bool _isLoading = false;
  WorkOrder? _existingWorkOrder;

  @override
  void initState() {
    super.initState();
    if (widget.workOrderId != null) {
      _loadWorkOrder();
    }
  }

  Future<void> _loadWorkOrder() async {
    setState(() => _isLoading = true);
    try {
      final wo = await ref.read(
        workOrderDetailProvider(widget.workOrderId!).future,
      );
      if (wo != null && mounted) {
        _existingWorkOrder = wo;
        _titleController.text = wo.title;
        _descController.text = wo.description ?? '';
        _scheduledAtController.text = wo.scheduledAt ?? '';
        _notesController.text = wo.notes ?? '';
        _workOrderType = wo.workOrderType;
        _priority = wo.priority;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _scheduledAtController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectScheduledDate() async {
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.now(),
      firstDate: Jalali.now(),
      lastDate: Jalali(1450, 12),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _scheduledAtController.text = formatted);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final facility = await ref.read(primaryFacilityProvider.future);
      if (facility == null) return;
      if (_existingWorkOrder != null) {
        final updated = _existingWorkOrder!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          scheduledAt: _scheduledAtController.text.trim().isEmpty
              ? null
              : _scheduledAtController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          workOrderType: _workOrderType,
          priority: _priority,
        );
        await ref.read(workOrderActionsProvider).updateWorkOrder(updated);
      } else {
        await ref
            .read(workOrderActionsProvider)
            .createWorkOrder(
              facilityId: facility.id,
              title: _titleController.text.trim(),
              description: _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
              scheduledAt: _scheduledAtController.text.trim().isEmpty
                  ? null
                  : _scheduledAtController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              workOrderType: _workOrderType,
              priority: _priority,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.workOrderId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'ویرایش دستورکار' : 'ایجاد دستورکار جدید',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان دستورکار *',
                  prefixIcon: Icon(EneftyIcons.document_text_bold),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    AppValidators.required(v, fieldName: 'عنوان دستورکار'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WorkOrderType>(
                initialValue: _workOrderType,
                decoration: const InputDecoration(
                  labelText: 'نوع دستورکار',
                  prefixIcon: Icon(EneftyIcons.task_bold),
                  border: OutlineInputBorder(),
                ),
                items: WorkOrderType.values
                    .map(
                      (w) => DropdownMenuItem(
                        value: w,
                        child: Text(w.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(
                  () => _workOrderType = v ?? WorkOrderType.corrective,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Priority>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'اولویت',
                  prefixIcon: Icon(EneftyIcons.danger_bold),
                  border: OutlineInputBorder(),
                ),
                items: Priority.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _priority = v ?? Priority.medium),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduledAtController,
                readOnly: true,
                onTap: _selectScheduledDate,
                decoration: const InputDecoration(
                  labelText: 'تاریخ زمان‌بندی (شمسی)',
                  prefixIcon: Icon(EneftyIcons.calendar_2_bold),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'توضیحات / شرح کار',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                icon: Icon(
                  isEditing ? EneftyIcons.edit_2_bold : EneftyIcons.add_bold,
                ),
                onPressed: _isLoading ? null : _save,
                label: Text(isEditing ? 'بروزرسانی دستورکار' : 'ثبت دستورکار'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
