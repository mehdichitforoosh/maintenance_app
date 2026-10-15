import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../work_orders/models/work_order_task.dart';

class AssetWorkOrderCharts extends StatelessWidget {
  final List<WorkOrderTask> tasks;

  const AssetWorkOrderCharts({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _TaskStatusChart(tasks: tasks),
        if (_hasTimeData) ...[
          const SizedBox(height: 8),
          _TaskTimeChart(tasks: tasks),
        ],
      ],
    );
  }

  bool get _hasTimeData => tasks.any(
    (task) => (task.laborMinutes ?? 0) > 0 || (task.downtimeMinutes ?? 0) > 0,
  );
}

class _TaskStatusChart extends StatefulWidget {
  final List<WorkOrderTask> tasks;

  const _TaskStatusChart({required this.tasks});

  @override
  State<_TaskStatusChart> createState() => _TaskStatusChartState();
}

class _TaskStatusChartState extends State<_TaskStatusChart> {
  TaskStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final status in TaskStatus.values)
        status: widget.tasks.where((task) => task.status == status).length,
    }..removeWhere((_, count) => count == 0);
    final statuses = counts.keys.toList();
    final colors = Theme.of(context).colorScheme;
    final selectedStatus = counts.containsKey(_selectedStatus)
        ? _selectedStatus
        : null;
    final sectionColors = {
      TaskStatus.pending: colors.tertiary,
      TaskStatus.inProgress: colors.primary,
      TaskStatus.completed: Colors.green,
      TaskStatus.skipped: colors.onSurfaceVariant,
      TaskStatus.cancelled: colors.error,
    };

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وضعیت وظایف تجهیز',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 38,
                        sectionsSpace: 3,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions) return;
                            final index =
                                response?.touchedSection?.touchedSectionIndex;
                            setState(() {
                              _selectedStatus =
                                  index != null &&
                                      index >= 0 &&
                                      index < statuses.length
                                  ? statuses[index]
                                  : null;
                            });
                          },
                        ),
                        sections: [
                          for (final status in statuses)
                            PieChartSectionData(
                              value: counts[status]!.toDouble(),
                              color: sectionColors[status],
                              radius: selectedStatus == status ? 24 : 20,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: selectedStatus == null
                          ? Text(
                              '${widget.tasks.length}\nوظیفه',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedStatus.displayName,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: sectionColors[selectedStatus],
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '${counts[selectedStatus]} وظیفه',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final status in statuses)
                  _LegendItem(
                    label: status.displayName,
                    color: sectionColors[status]!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTimeChart extends StatelessWidget {
  final List<WorkOrderTask> tasks;

  const _TaskTimeChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final laborHours = tasks.fold<int>(
      0,
      (total, task) => total + (task.laborMinutes ?? 0),
    );
    final downtimeHours = tasks.fold<int>(
      0,
      (total, task) => total + (task.downtimeMinutes ?? 0),
    );
    final colors = Theme.of(context).colorScheme;
    final maxValue = [
      laborHours,
      downtimeHours,
    ].reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'زمان ثبت‌شده',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'مجموع زمان کار و توقف تجهیزات',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  maxY: maxValue == 0 ? 1 : maxValue * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = group.x == 0 ? 'زمان کار' : 'زمان توقف';
                        return BarTooltipItem(
                          '$label\n${_formatDuration(rod.toY.toInt())}',
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
                          final title = switch (value.toInt()) {
                            0 => 'زمان کار',
                            1 => 'زمان توقف',
                            _ => '',
                          };
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              title,
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
                    _barGroup(0, laborHours.toDouble(), colors.primary),
                    _barGroup(1, downtimeHours.toDouble(), colors.error),
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
          width: 34,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '$remainingMinutes دقیقه';
    if (remainingMinutes == 0) return '$hours ساعت';
    return '$hours ساعت و $remainingMinutes دقیقه';
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

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
