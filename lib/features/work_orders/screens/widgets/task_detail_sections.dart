import 'dart:convert';

import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../../inventory/providers/inventory_providers.dart';
import '../../providers/work_order_providers.dart';

Future<String?> askForTaskReason(
  BuildContext context, {
  required String title,
  required String actionLabel,
}) {
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

class TaskHistorySection extends ConsumerWidget {
  final String taskId;

  const TaskHistorySection({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(workOrderTaskEventsProvider(taskId));
    final itemsAsync = ref.watch(inventoryItemsProvider);
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return itemsAsync.when(
          data: (items) {
            final itemNames = {for (final item in items) item.id: item.name};
            return ExpansionTile(
              tilePadding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
              collapsedShape: const RoundedRectangleBorder(),
              title: const Text('تاریخچه تکمیل و اصلاح'),
              childrenPadding: const EdgeInsetsDirectional.only(start: 12),
              children: events.map((event) {
                final eventType = event['event_type'] as String? ?? '';
                final label = switch (eventType) {
                  'COMPLETED' => 'تکمیل وظیفه',
                  'REOPENED' => 'بازگشایی وظیفه',
                  'COMPLETION_CORRECTED' => 'اصلاح اطلاعات تکمیل',
                  _ => 'رویداد وظیفه',
                };
                final reason = event['reason'] as String?;
                final createdAt = event['created_at'] as String?;
                return ListTile(
                  dense: true,
                  title: Text(label),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          if (createdAt != null)
                            AppDateUtils.formatJalali(
                              createdAt,
                              includeTime: true,
                            ),
                          if (reason != null && reason.isNotEmpty)
                            'دلیل: $reason',
                        ].join(' · '),
                      ),
                      if (eventType == 'COMPLETION_CORRECTED') ...[
                        if (event['before_json'] is String)
                          Text(
                            'پیش از اصلاح: ${_taskSnapshotSummary(event['before_json'] as String, itemNames)}',
                          ),
                        if (event['after_json'] is String)
                          Text(
                            'پس از اصلاح: ${_taskSnapshotSummary(event['after_json'] as String, itemNames)}',
                          ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) =>
              Text('بارگذاری اطلاعات کالاها ناموفق بود: $error'),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('بارگذاری تاریخچه ناموفق بود: $error'),
    );
  }
}

String _taskSnapshotSummary(String json, Map<String, String> itemNames) {
  final decoded = jsonDecode(json) as Map<String, dynamic>;
  final task = decoded['task'] as Map<String, dynamic>?;
  if (task == null) return 'اطلاعات ثبت نشده';
  final materials = decoded['materials'] as List<dynamic>? ?? const [];
  final materialSummary = materials
      .map((entry) {
        final material = entry as Map<String, dynamic>;
        final itemId = material['item_id'] as String? ?? '';
        final itemName = itemNames[itemId] ?? 'ماده';
        return '$itemName: ${AppNumberFormat.decimal((material['actual_quantity'] as num?) ?? 0)}';
      })
      .join('، ');
  return [
    if (task['result'] != null) 'نتیجه ${task['result']}',
    'کار ${AppNumberFormat.decimal((task['labor_minutes'] as num?) ?? 0)} دقیقه',
    'توقف ${AppNumberFormat.decimal((task['downtime_minutes'] as num?) ?? 0)} دقیقه',
    if (task['findings'] != null && (task['findings'] as String).isNotEmpty)
      'یافته ${task['findings']}',
    'مصرف [$materialSummary]',
  ].join(' · ');
}

class TaskMaterialsSection extends ConsumerWidget {
  final String taskId;

  const TaskMaterialsSection({super.key, required this.taskId});

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
                  const SizedBox(height: 8),
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
                                  '$itemName · برنامه‌ریزی: ${_formatQuantity(material.plannedQuantity)} $unit · مصرف واقعی: ${_formatQuantity(material.actualQuantity)} $unit',
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
}

String _formatQuantity(double? quantity) {
  if (quantity == null) return '—';
  return AppNumberFormat.decimal(quantity);
}
