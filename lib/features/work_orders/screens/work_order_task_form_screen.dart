import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_form_body.dart';
import '../../../core/widgets/app_form_submit_button.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/utils/validators.dart';
import '../../assets/providers/asset_providers.dart';
import '../../facilities/providers/facility_providers.dart';
import '../../maintenance/models/maintenance_plan.dart';
import '../../maintenance/providers/maintenance_providers.dart';
import '../providers/work_order_providers.dart';

class WorkOrderTaskFormScreen extends ConsumerStatefulWidget {
  final String workOrderId;

  const WorkOrderTaskFormScreen({super.key, required this.workOrderId});

  @override
  ConsumerState<WorkOrderTaskFormScreen> createState() =>
      _WorkOrderTaskFormScreenState();
}

class _WorkOrderTaskFormScreenState
    extends ConsumerState<WorkOrderTaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descController = TextEditingController();
  final _dueDateController = TextEditingController();

  String? _selectedAssetId;
  String? _selectedMaintenancePlanId;
  ActivityType _activityType = ActivityType.inspection;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    _descController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final initialDate =
        AppDateUtils.parseDateOnlyAsJalali(_dueDateController.text) ??
        Jalali.now();
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: Jalali(1300, 1),
      lastDate: Jalali(1450, 12),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _dueDateController.text = AppDateUtils.formatDateOnlyAsJalali(
          formatted,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate() || _selectedAssetId == null) {
      if (_selectedAssetId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفاً تجهیز مرتبط با وظیفه را انتخاب کنید.'),
          ),
        );
      }
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(workOrderActionsProvider)
          .addTask(
            workOrderId: widget.workOrderId,
            assetId: _selectedAssetId!,
            maintenancePlanId: _selectedMaintenancePlanId,
            title: _titleController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            activityType: _activityType,
            plannedDueAt: AppDateUtils.jalaliDateToIsoDate(
              _dueDateController.text,
            ),
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
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'افزودن وظیفه جدید به دستورکار',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: facilityAsync.when(
        data: (facility) {
          if (facility == null) {
            return const Center(
              child: Text('ابتدا اطلاعات کارگاه را ثبت کنید.'),
            );
          }
          final assetsAsync = ref.watch(assetsProvider(facility.id));
          final plansAsync = ref.watch(allFacilityPlansProvider(facility.id));
          return assetsAsync.when(
            data: (assets) {
              if (assets.isEmpty) {
                return const Center(
                  child: Text('ابتدا باید تجهیزی در سیستم ثبت کنید.'),
                );
              }
              _selectedAssetId ??= assets.first.id;
              return AppFormBody(
                formKey: _formKey,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedAssetId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'تجهیز هدف *',
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
                      onChanged: (value) {
                        setState(() {
                          _selectedAssetId = value;
                          _selectedMaintenancePlanId = null;
                          _activityType = ActivityType.inspection;
                          _titleController.clear();
                          _descController.clear();
                          _dueDateController.clear();
                        });
                      },
                    ),
                  ),
                  plansAsync.when(
                    data: (plans) => _buildTitleAutocomplete(plans),
                    loading: () =>
                        _buildTitleAutocomplete(const [], isLoading: true),
                    error: (_, _) => _buildTitleAutocomplete(
                      const [],
                      failedToLoad: true,
                      onRetry: () {
                        ref.invalidate(allFacilityPlansProvider(facility.id));
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ActivityType>(
                    initialValue: _activityType,
                    decoration: const InputDecoration(
                      labelText: 'نوع فعالیت',
                      prefixIcon: Icon(EneftyIcons.setting_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: ActivityType.values
                        .map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(
                      () => _activityType = v ?? ActivityType.inspection,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dueDateController,
                    readOnly: true,
                    onTap: _selectDueDate,
                    decoration: const InputDecoration(
                      labelText: 'تاریخ سررسید برنامه (شمسی)',
                      prefixIcon: Icon(EneftyIcons.calendar_2_outline),
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
                  AppFormSubmitButton(
                    isSubmitting: _isSubmitting,
                    onPressed: _save,
                    label: 'افزودن وظیفه به دستورکار',
                  ),
                ],
              );
            },
            loading: () => const AppLoading(),
            error: (error, _) => AppErrorState(
              message: 'بارگذاری تجهیزات ناموفق بود: $error',
              onRetry: () => ref.invalidate(assetsProvider(facility.id)),
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorState(
          message: 'بارگذاری اطلاعات کارگاه ناموفق بود: $error',
          onRetry: () => ref.invalidate(primaryFacilityProvider),
        ),
      ),
    );
  }

  Widget _buildTitleAutocomplete(
    List<MaintenancePlan> plans, {
    bool isLoading = false,
    bool failedToLoad = false,
    VoidCallback? onRetry,
  }) {
    final assetPlans = plans
        .where((plan) => plan.assetId == _selectedAssetId)
        .toList();
    return Autocomplete<MaintenancePlan>(
      textEditingController: _titleController,
      focusNode: _titleFocusNode,
      displayStringForOption: (plan) => plan.title,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        return assetPlans.where(
          (plan) => query.isEmpty || plan.title.toLowerCase().contains(query),
        );
      },
      onSelected: (plan) {
        setState(() {
          _selectedMaintenancePlanId = plan.id;
          _selectedAssetId = plan.assetId;
          _activityType = plan.activityType;
          _titleController.text = plan.title;
          _descController.text = plan.description ?? '';
          final plannedDate = switch (plan.scheduleType) {
            ScheduleType.calendar => plan.nextDueAt ?? plan.startDate,
            ScheduleType.oneTime => plan.oneTimeDueAt,
            _ => null,
          };
          _dueDateController.text = plannedDate == null
              ? ''
              : AppDateUtils.formatDateOnlyAsJalali(plannedDate);
        });
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: textController,
              focusNode: focusNode,
              onChanged: (value) {
                final selectedPlan = assetPlans
                    .where((plan) => plan.id == _selectedMaintenancePlanId)
                    .firstOrNull;
                if (selectedPlan != null && selectedPlan.title != value) {
                  setState(() => _selectedMaintenancePlanId = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'عنوان وظیفه *',
                helperText: failedToLoad
                    ? 'برنامه‌ها بارگذاری نشدند؛ عنوان را می‌توانید دستی وارد کنید.'
                    : assetPlans.isEmpty
                    ? 'برای این تجهیز برنامه‌ای نیست؛ عنوان را دستی وارد کنید.'
                    : 'عنوان برنامه را جست‌وجو و انتخاب کنید تا وظیفه به آن پیوند بخورد.',
                prefixIcon: const Icon(EneftyIcons.task_outline),
                border: const OutlineInputBorder(),
                suffixIcon: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              validator: (value) =>
                  AppValidators.required(value, fieldName: 'عنوان وظیفه'),
              onFieldSubmitted: (_) => onFieldSubmitted(),
            ),
            if (onRetry != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text(
                    'بارگذاری برنامه‌ها ناموفق بود؛ تلاش دوباره',
                  ),
                ),
              ),
          ],
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: options
                  .map(
                    (plan) => ListTile(
                      dense: true,
                      leading: const Icon(EneftyIcons.task_bold),
                      title: Text(
                        plan.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(plan.activityType.displayName),
                      onTap: () => onSelected(plan),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
