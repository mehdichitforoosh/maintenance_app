import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/number_format_utils.dart';

class ReportChartValue {
  final String label;
  final double value;

  const ReportChartValue(this.label, this.value);
}

class ReportBarChart extends StatelessWidget {
  final String title;
  final String valueLabel;
  final List<ReportChartValue> values;

  const ReportBarChart({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxValue = values.fold<double>(
      0,
      (current, entry) => entry.value > current ? entry.value : current,
    );
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            if (values.isEmpty || maxValue == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_chart_outlined,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'در این بازه داده‌ای برای نمودار ثبت نشده است.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 190,
                child: BarChart(
                  BarChartData(
                    maxY: maxValue * 1.2,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: colors.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          if (groupIndex < 0 || groupIndex >= values.length) {
                            return null;
                          }
                          return BarTooltipItem(
                            '${values[groupIndex].label}\n'
                            '${AppNumberFormat.decimal(rod.toY)} $valueLabel',
                            TextStyle(
                              color: colors.onInverseSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
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
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= values.length) {
                              return const SizedBox.shrink();
                            }
                            final step = (values.length / 6).ceil();
                            if (index % step != 0 &&
                                index != values.length - 1) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              space: 4,
                              child: Text(
                                values[index].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var index = 0; index < values.length; index++)
                        BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: values[index].value,
                              color: colors.primary,
                              width: values.length > 12 ? 9 : 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
