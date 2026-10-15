import 'dart:convert';

import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/section_header.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../providers/work_order_providers.dart';

class WorkOrderDetailScreen extends ConsumerWidget {
  final String workOrderId;

  const WorkOrderDetailScreen({super.key, required this.workOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final woAsync = ref.watch(workOrderDetailProvider(workOrderId));
    final tasksAsync = ref.watch(workOrderTasksProvider(workOrderId));

    return woAsync.when(
      data: (wo) {
        if (wo == null) {
          return const Scaffold(body: Center(child: Text('دستورکار یافت نشد')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'دستورکار ${wo.workOrderNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              PopupMenuButton<WorkOrderStatus>(
                icon: const Icon(EneftyIcons.setting_4_outline),
                tooltip: 'تغییر وضعیت دستورکار',
                onSelected: (newStatus) async {
                  try {
                    final repo = ref.read(workOrderRepositoryProvider);
                    if (newStatus == WorkOrderStatus.completed) {
                      await repo.closeWorkOrder(workOrderId);
                    } else {
                      await repo.updateWorkOrderStatus(workOrderId, newStatus);
                    }
                    ref.invalidate(workOrderDetailProvider(workOrderId));
                    ref.invalidate(workOrdersProvider(wo.facilityId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('وضعیت دستورکار بروز شد.'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('خطا: $e')));
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: WorkOrderStatus.open,
                    child: Text('باز (Open)'),
                  ),
                  const PopupMenuItem(
                    value: WorkOrderStatus.inProgress,
                    child: Text('در جریان (In Progress)'),
                  ),
                  const PopupMenuItem(
                    value: WorkOrderStatus.onHold,
                    child: Text('معوق / تعلیق (On Hold)'),
                  ),
                  const PopupMenuItem(
                    value: WorkOrderStatus.completed,
                    child: Text('تکمیل / بسته شده (Completed)'),
                  ),
                  const PopupMenuItem(
                    value: WorkOrderStatus.cancelled,
                    child: Text('لغو شده (Cancelled)'),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(EneftyIcons.edit_2_outline),
                tooltip: 'ویرایش دستورکار',
                onPressed: () => context.push('/work-orders/$workOrderId/edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              wo.title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              wo.status.displayName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _infoRow('نوع دستورکار', wo.workOrderType.displayName),
                      _infoRow('اولویت', wo.priority.displayName),
                      if (wo.scheduledAt != null)
                        _infoRow('زمان‌بندی', wo.scheduledAt!),
                      if (wo.description != null && wo.description!.isNotEmpty)
                        _infoRow('توضیحات', wo.description!),
                      if (wo.notes != null && wo.notes!.isNotEmpty)
                        _infoRow('یادداشت‌ها', wo.notes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(title: 'وظایف و فعالیت‌ها (Tasks)'),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(EneftyIcons.box_bold, size: 16),
                          label: const Text('افزودن متریال'),
                          onPressed: () => context.push(
                            '/work-orders/$workOrderId/materials/new',
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(EneftyIcons.add_bold, size: 16),
                          label: const Text('افزودن وظیفه'),
                          onPressed: () => context.push(
                            '/work-orders/$workOrderId/tasks/new',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'وظیفه‌ای برای این دستورکار ثبت نشده است. از دکمه بالا برای افزودن وظیفه استفاده کنید.',
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: tasks
                        .map(
                          (t) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                              end: 12,
                                              top: 2,
                                            ),
                                        child: Icon(
                                          t.status == TaskStatus.completed
                                              ? EneftyIcons.tick_circle_bold
                                              : EneftyIcons.task_square_bold,
                                          color:
                                              t.status == TaskStatus.completed
                                              ? Colors.green
                                              : const Color(0xFF2563EB),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'وضعیت: ${t.status.displayName}${t.result != null ? ' | نتیجه: ${t.result!.displayName}' : ''}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (t.status == TaskStatus.pending ||
                                      t.status == TaskStatus.inProgress)
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: FilledButton.tonalIcon(
                                          icon: const Icon(
                                            EneftyIcons.tick_square_bold,
                                            size: 16,
                                          ),
                                          label: const Text('تکمیل وظیفه'),
                                          onPressed: () => context.push(
                                            '/work-orders/$workOrderId/tasks/${t.id}/complete',
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (t.status == TaskStatus.completed)
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          OutlinedButton.icon(
                                            icon: const Icon(
                                              EneftyIcons.edit_2_outline,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'اصلاح اطلاعات تکمیل',
                                            ),
                                            onPressed: () => context.push(
                                              '/work-orders/$workOrderId/tasks/${t.id}/correct',
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            icon: const Icon(
                                              EneftyIcons.refresh_outline,
                                              size: 16,
                                            ),
                                            label: const Text('بازگشایی وظیفه'),
                                            onPressed: () async {
                                              final reason =
                                                  await _askForTaskReason(
                                                    context,
                                                    title: 'بازگشایی وظیفه',
                                                    actionLabel: 'بازگشایی',
                                                  );
                                              if (reason == null ||
                                                  !context.mounted) {
                                                return;
                                              }
                                              try {
                                                await ref
                                                    .read(
                                                      workOrderRepositoryProvider,
                                                    )
                                                    .reopenCompletedTask(
                                                      taskId: t.id,
                                                      reason: reason,
                                                    );
                                                ref.invalidate(
                                                  workOrderDetailProvider(
                                                    workOrderId,
                                                  ),
                                                );
                                                ref.invalidate(
                                                  workOrderTasksProvider(
                                                    workOrderId,
                                                  ),
                                                );
                                                ref.invalidate(
                                                  workOrderTaskEventsProvider(
                                                    t.id,
                                                  ),
                                                );
                                                ref.invalidate(
                                                  workOrdersProvider(
                                                    wo.facilityId,
                                                  ),
                                                );
                                                ref.invalidate(
                                                  dashboardSummaryProvider(
                                                    wo.facilityId,
                                                  ),
                                                );
                                                ref.invalidate(
                                                  dashboardCompletedTaskTrendProvider(
                                                    wo.facilityId,
                                                  ),
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'وظیفه بازگشایی شد؛ مصرف قبلی انبار حفظ شده است.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (error) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'بازگشایی ناموفق بود: $error',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (t.findings != null &&
                                      t.findings!.isNotEmpty) ...[
                                    const Divider(height: 12),
                                    Text(
                                      'یافته‌ها و گزارش: ${t.findings}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                  _TaskMaterialsSection(taskId: t.id),
                                  _TaskHistorySection(taskId: t.id),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const AppLoading(),
                error: (e, _) => Text('خطا: $e'),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _askForTaskReason(
  BuildContext context, {
  required String title,
  required String actionLabel,
}) async {
  return showDialog<String>(
    context: context,
    builder: (_) => _TaskReasonDialog(title: title, actionLabel: actionLabel),
  );
}

class _TaskReasonDialog extends StatefulWidget {
  final String title;
  final String actionLabel;

  const _TaskReasonDialog({required this.title, required this.actionLabel});

  @override
  State<_TaskReasonDialog> createState() => _TaskReasonDialogState();
}

class _TaskReasonDialogState extends State<_TaskReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'دلیل *',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'وارد کردن دلیل الزامی است.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _TaskHistorySection extends ConsumerWidget {
  final String taskId;

  const _TaskHistorySection({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(workOrderTaskEventsProvider(taskId));
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('تاریخچه تکمیل و اصلاح'),
          children: events.map((event) {
            final eventType = event['event_type'] as String? ?? '';
            final label = switch (eventType) {
              'COMPLETED' => 'تکمیل وظیفه',
              'REOPENED' => 'بازگشایی وظیفه',
              'COMPLETION_CORRECTED' => 'اصلاح اطلاعات تکمیل',
              _ => 'رویداد وظیفه',
            };
            final reason = event['reason'] as String?;
            return ListTile(
              dense: true,
              title: Text(label),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (event['created_at'] != null)
                        event['created_at'] as String,
                      if (reason != null && reason.isNotEmpty) 'دلیل: $reason',
                    ].join(' · '),
                  ),
                  if (eventType == 'COMPLETION_CORRECTED') ...[
                    if (event['before_json'] is String)
                      Text(
                        'پیش از اصلاح: ${_taskSnapshotSummary(event['before_json'] as String)}',
                      ),
                    if (event['after_json'] is String)
                      Text(
                        'پس از اصلاح: ${_taskSnapshotSummary(event['after_json'] as String)}',
                      ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('بارگذاری تاریخچه ناموفق بود: $error'),
    );
  }
}

String _taskSnapshotSummary(String json) {
  final decoded = jsonDecode(json) as Map<String, dynamic>;
  final task = decoded['task'] as Map<String, dynamic>?;
  if (task == null) return 'اطلاعات ثبت نشده';
  final materials = decoded['materials'] as List<dynamic>? ?? const [];
  final materialSummary = materials
      .map((entry) {
        final material = entry as Map<String, dynamic>;
        return '${material['item_id']}: ${material['actual_quantity'] ?? 0}';
      })
      .join('، ');
  return [
    if (task['result'] != null) 'نتیجه ${task['result']}',
    'کار ${task['labor_minutes'] ?? 0} دقیقه',
    'توقف ${task['downtime_minutes'] ?? 0} دقیقه',
    if (task['findings'] != null && (task['findings'] as String).isNotEmpty)
      'یافته ${task['findings']}',
    'مصرف [$materialSummary]',
  ].join(' · ');
}

class _TaskMaterialsSection extends ConsumerWidget {
  final String taskId;

  const _TaskMaterialsSection({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(workOrderMaterialsProvider(taskId));
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return materialsAsync.when(
      data: (materials) {
        if (materials.isEmpty) return const SizedBox.shrink();
        return itemsAsync.when(
          data: (items) {
            final itemById = {for (final item in items) item.id: item};
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16),
                  Text(
                    'قطعات و متریال',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...materials.map((material) {
                    final item = itemById[material.itemId];
                    final itemName = item?.name ?? 'کالای غیرفعال یا حذف‌شده';
                    final unit = item?.unit ?? '';
                    final planned = material.plannedQuantity;
                    final actual = material.actualQuantity;
                    final cost = material.unitCostAtUse;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(EneftyIcons.box_bold, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$itemName · برنامه‌ریزی: ${_formatQuantity(planned)} $unit · مصرف واقعی: ${_formatQuantity(actual)} $unit',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (cost != null ||
                                    material.notes?.isNotEmpty == true)
                                  Text(
                                    [
                                      if (cost != null)
                                        'بهای واحد: ${_formatQuantity(cost)} تومان',
                                      if (material.notes?.isNotEmpty == true)
                                        material.notes!,
                                    ].join(' · '),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('بارگذاری نام کالاها ناموفق بود: $error'),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Text('بارگذاری متریال وظیفه ناموفق بود: $error'),
    );
  }

  String _formatQuantity(double? quantity) {
    if (quantity == null) return '—';
    return quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toString();
  }
}
