import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../assets/models/asset.dart';
import '../../../maintenance/models/maintenance_plan.dart';
import '../../../maintenance/models/maintenance_plan_material.dart';
import '../../../work_orders/models/work_order_task.dart';

class MaintenancePlanSummary extends StatelessWidget {
  final MaintenancePlan plan;

  const MaintenancePlanSummary({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  backgroundColor: plan.isActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.errorContainer,
                  labelStyle: TextStyle(
                    color: plan.isActive
                        ? Colors.green
                        : Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  label: Text(plan.isActive ? 'فعال' : 'غیرفعال'),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(label: 'نوع فعالیت', value: plan.activityType.displayName),
            _InfoRow(
              label: 'اولویت',
              value: plan.priority.displayName,
              valueColor: AppColors.priorityColor(plan.priority),
            ),
            _InfoRow(label: 'زمان‌بندی', value: plan.scheduleType.displayName),
            if (plan.scheduleType == ScheduleType.calendar &&
                plan.calendarIntervalValue != null &&
                plan.calendarIntervalUnit != null)
              _InfoRow(
                label: 'تناوب اجرا',
                value:
                    'هر ${AppNumberFormat.decimal(plan.calendarIntervalValue!)} ${plan.calendarIntervalUnit!.displayName}',
              ),
            if (plan.scheduleType == ScheduleType.meter) ...[
              if (plan.meterName != null)
                _InfoRow(label: 'شاخص کارکرد', value: plan.meterName!),
              if (plan.meterInterval != null && plan.meterUnit != null)
                _InfoRow(
                  label: 'تناوب کارکرد',
                  value:
                      'هر ${AppNumberFormat.decimal(plan.meterInterval!)} ${plan.meterUnit}',
                ),
              if (plan.nextDueMeterValue != null && plan.meterUnit != null)
                _InfoRow(
                  label: 'هدف بعدی',
                  value:
                      '${AppNumberFormat.decimal(plan.nextDueMeterValue!)} ${plan.meterUnit}',
                ),
              if (plan.lastCompletedMeterValue != null &&
                  plan.meterUnit != null)
                _InfoRow(
                  label: 'آخرین کارکرد تکمیل',
                  value:
                      '${AppNumberFormat.decimal(plan.lastCompletedMeterValue!)} ${plan.meterUnit}',
                ),
            ],
            if (_hasText(plan.nextDueAt))
              _InfoRow(
                label: 'سررسید بعدی',
                value: AppDateUtils.formatDisplay(
                  plan.nextDueAt,
                  includeTime: false,
                ),
              ),
            if (_hasText(plan.oneTimeDueAt))
              _InfoRow(
                label: 'تاریخ اجرای برنامه',
                value: AppDateUtils.formatDisplay(
                  plan.oneTimeDueAt,
                  includeTime: false,
                ),
              ),
            if (_hasText(plan.lastCompletedAt))
              _InfoRow(
                label: 'آخرین تکمیل',
                value: AppDateUtils.formatDisplay(plan.lastCompletedAt),
              ),
            if (_hasText(plan.description)) ...[
              const Divider(height: 24),
              Text(
                plan.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static bool _hasText(String? value) => value != null && value.isNotEmpty;
}

class MaintenancePlanAssetCard extends StatelessWidget {
  final Asset? asset;

  const MaintenancePlanAssetCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: const Icon(EneftyIcons.cpu_outline),
        ),
        title: Text(asset?.name ?? 'تجهیز مرتبط در دسترس نیست'),
        subtitle: Text(asset == null ? '' : 'کد تجهیز: ${asset!.code}'),
        onTap: asset == null
            ? null
            : () => context.push('/assets/${asset!.id}'),
      ),
    );
  }
}

class MaintenancePlanMaterialsSection extends StatelessWidget {
  final List<MaintenancePlanMaterial> materials;
  final Map<String, String> itemNames;
  final Map<String, String> itemUnits;

