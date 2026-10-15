import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/app_enums.dart';
import '../../models/work_order_task.dart';
import '../../providers/work_order_providers.dart';
import '../../../dashboard/providers/dashboard_providers.dart';
import 'task_detail_sections.dart';

class WorkOrderTaskCard extends ConsumerWidget {
  final WorkOrderTask task;
  final String workOrderId;
  final String facilityId;

  const WorkOrderTaskCard({
    super.key,
    required this.task,
    required this.workOrderId,
    required this.facilityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12, top: 2),
                  child: Icon(
                    task.status == TaskStatus.completed
                        ? EneftyIcons.tick_circle_bold
                        : EneftyIcons.task_square_bold,
                    color: task.status == TaskStatus.completed
                        ? Colors.green
                        : const Color(0xFF2563EB),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'وضعیت: ${task.status.displayName}${task.result != null ? ' | نتیجه: ${task.result!.displayName}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (task.status == TaskStatus.pending ||
                task.status == TaskStatus.inProgress)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.icon(
                    icon: const Icon(EneftyIcons.tick_square_bold, size: 16),
                    label: const Text('تکمیل وظیفه'),
                    onPressed: () => context.push(
                      '/work-orders/$workOrderId/tasks/${task.id}/complete',
                    ),
                  ),
                ),
              ),
            if (task.status == TaskStatus.completed)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(EneftyIcons.edit_2_outline, size: 16),
                      label: const Text('اصلاح اطلاعات تکمیل'),
                      onPressed: () => context.push(
                        '/work-orders/$workOrderId/tasks/${task.id}/correct',
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(EneftyIcons.refresh_outline, size: 16),
                      label: const Text('بازگشایی وظیفه'),
                      onPressed: () => _reopenTask(context, ref),
                    ),
                  ],
                ),
              ),
            if (task.findings?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                'یافته‌ها و گزارش: ${task.findings}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
            TaskMaterialsSection(taskId: task.id),
            TaskHistorySection(taskId: task.id),
          ],
        ),
      ),
    );
  }

  Future<void> _reopenTask(BuildContext context, WidgetRef ref) async {
    final reason = await askForTaskReason(
      context,
      title: 'بازگشایی وظیفه',
      actionLabel: 'بازگشایی',
    );
    if (reason == null || !context.mounted) return;

    try {
      await ref
          .read(workOrderRepositoryProvider)
          .reopenCompletedTask(taskId: task.id, reason: reason);
      ref.invalidate(workOrderDetailProvider(workOrderId));
      ref.invalidate(workOrderTasksProvider(workOrderId));
      ref.invalidate(workOrderTaskEventsProvider(task.id));
      ref.invalidate(workOrdersProvider(facilityId));
      ref.invalidate(dashboardSummaryProvider(facilityId));
      ref.invalidate(dashboardCompletedTaskTrendProvider(facilityId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('وظیفه بازگشایی شد؛ مصرف قبلی انبار حفظ شده است.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('بازگشایی ناموفق بود: $error')));
      }
    }
  }
}
