import 'dart:convert';

import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_body.dart';
import '../../../core/widgets/app_form_submit_button.dart';
import '../../assets/providers/asset_providers.dart';
import '../../facilities/providers/facility_providers.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_plan_material.dart';
import '../providers/maintenance_providers.dart';

class MaintenancePlanFormScreen extends ConsumerStatefulWidget {
  final String assetId;
  final String? planId;

  const MaintenancePlanFormScreen({
    super.key,
    required this.assetId,
    this.planId,
  });

  @override
  ConsumerState<MaintenancePlanFormScreen> createState() =>
      _MaintenancePlanFormScreenState();
}

class _MaintenancePlanFormScreenState
    extends ConsumerState<MaintenancePlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _intervalController = TextEditingController(text: '30');
  final _meterNameController = TextEditingController();
  final _meterIntervalController = TextEditingController();
  final _meterUnitController = TextEditingController();
  final _meterStartValueController = TextEditingController();
  final _oneTimeDueController = TextEditingController();
  final _conditionMetricController = TextEditingController(text: 'temperature');
  final _conditionThresholdController = TextEditingController(text: '80');
  final _conditionUnitController = TextEditingController(text: '°C');
  String? _selectedAssetId;
  String _conditionOperator = 'gte';
  ActivityType _activityType = ActivityType.inspection;
  Priority _priority = Priority.medium;
  ScheduleType _scheduleType = ScheduleType.calendar;
  bool _isActive = true;
  CalendarUnit _calendarUnit = CalendarUnit.day;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;
  MaintenancePlan? _existingPlan;
  List<_PlanMaterialDraft> _materials = [];

  String get _scheduleHelpText {
    switch (_scheduleType) {
      case ScheduleType.calendar:
        return 'برنامه بر اساس فاصله زمانی مشخص‌شده اجرا می‌شود؛ '
            'برای مثال، هر ۳۰ روز یک‌بار.';
      case ScheduleType.meter:
        return 'با ثبت خوانش شاخص انتخاب‌شده، هنگام رسیدن به مقدار هدف '
            'یک وظیفه نگهداری ساخته می‌شود.';
      case ScheduleType.condition:
        return 'با ثبت خوانش جدید برای تجهیز، شرط بررسی می‌شود و '
            'در صورت برقرار بودن، یک وظیفه نگهداری ایجاد خواهد شد.';
      case ScheduleType.oneTime:
        return 'این برنامه فقط یک‌بار و در تاریخ تعیین‌شده اجرا می‌شود.';
      case ScheduleType.manual:
        return 'برای این برنامه زمان‌بندی خودکار تعریف نمی‌شود و اجرای آن '
            'به‌صورت دستی ثبت خواهد شد.';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedAssetId = widget.assetId.isNotEmpty ? widget.assetId : null;
    if (widget.planId != null) {
      _loadPlan();
    }
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final repo = ref.read(maintenancePlanRepositoryProvider);
      final plan = await repo.getPlanById(widget.planId!);
      if (plan == null) {
        _loadError = 'برنامه نگهداری موردنظر پیدا نشد.';
      } else if (mounted) {
        _existingPlan = plan;
        _selectedAssetId = plan.assetId;
        _titleController.text = plan.title;
        _descController.text = plan.description ?? '';
        _activityType = plan.activityType;
        _priority = plan.priority;
        _scheduleType = plan.scheduleType;
        _isActive = plan.isActive;
        _meterNameController.text = plan.meterName ?? '';
        _meterIntervalController.text = plan.meterInterval?.toString() ?? '';
        _meterUnitController.text = plan.meterUnit ?? '';
        _meterStartValueController.text =
            plan.nextDueMeterValue?.toString() ?? '';
        if (plan.calendarIntervalValue != null) {
          _intervalController.text = plan.calendarIntervalValue.toString();
        }
        if (mounted) {
          final materials = await ref
              .read(maintenancePlanRepositoryProvider)
              .getPlanMaterials(plan.id);
          _materials = materials.map(_PlanMaterialDraft.fromModel).toList();
        }
        if (plan.calendarIntervalUnit != null) {
          _calendarUnit = plan.calendarIntervalUnit!;
        }
        _oneTimeDueController.text = plan.oneTimeDueAt == null
            ? ''
            : AppDateUtils.formatDisplay(plan.oneTimeDueAt, includeTime: false);
        _selectedOneTimeDueDate = plan.oneTimeDueAt;
        final conditionJson = plan.conditionConfigJson;
        if (conditionJson != null) {
          final decoded = jsonDecode(conditionJson);
          if (decoded is Map<String, dynamic>) {
            _conditionMetricController.text =
                decoded['metric'] as String? ?? 'temperature';
            _conditionOperator = decoded['operator'] as String? ?? 'gte';
            _conditionThresholdController.text =
                decoded['threshold']?.toString() ?? '80';
            _conditionUnitController.text = decoded['unit'] as String? ?? '°C';
          }
        }
      }
    } catch (error) {
      _loadError = 'خطا در دریافت برنامه نگهداری: $error';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _intervalController.dispose();
    _meterNameController.dispose();
    _meterIntervalController.dispose();
    _meterUnitController.dispose();
    _meterStartValueController.dispose();
    _oneTimeDueController.dispose();
    _conditionMetricController.dispose();
    _conditionThresholdController.dispose();
    _conditionUnitController.dispose();
    super.dispose();
  }

  Future<void> _selectOneTimeDueDate() async {
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.now(),
      firstDate: Jalali(1370, 1),
      lastDate: Jalali(1450, 12),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedOneTimeDueDate = AppDateUtils.formatDateOnly(
          picked.toDateTime(),
        );
        _oneTimeDueController.text = AppDateUtils.formatDisplay(
          _selectedOneTimeDueDate,
          includeTime: false,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_isSubmitting || _loadError != null) return;
    if (!_formKey.currentState!.validate() || _selectedAssetId == null) {
      if (_selectedAssetId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً تجهیز موردنظر را انتخاب کنید.')),
        );
      }
      return;
    }
    final oneTimeDueAt = _scheduleType == ScheduleType.oneTime
        ? _oneTimeDueDateIso
        : null;
    final conditionConfigJson = _scheduleType == ScheduleType.condition
        ? jsonEncode({
            'metric': _conditionMetricController.text.trim(),
            'operator': _conditionOperator,
            'threshold': double.parse(
              _conditionThresholdController.text.trim(),
            ),
            'unit': _conditionUnitController.text.trim(),
          })
        : null;
    final meterName = _scheduleType == ScheduleType.meter
        ? _meterNameController.text.trim()
        : null;
    final meterInterval = _scheduleType == ScheduleType.meter
        ? double.tryParse(_meterIntervalController.text.trim())
        : null;
    final meterUnit = _scheduleType == ScheduleType.meter
        ? _meterUnitController.text.trim()
        : null;
    final nextDueMeterValue = _scheduleType == ScheduleType.meter
        ? double.tryParse(_meterStartValueController.text.trim())
        : null;
    if (_scheduleType == ScheduleType.oneTime && oneTimeDueAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً تاریخ اجرای برنامه را انتخاب کنید.'),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      if (_existingPlan != null) {
        final updated = _existingPlan!.copyWith(
          assetId: _selectedAssetId!,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          activityType: _activityType,
          priority: _priority,
          scheduleType: _scheduleType,
          isActive: _isActive,
          clearDescription: _descController.text.trim().isEmpty,
          clearScheduleFields: true,
          calendarIntervalValue: _scheduleType == ScheduleType.calendar
              ? int.parse(_intervalController.text.trim())
              : null,
          calendarIntervalUnit: _scheduleType == ScheduleType.calendar
              ? _calendarUnit
              : null,
          nextDueAt: _scheduleType == ScheduleType.calendar
              ? _existingPlan!.nextDueAt
              : null,
          startDate: _scheduleType == ScheduleType.calendar
              ? _existingPlan!.startDate
              : null,
          oneTimeDueAt: oneTimeDueAt,
          conditionConfigJson: conditionConfigJson,
          meterName: meterName,
          meterInterval: meterInterval,
          meterUnit: meterUnit,
          lastCompletedMeterValue:
              _scheduleType == ScheduleType.meter &&
                  _existingPlan!.scheduleType == ScheduleType.meter &&
                  _existingPlan!.meterName?.trim().toLowerCase() ==
                      meterName?.toLowerCase() &&
                  _existingPlan!.meterUnit?.trim().toLowerCase() ==
                      meterUnit?.toLowerCase()
              ? _existingPlan!.lastCompletedMeterValue
              : null,
          nextDueMeterValue: nextDueMeterValue,
          clearLastCompletedMeterValue: _scheduleType != ScheduleType.meter,
          clearNextDueMeterValue: _scheduleType != ScheduleType.meter,
        );
        await ref
            .read(maintenancePlanActionsProvider)
            .update(
              updated,
              previousAssetId: _existingPlan!.assetId,
              materials: _materialPayload,
            );
      } else {
        await ref
            .read(maintenancePlanActionsProvider)
            .create(
              assetId: _selectedAssetId!,
              title: _titleController.text.trim(),
              description: _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
              activityType: _activityType,
              priority: _priority,
              scheduleType: _scheduleType,
              isActive: _isActive,
              calendarIntervalValue: _scheduleType == ScheduleType.calendar
                  ? int.parse(_intervalController.text.trim())
                  : null,
              calendarIntervalUnit: _scheduleType == ScheduleType.calendar
                  ? _calendarUnit
                  : null,
              conditionConfigJson: conditionConfigJson,
              oneTimeDueAt: oneTimeDueAt,
              meterName: meterName,
              meterInterval: meterInterval,
              meterUnit: meterUnit,
              nextDueMeterValue: nextDueMeterValue,
              materials: _materialPayload,
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
    final isEditing = widget.planId != null;
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'ویرایش برنامه PM' : 'تعریف برنامه نگهداری جدید (PM)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: AppFormBody(
        formKey: _formKey,
        isLoading: _isLoading && _existingPlan == null,
        loadError: _loadError,
        onRetry: _loadPlan,
        children: [
          // Asset Selection if not editing or when needed
          facilityAsync.when(
            data: (facility) {
              if (facility == null) {
                return const Text('ابتدا اطلاعات کارگاه را ثبت کنید.');
              }
              final assetsAsync = ref.watch(assetsProvider(facility.id));
              return assetsAsync.when(
                data: (assets) {
                  if (assets.isEmpty) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        color: colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                EneftyIcons.info_circle_outline,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'ابتدا باید تجهیزی در سیستم ثبت کنید.',
                                  style: TextStyle(
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  _selectedAssetId ??= assets.first.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedAssetId,
                      decoration: const InputDecoration(
                        labelText: 'انتخاب تجهیز *',
                        prefixIcon: Icon(EneftyIcons.cpu_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: assets
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text('${a.name} (${a.code})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAssetId = v),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطا در دریافت تجهیزات: $e'),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(
              'خطا در دریافت اطلاعات کارگاه: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان برنامه *',
              prefixIcon: Icon(EneftyIcons.calendar_2_outline),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                AppValidators.required(v, fieldName: 'عنوان برنامه'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ActivityType>(
            initialValue: _activityType,
            decoration: const InputDecoration(
              labelText: 'نوع فعالیت',
              prefixIcon: Icon(EneftyIcons.task_outline),
              border: OutlineInputBorder(),
            ),
            items: ActivityType.values
                .map(
                  (a) => DropdownMenuItem(value: a, child: Text(a.displayName)),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _activityType = v ?? ActivityType.inspection),
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
          DropdownButtonFormField<ScheduleType>(
            initialValue: _scheduleType,
            decoration: const InputDecoration(
              labelText: 'نوع زمان‌بندی',
              prefixIcon: Icon(EneftyIcons.clock_outline),
              border: OutlineInputBorder(),
            ),
            items: ScheduleType.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s == ScheduleType.meter
                          ? '${s.displayName} (بر اساس ثبت خوانش)'
                          : s.displayName,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _scheduleType = v ?? ScheduleType.calendar),
          ),
          const SizedBox(height: 10),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    EneftyIcons.info_circle_outline,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _scheduleHelpText,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_scheduleType == ScheduleType.calendar) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'فاصله زمانی *',
                      prefixIcon: Icon(EneftyIcons.timer_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      return parsed == null || parsed <= 0
                          ? 'فاصله زمانی باید عدد صحیح بزرگ‌تر از صفر باشد.'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<CalendarUnit>(
                    initialValue: _calendarUnit,
                    decoration: const InputDecoration(
                      labelText: 'واحد',
                      border: OutlineInputBorder(),
                    ),
                    items: CalendarUnit.values
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(u.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _calendarUnit = v ?? CalendarUnit.day),
                  ),
                ),
              ],
            ),
          ],
          if (_scheduleType == ScheduleType.meter) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _meterNameController,
              decoration: const InputDecoration(
                labelText: 'نام شاخص کارکرد *',
                hintText: 'مانند operating_hours',
                border: OutlineInputBorder(),
              ),
              validator: _scheduleType == ScheduleType.meter
                  ? (value) =>
                        AppValidators.required(value, fieldName: 'نام شاخص')
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _meterIntervalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'فاصله کارکرد *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_scheduleType != ScheduleType.meter) {
                        return null;
                      }
                      final parsed = double.tryParse(value?.trim() ?? '');
                      return parsed == null || !parsed.isFinite || parsed <= 0
                          ? 'فاصله کارکرد باید عددی بزرگ‌تر از صفر باشد.'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _meterUnitController,
                    decoration: const InputDecoration(
                      labelText: 'واحد *',
                      hintText: 'ساعت',
                      border: OutlineInputBorder(),
                    ),
                    validator: _scheduleType == ScheduleType.meter
                        ? (value) => AppValidators.required(
                            value,
                            fieldName: 'واحد کارکرد',
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _meterStartValueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'اولین مقدار هدف *',
                helperText:
                    'این مقدار باید با واحد شاخص و خوانش‌ها یکسان باشد.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_scheduleType != ScheduleType.meter) {
                  return null;
                }
                final parsed = double.tryParse(value?.trim() ?? '');
                return parsed == null || !parsed.isFinite || parsed < 0
                    ? 'مقدار صفر یا بزرگ‌تر وارد کنید.'
                    : null;
              },
            ),
          ],
          if (_scheduleType == ScheduleType.oneTime) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _oneTimeDueController,
              readOnly: true,
              onTap: _selectOneTimeDueDate,
              decoration: const InputDecoration(
                labelText: 'تاریخ اجرای برنامه *',
                prefixIcon: Icon(EneftyIcons.calendar_2_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  AppValidators.required(value, fieldName: 'تاریخ اجرا'),
            ),
          ],
          if (_scheduleType == ScheduleType.condition) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _conditionMetricController,
              decoration: const InputDecoration(
                labelText: 'نام شاخص *',
                hintText: 'مانند temperature',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  AppValidators.required(value, fieldName: 'نام شاخص'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _conditionOperator,
                    decoration: const InputDecoration(
                      labelText: 'شرط *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'gt', child: Text('بیشتر از')),
                      DropdownMenuItem(
                        value: 'gte',
                        child: Text('بزرگ‌تر یا مساوی'),
                      ),
                      DropdownMenuItem(value: 'lt', child: Text('کمتر از')),
                      DropdownMenuItem(
                        value: 'lte',
                        child: Text('کوچک‌تر یا مساوی'),
                      ),
                      DropdownMenuItem(value: 'eq', child: Text('برابر')),
                    ],
                    onChanged: (value) =>
                        setState(() => _conditionOperator = value ?? 'gte'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _conditionThresholdController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'مقدار *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      return parsed == null || !parsed.isFinite
                          ? 'عدد معتبر وارد کنید.'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _conditionUnitController,
              decoration: const InputDecoration(
                labelText: 'واحد شاخص *',
                hintText: 'مانند °C',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  AppValidators.required(value, fieldName: 'واحد شاخص'),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'توضیحات',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text(
                'برنامه فعال باشد',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'با غیرفعال‌کردن، اجرای خودکار برنامه متوقف می‌شود؛ '
                'سوابق قبلی حفظ خواهند شد.',
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              secondary: Icon(
                _isActive
                    ? EneftyIcons.tick_circle_bold
                    : EneftyIcons.close_circle_bold,
                color: _isActive
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _PlanMaterialsEditor(
            materials: _materials,
            onChanged: (materials) => setState(() => _materials = materials),
          ),
          const SizedBox(height: 24),
          AppFormSubmitButton(
            icon: Icon(
              isEditing ? EneftyIcons.edit_2_bold : EneftyIcons.add_bold,
            ),
            isSubmitting: _isSubmitting,
            onPressed: _save,
            label: isEditing ? 'بروزرسانی برنامه PM' : 'ذخیره برنامه PM',
          ),
        ],
      ),
    );
  }

  String? get _oneTimeDueDateIso {
    final plan = _existingPlan;
    if (_oneTimeDueController.text.isEmpty) return null;
    if (plan?.oneTimeDueAt != null &&
        _oneTimeDueController.text ==
            AppDateUtils.formatDisplay(
              plan!.oneTimeDueAt,
              includeTime: false,
            )) {
      return plan.oneTimeDueAt;
    }
    // The picker selection is stored separately so the display stays Jalali.
    return _selectedOneTimeDueDate;
  }

  String? _selectedOneTimeDueDate;

  List<Map<String, dynamic>> get _materialPayload => _materials
      .map(
        (material) => {
          'item_id': material.itemId,
          'planned_quantity': material.plannedQuantity,
          'notes': material.notes,
        },
      )
      .toList();
}

class _PlanMaterialDraft {
  final String itemId;
  final double plannedQuantity;
  final String? notes;

  const _PlanMaterialDraft({
    required this.itemId,
    required this.plannedQuantity,
    this.notes,
  });

  factory _PlanMaterialDraft.fromModel(MaintenancePlanMaterial material) =>
      _PlanMaterialDraft(
        itemId: material.itemId,
        plannedQuantity: material.plannedQuantity,
        notes: material.notes,
      );
}

class _PlanMaterialsEditor extends ConsumerWidget {
  final List<_PlanMaterialDraft> materials;
  final ValueChanged<List<_PlanMaterialDraft>> onChanged;

  const _PlanMaterialsEditor({
    required this.materials,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(allInventoryItemsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'مواد و قطعات موردنیاز',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        itemsAsync.when(
          data: (items) {
            final itemById = {for (final item in items) item.id: item};
            if (materials.isEmpty) {
              return const Text('هنوز کالایی به این برنامه اضافه نشده است.');
            }
            return Column(
              children: [
                for (final entry in materials.indexed)
                  Card(
                    child: ListTile(
                      title: Text(
                        itemById[entry.$2.itemId]?.name ?? 'کالای حذف‌شده',
                      ),
                      subtitle: Text(
                        '${AppNumberFormat.decimal(entry.$2.plannedQuantity)} '
                        '${itemById[entry.$2.itemId]?.unit ?? ''}'
                        '${entry.$2.notes == null ? '' : '\n${entry.$2.notes}'}',
                      ),
                      isThreeLine: entry.$2.notes != null,
                      onTap: () =>
                          _editMaterial(context, items, entry.$1, entry.$2),
                      trailing: IconButton(
                        tooltip: 'حذف قلم',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          final updated = [...materials]..removeAt(entry.$1);
                          onChanged(updated);
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('خطا در دریافت کالاهای انبار: $error'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: itemsAsync.asData == null
              ? null
              : () => _addMaterial(context, itemsAsync.asData!.value),
          icon: const Icon(Icons.add),
          label: const Text('افزودن کالا'),
        ),
      ],
    );
  }

  Future<void> _addMaterial(
    BuildContext context,
    List<InventoryItem> items,
  ) async {
    final available = items
        .where(
          (item) =>
              item.isActive &&
              !materials.any((material) => material.itemId == item.id),
        )
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کالای فعال دیگری برای افزودن وجود ندارد.'),
        ),
      );
      return;
    }
    final draft = await showDialog<_PlanMaterialDraft>(
      context: context,
      builder: (context) => _MaterialDraftDialog(items: available),
    );
    if (draft != null) onChanged([...materials, draft]);
  }

  Future<void> _editMaterial(
    BuildContext context,
    List<InventoryItem> items,
    int index,
    _PlanMaterialDraft current,
  ) async {
    final draft = await showDialog<_PlanMaterialDraft>(
      context: context,
      builder: (context) => _MaterialDraftDialog(
        items: items,
        initial: current,
        allowItemSelection: false,
      ),
    );
    if (draft != null) {
      final updated = [...materials]..[index] = draft;
      onChanged(updated);
    }
  }
}

class _MaterialDraftDialog extends StatefulWidget {
  final List<InventoryItem> items;
  final _PlanMaterialDraft? initial;
  final bool allowItemSelection;

  const _MaterialDraftDialog({
    required this.items,
    this.initial,
    this.allowItemSelection = true,
  });

  @override
  State<_MaterialDraftDialog> createState() => _MaterialDraftDialogState();
}

class _MaterialDraftDialogState extends State<_MaterialDraftDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  String? _itemId;

  @override
  void initState() {
    super.initState();
    _itemId = widget.initial?.itemId;
    _quantityController = TextEditingController(
      text: widget.initial?.plannedQuantity.toString() ?? '1',
    );
    _notesController = TextEditingController(text: widget.initial?.notes ?? '');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'افزودن کالا' : 'ویرایش کالا'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.allowItemSelection)
              DropdownButtonFormField<String>(
                initialValue: _itemId,
                decoration: const InputDecoration(labelText: 'کالا *'),
                items: widget.items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} (${item.unit})'),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    value == null ? 'کالا را انتخاب کنید.' : null,
                onChanged: (value) => setState(() => _itemId = value),
              ),
            if (!widget.allowItemSelection)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    widget.items
                            .where((item) => item.id == widget.initial?.itemId)
                            .firstOrNull
                            ?.name ??
                        'کالای مرتبط',
                  ),
                ),
              ),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'مقدار *'),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                return parsed == null || !parsed.isFinite || parsed <= 0
                    ? 'مقدار باید بزرگ‌تر از صفر باشد.'
                    : null;
              },
            ),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'توضیحات'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _PlanMaterialDraft(
                itemId: _itemId!,
                plannedQuantity: double.parse(_quantityController.text.trim()),
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
              ),
            );
          },
          child: const Text('ذخیره'),
        ),
      ],
    );
  }
}
