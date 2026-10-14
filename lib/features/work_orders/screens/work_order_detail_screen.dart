import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/section_header.dart';
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
        if (wo == null) return const Scaffold(body: Center(child: Text('دستورکار یافت نشد')));

        return Scaffold(
          appBar: AppBar(
            title: Text('دستورکار ${wo.workOrderNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وضعیت دستورکار بروز شد.')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: WorkOrderStatus.open, child: Text('باز (Open)')),
                  const PopupMenuItem(value: WorkOrderStatus.inProgress, child: Text('در جریان (In Progress)')),
                  const PopupMenuItem(value: WorkOrderStatus.onHold, child: Text('معوق / تعلیق (On Hold)')),
                  const PopupMenuItem(value: WorkOrderStatus.completed, child: Text('تکمیل / بسته شده (Completed)')),
                  const PopupMenuItem(value: WorkOrderStatus.cancelled, child: Text('لغو شده (Cancelled)')),
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
                            child: Text(wo.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(wo.status.displayName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _infoRow('نوع دستورکار', wo.workOrderType.displayName),
                      _infoRow('اولویت', wo.priority.displayName),
                      if (wo.scheduledAt != null) _infoRow('زمان‌بندی', wo.scheduledAt!),
                      if (wo.description != null && wo.description!.isNotEmpty) _infoRow('توضیحات', wo.description!),
                      if (wo.notes != null && wo.notes!.isNotEmpty) _infoRow('یادداشت‌ها', wo.notes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionHeader(title: 'وظایف و فعالیت‌ها (Tasks)'),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(EneftyIcons.box_bold, size: 16),
                        label: const Text('افزودن متریال'),
                        onPressed: () => context.push('/work-orders/$workOrderId/materials/new'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(EneftyIcons.add_bold, size: 16),
                        label: const Text('افزودن وظیفه'),
                        onPressed: () => context.push('/work-orders/$workOrderId/tasks/new'),
                      ),
                    ],
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
                        child: Text('وظیفه‌ای برای این دستورکار ثبت نشده است. از دکمه بالا برای افزودن وظیفه استفاده کنید.'),
                      ),
                    );
                  }
                  return Column(
                    children: tasks.map((t) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                t.status == TaskStatus.completed ? EneftyIcons.tick_circle_bold : EneftyIcons.task_square_bold,
                                color: t.status == TaskStatus.completed ? Colors.green : const Color(0xFF2563EB),
                              ),
                              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('وضعیت: ${t.status.displayName}${t.result != null ? ' | نتیجه: ${t.result!.displayName}' : ''}'),
                              trailing: t.status != TaskStatus.completed
                                  ? FilledButton.tonalIcon(
                                      icon: const Icon(EneftyIcons.tick_square_bold, size: 16),
                                      label: const Text('تکمیل وظیفه'),
                                      onPressed: () => context.push('/work-orders/$workOrderId/tasks/${t.id}/complete'),
                                    )
                                  : const Icon(EneftyIcons.tick_circle_bold, color: Colors.green),
                            ),
                            if (t.findings != null && t.findings!.isNotEmpty) ...[
                              const Divider(height: 12),
                              Text('یافته‌ها و گزارش: ${t.findings}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ],
                        ),
                      ),
                    )).toList(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
