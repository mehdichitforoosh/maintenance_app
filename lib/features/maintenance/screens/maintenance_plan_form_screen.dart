import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/validators.dart';
import '../../assets/providers/asset_providers.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/maintenance_plan.dart';
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
  ConsumerState<MaintenancePlanFormScreen> createState() => _MaintenancePlanFormScreenState();
}

class _MaintenancePlanFormScreenState extends ConsumerState<MaintenancePlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _intervalController = TextEditingController(text: '30');
  String? _selectedAssetId;
  ActivityType _activityType = ActivityType.inspection;
  Priority _priority = Priority.medium;
  ScheduleType _scheduleType = ScheduleType.calendar;
  CalendarUnit _calendarUnit = CalendarUnit.day;
  bool _isLoading = false;
  MaintenancePlan? _existingPlan;

  @override
  void initState() {
    super.initState();
    _selectedAssetId = widget.assetId.isNotEmpty ? widget.assetId : null;
    if (widget.planId != null) {
      _loadPlan();
    }
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(maintenancePlanRepositoryProvider);
      final plan = await repo.getPlanById(widget.planId!);
      if (plan != null && mounted) {
        _existingPlan = plan;
        _selectedAssetId = plan.assetId;
        _titleController.text = plan.title;
        _descController.text = plan.description ?? '';
        _activityType = plan.activityType;
        _priority = plan.priority;
        _scheduleType = plan.scheduleType;
        if (plan.calendarIntervalValue != null) {
          _intervalController.text = plan.calendarIntervalValue.toString();
        }
        if (plan.calendarIntervalUnit != null) {
          _calendarUnit = plan.calendarIntervalUnit!;
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedAssetId == null) {
      if (_selectedAssetId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً تجهیز موردنظر را انتخاب کنید.')),
        );
      }
      return;
    }
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(maintenancePlanRepositoryProvider);

      if (_existingPlan != null) {
        final updated = _existingPlan!.copyWith(
          assetId: _selectedAssetId!,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          activityType: _activityType,
          priority: _priority,
          scheduleType: _scheduleType,
          calendarIntervalValue: _scheduleType == ScheduleType.calendar ? int.parse(_intervalController.text.trim()) : null,
          calendarIntervalUnit: _scheduleType == ScheduleType.calendar ? _calendarUnit : null,
        );
        await repo.updatePlan(updated);
      } else {
        await repo.createPlan(
          assetId: _selectedAssetId!,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          activityType: _activityType,
          priority: _priority,
          scheduleType: _scheduleType,
          calendarIntervalValue: _scheduleType == ScheduleType.calendar ? int.parse(_intervalController.text.trim()) : null,
          calendarIntervalUnit: _scheduleType == ScheduleType.calendar ? _calendarUnit : null,
        );
      }

      final facility = await ref.read(primaryFacilityProvider.future);
      if (facility != null) {
        ref.invalidate(allFacilityPlansProvider(facility.id));
      }
      ref.invalidate(maintenancePlansProvider(_selectedAssetId!));
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
    final isEditing = widget.planId != null;
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش برنامه PM' : 'تعریف برنامه نگهداری جدید (PM)', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Asset Selection if not editing or when needed
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
                            labelText: 'انتخاب تجهیز *',
                            prefixIcon: Icon(EneftyIcons.cpu_bold),
                            border: OutlineInputBorder(),
                          ),
                          items: assets.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.code})'))).toList(),
                          onChanged: (v) => setState(() => _selectedAssetId = v),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('خطا در دریافت تجهیزات: $e'),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان برنامه *',
                  prefixIcon: Icon(EneftyIcons.calendar_2_bold),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => AppValidators.required(v, fieldName: 'عنوان برنامه'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivityType>(
                initialValue: _activityType,
                decoration: const InputDecoration(
                  labelText: 'نوع فعالیت',
                  prefixIcon: Icon(EneftyIcons.task_bold),
                  border: OutlineInputBorder(),
                ),
                items: ActivityType.values.map((a) => DropdownMenuItem(value: a, child: Text(a.displayName))).toList(),
                onChanged: (v) => setState(() => _activityType = v ?? ActivityType.inspection),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Priority>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'اولویت',
                  prefixIcon: Icon(EneftyIcons.danger_bold),
                  border: OutlineInputBorder(),
                ),
                items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
                onChanged: (v) => setState(() => _priority = v ?? Priority.medium),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ScheduleType>(
                initialValue: _scheduleType,
                decoration: const InputDecoration(
                  labelText: 'نوع زمان‌بندی',
                  prefixIcon: Icon(EneftyIcons.clock_bold),
                  border: OutlineInputBorder(),
                ),
                items: ScheduleType.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                onChanged: (v) => setState(() => _scheduleType = v ?? ScheduleType.calendar),
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
                          prefixIcon: Icon(EneftyIcons.timer_bold),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => AppValidators.positiveNumber(v, fieldName: 'فاصله زمانی'),
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
                        items: CalendarUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.displayName))).toList(),
                        onChanged: (v) => setState(() => _calendarUnit = v ?? CalendarUnit.day),
                      ),
                    ),
                  ],
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
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: Icon(isEditing ? EneftyIcons.edit_2_bold : EneftyIcons.add_bold),
                onPressed: _isLoading ? null : _save,
                label: Text(isEditing ? 'بروزرسانی برنامه PM' : 'ذخیره برنامه PM'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
