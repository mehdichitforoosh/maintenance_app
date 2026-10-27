import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../models/work_order.dart';

class WorkOrderSummaryCard extends StatelessWidget {
  final WorkOrder workOrder;

  const WorkOrderSummaryCard({super.key, required this.workOrder});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    workOrder.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    workOrder.status.displayName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _WorkOrderInfoRow(
              'نوع دستورکار',
              workOrder.workOrderType.displayName,
            ),
            _WorkOrderInfoRow('اولویت', workOrder.priority.displayName),
            if (workOrder.scheduledAt != null)
              _WorkOrderInfoRow(
                'زمان‌بندی',
                AppDateUtils.formatDateOnlyAsJalali(workOrder.scheduledAt),
              ),
            if (workOrder.description?.isNotEmpty == true)
              _WorkOrderInfoRow('توضیحات', workOrder.description!),
            if (workOrder.notes?.isNotEmpty == true)
              _WorkOrderInfoRow('یادداشت‌ها', workOrder.notes!),
          ],
        ),
      ),
    );
  }
}

class _WorkOrderInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _WorkOrderInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
