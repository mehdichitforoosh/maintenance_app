import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/section_header.dart';
import '../../models/work_order_task.dart';
import 'work_order_task_card.dart';

class WorkOrderTasksSection extends StatelessWidget {
  final String workOrderId;
  final String facilityId;
  final AsyncValue<List<WorkOrderTask>> tasksAsync;

  const WorkOrderTasksSection({
    super.key,
    required this.workOrderId,
    required this.facilityId,
    required this.tasksAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                onPressed: () =>
                    context.push('/work-orders/$workOrderId/materials/new'),
              ),
              OutlinedButton.icon(
                icon: const Icon(EneftyIcons.add_bold, size: 16),
                label: const Text('افزودن وظیفه'),
                onPressed: () =>
                    context.push('/work-orders/$workOrderId/tasks/new'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'وظیفه‌ای برای این دستورکار ثبت نشده است. از دکمه بالا برای افزودن وظیفه استفاده کنید.',
                  ),
                ),
              );
            }
            return Column(
              children: tasks
                  .map(
                    (task) => WorkOrderTaskCard(
                      task: task,
                      workOrderId: workOrderId,
                      facilityId: facilityId,
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const AppLoading(),
          error: (error, _) => Text('خطا: $error'),
        ),
      ],
    );
  }
}