  const MaintenancePlanMaterialsSection({
    super.key,
    required this.materials,
    required this.itemNames,
    required this.itemUnits,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'اقلام پیش‌بینی‌شده'),
        if (materials.isEmpty)
          const Text('برای این برنامه قلم مصرفی تعریف نشده است.')
        else
          ...materials.map(
            (material) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                child: const Icon(EneftyIcons.box_outline),
              ),
              title: Text(itemNames[material.itemId] ?? 'کالای حذف‌شده'),
              subtitle: material.notes == null || material.notes!.isEmpty
                  ? null
                  : Text(material.notes!),
              trailing: Text(
                '${AppNumberFormat.decimal(material.plannedQuantity)} '
                        '${itemUnits[material.itemId] ?? ''}'
                    .trim(),
              ),
            ),
          ),
      ],
    );
  }
}

class MaintenancePlanTaskHistory extends StatelessWidget {
  final List<WorkOrderTask> tasks;

  const MaintenancePlanTaskHistory({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'سوابق اجرای برنامه'),
        if (tasks.isEmpty)
          const Text('هنوز برای این برنامه وظیفه‌ای ثبت نشده است.')
        else
          ...tasks.map(
            (task) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusBackgroundColor(context, task.status),
                  foregroundColor: _statusColor(context, task.status),
                  child: Icon(_statusIcon(task.status)),
                ),
                title: Text(task.title),
                subtitle: Text(_taskSubtitle(task)),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.push('/work-orders/${task.workOrderId}'),
              ),
            ),
          ),
      ],
    );
  }

  String _taskSubtitle(WorkOrderTask task) {
    final date = task.completedAt ?? task.plannedDueAt ?? task.createdAt;
    final details = <String>[task.status.displayName];
    if (task.result != null) details.add(task.result!.displayName);
    if (task.laborMinutes != null) {
      details.add('کار: ${AppNumberFormat.decimal(task.laborMinutes!)} دقیقه');
    }
    if (task.downtimeMinutes != null) {
      details.add(
        'توقف: ${AppNumberFormat.decimal(task.downtimeMinutes!)} دقیقه',
      );
    }
    if (task.plannedMeterValue != null) {
      details.add(
        'هدف کارکرد: ${AppNumberFormat.decimal(task.plannedMeterValue!)} '
                '${task.completionMeterUnit ?? ''}'
            .trim(),
      );
    }
    if (task.completionMeterValue != null) {
      details.add(
        'خوانش تکمیل: ${AppNumberFormat.decimal(task.completionMeterValue!)} '
                '${task.completionMeterUnit ?? ''}'
            .trim(),
      );
    }
    return '${AppDateUtils.formatDisplay(date)}\n${details.join(' • ')}';
  }

  IconData _statusIcon(TaskStatus status) => switch (status) {
    TaskStatus.pending => Icons.schedule,
    TaskStatus.inProgress => Icons.play_circle_outline,
    TaskStatus.completed => Icons.check_circle_outline,
    TaskStatus.skipped => Icons.skip_next,
    TaskStatus.cancelled => Icons.cancel_outlined,
  };

  Color _statusColor(BuildContext context, TaskStatus status) =>
      switch (status) {
        TaskStatus.pending => Theme.of(context).colorScheme.tertiary,
        TaskStatus.inProgress => Theme.of(context).colorScheme.primary,
        TaskStatus.completed => Colors.green,
        TaskStatus.skipped => Theme.of(context).colorScheme.onSurfaceVariant,
        TaskStatus.cancelled => Theme.of(context).colorScheme.error,
      };

  Color _statusBackgroundColor(BuildContext context, TaskStatus status) =>
      switch (status) {
        TaskStatus.pending => Theme.of(context).colorScheme.tertiaryContainer,
        TaskStatus.inProgress => Theme.of(context).colorScheme.primaryContainer,
        TaskStatus.completed => Colors.green.shade100,
        TaskStatus.skipped => Theme.of(context).colorScheme.surfaceContainerHighest,
        TaskStatus.cancelled => Theme.of(context).colorScheme.errorContainer,
      };
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
