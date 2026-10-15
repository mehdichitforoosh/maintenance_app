import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../providers/work_order_providers.dart';
import 'widgets/work_order_summary_card.dart';
import 'widgets/work_order_tasks_section.dart';

class WorkOrderDetailScreen extends ConsumerWidget {
  final String workOrderId;

  const WorkOrderDetailScreen({super.key, required this.workOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workOrderAsync = ref.watch(workOrderDetailProvider(workOrderId));
    final tasksAsync = ref.watch(workOrderTasksProvider(workOrderId));

    return workOrderAsync.when(
      data: (workOrder) {
        if (workOrder == null) {
          return const Scaffold(body: Center(child: Text('دستورکار یافت نشد')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'دستورکار ${workOrder.workOrderNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              PopupMenuButton<WorkOrderStatus>(
                icon: const Icon(EneftyIcons.setting_4_outline),
                tooltip: 'تغییر وضعیت دستورکار',
                onSelected: (newStatus) async {
                  try {
                    final repository = ref.read(workOrderRepositoryProvider);
                    if (newStatus == WorkOrderStatus.completed) {
                      await repository.closeWorkOrder(workOrderId);
                    } else {
                      await repository.updateWorkOrderStatus(
                        workOrderId,
                        newStatus,
                      );
                    }
                    ref.invalidate(workOrderDetailProvider(workOrderId));
                    ref.invalidate(workOrdersProvider(workOrder.facilityId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('وضعیت دستورکار بروز شد.'),
                        ),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('خطا: $error')));
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
              WorkOrderSummaryCard(workOrder: workOrder),
              const SizedBox(height: 24),
              WorkOrderTasksSection(
                workOrderId: workOrderId,
                facilityId: workOrder.facilityId,
                tasksAsync: tasksAsync,
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (error, _) =>
          Scaffold(body: AppErrorState(message: error.toString())),
    );
  }
}
