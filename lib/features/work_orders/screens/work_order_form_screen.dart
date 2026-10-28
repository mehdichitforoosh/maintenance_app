import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_form_body.dart';
import '../../../core/widgets/app_form_submit_button.dart';
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

  String? _selectedScheduledAt;
  WorkOrderType _workOrderType = WorkOrderType.corrective;
  Priority _priority = Priority.medium;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;
  WorkOrder? _existingWorkOrder;

  @override
  void initState() {
    super.initState();
    if (widget.workOrderId != null) {
      _loadWorkOrder();
    }
  }

  Future<void> _loadWorkOrder() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final wo = await ref.read(
        workOrderDetailProvider(widget.workOrderId!).future,
      );
      if (wo == null) {
        _loadError = 'دستورکار موردنظر پیدا نشد.';
      } else if (mounted) {
        _existingWorkOrder = wo;
        _titleController.text = wo.title;
        _descController.text = wo.description ?? '';
        _selectedScheduledAt = wo.scheduledAt;
        _scheduledAtController.text = wo.scheduledAt == null
            ? ''
            : AppDateUtils.formatDateOnlyAsJalali(wo.scheduledAt);
        _notesController.text = wo.notes ?? '';
        _workOrderType = wo.workOrderType;
        _priority = wo.priority;
      }
    } catch (error) {
      if (mounted) _loadError = 'بارگذاری دستورکار ناموفق بود: $error';
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
    final selectedDate = AppDateUtils.parseDateOnlyAsJalali(
      _scheduledAtController.text,
    );
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: selectedDate ?? Jalali.now(),
      firstDate: Jalali(1370, 1),
      lastDate: Jalali(1450, 12),
    );
    if (picked != null) {
      setState(() {
        _selectedScheduledAt = AppDateUtils.formatDateOnly(picked.toDateTime());
        _scheduledAtController.text = AppDateUtils.formatDateOnlyAsJalali(
          _selectedScheduledAt,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_isSubmitting || _loadError != null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final facility = await ref.read(primaryFacilityProvider.future);
      if (facility == null) {
        throw StateError('ابتدا اطلاعات کارگاه را ثبت کنید.');
      }
      if (_existingWorkOrder != null) {
        final updated = _existingWorkOrder!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          scheduledAt: _selectedScheduledAt,
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
              scheduledAt: _selectedScheduledAt,
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
      if (mounted) setState(() => _isSubmitting = false);
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
      body: AppFormBody(
        formKey: _formKey,
        isLoading: _isLoading && isEditing && _existingWorkOrder == null,
        loadError: _loadError,
        onRetry: _loadWorkOrder,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان دستورکار *',
              prefixIcon: Icon(EneftyIcons.document_text_outline),
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
              prefixIcon: Icon(EneftyIcons.task_outline),
              border: OutlineInputBorder(),
            ),
            items: WorkOrderType.values
                .map(
                  (w) => DropdownMenuItem(value: w, child: Text(w.displayName)),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _workOrderType = v ?? WorkOrderType.corrective),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Priority>(
            initialValue: _priority,
            decoration: const InputDecoration(
              labelText: 'اولویت',
              prefixIcon: Icon(EneftyIcons.danger_outline),
              border: OutlineInputBorder(),
            ),
            items: Priority.values
                .map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.displayName)),
                )
                .toList(),
            onChanged: (v) => setState(() => _priority = v ?? Priority.medium),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _scheduledAtController,
            readOnly: true,
            onTap: _selectScheduledDate,
            decoration: const InputDecoration(
              labelText: 'تاریخ زمان‌بندی (شمسی)',
              prefixIcon: Icon(EneftyIcons.calendar_2_outline),
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
          AppFormSubmitButton(
            isSubmitting: _isSubmitting,
            onPressed: _save,
            label: isEditing ? 'بروزرسانی دستورکار' : 'ثبت دستورکار',
          ),
        ],
      ),
    );
  }
}
