import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../work_orders/models/work_order_task.dart';

class MaintenancePlanReport extends StatelessWidget {
  final List<WorkOrderTask> tasks;

  const MaintenancePlanReport({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'گزارش اجرا'),
          Text(
            'پس از ثبت وظایف، آمار و نمودارهای اجرا در این بخش نمایش داده می‌شود.',
          ),
        ],
      );
    }

    final completed = tasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    final open = tasks
        .where(
          (task) =>
              task.status == TaskStatus.pending ||
              task.status == TaskStatus.inProgress,
        )
        .length;
    final needsAttention = tasks
        .where(
          (task) =>
              task.result == TaskResult.issueFound ||
              task.result == TaskResult.failed ||
              task.result == TaskResult.followUpRequired,
        )
        .length;
    final labor = tasks.fold<int>(
      0,
      (total, task) => total + (task.laborMinutes ?? 0),
    );
    final downtime = tasks.fold<int>(
      0,
      (total, task) => total + (task.downtimeMinutes ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'گزارش اجرا'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ReportMetric(label: 'کل وظایف', value: tasks.length),
            _ReportMetric(label: 'تکمیل‌شده', value: completed),
            _ReportMetric(label: 'باز', value: open),
            _ReportMetric(label: 'نیازمند رسیدگی', value: needsAttention),
          ],
        ),
        const SizedBox(height: 8),
        _TaskStatusChart(tasks: tasks),
        if (labor > 0 || downtime > 0) ...[
          const SizedBox(height: 8),
          _TaskEffortChart(laborMinutes: labor, downtimeMinutes: downtime),
        ],
      ],
    );
  }
}

class _ReportMetric extends StatelessWidget {
  final String label;
  final int value;

  const _ReportMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 48) / 2,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppNumberFormat.decimal(value),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskStatusChart extends StatelessWidget {
  final List<WorkOrderTask> tasks;

  const _TaskStatusChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final status in TaskStatus.values)
        status: tasks.where((task) => task.status == status).length,
    }..removeWhere((_, count) => count == 0);
    final colors = Theme.of(context).colorScheme;
    final statusColors = {
      TaskStatus.pending: colors.tertiary,
      TaskStatus.inProgress: colors.primary,
      TaskStatus.completed: Colors.green,
      TaskStatus.skipped: colors.onSurfaceVariant,
      TaskStatus.cancelled: colors.error,
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وضعیت وظایف این برنامه',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 170,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 32,
                        sectionsSpace: 2,
                        sections: [
                          for (final entry in counts.entries)
                            PieChartSectionData(
                              value: entry.value.toDouble(),
                              color: statusColors[entry.key],
                              radius: 22,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in counts.entries)
                          _ChartLegend(
                            label:
                                '${entry.key.displayName} (${AppNumberFormat.decimal(entry.value)})',
                            color: statusColors[entry.key]!,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskEffortChart extends StatelessWidget {
  final int laborMinutes;
  final int downtimeMinutes;

  const _TaskEffortChart({
    required this.laborMinutes,
    required this.downtimeMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maximum = laborMinutes > downtimeMinutes
        ? laborMinutes
        : downtimeMinutes;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'زمان کار و توقف ثبت‌شده',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: (maximum * 1.2).ceilToDouble().clamp(
                    1,
                    double.infinity,
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = group.x == 0 ? 'زمان کار' : 'زمان توقف';
                        return BarTooltipItem(
                          '$label\n${AppNumberFormat.decimal(rod.toY.toInt())} دقیقه',
                          TextStyle(
                            color: colors.onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colors.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final label = switch (value.toInt()) {
                            0 => 'زمان کار',
                            1 => 'زمان توقف',
                            _ => '',
                          };
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    _barGroup(0, laborMinutes.toDouble(), colors.primary),
                    _barGroup(1, downtimeMinutes.toDouble(), colors.error),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 30,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final String label;
  final Color color;

  const _ChartLegend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
