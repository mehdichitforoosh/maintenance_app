import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../models/asset_reading.dart';

class AssetReadingTrendChart extends StatelessWidget {
  final List<AssetReading> readings;

  const AssetReadingTrendChart({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    final points =
        readings
            .where(
              (reading) =>
                  reading.supersededByReadingId == null &&
                  DateTime.tryParse(reading.recordedAt) != null,
            )
            .map((reading) => _ReadingPoint(reading))
            .toList()
          ..sort(
            (a, b) => a.reading.recordedAt.compareTo(b.reading.recordedAt),
          );
    if (points.isEmpty) return const SizedBox.shrink();

    final first = points.first.reading;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'روند ${_metricName(first.metricName)} (${first.unit})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              points.length == 1
                  ? 'برای مشاهده تغییرات، خوانش دیگری از همین شاخص ثبت کنید.'
                  : 'برای دیدن تاریخ و مقدار، نقطه‌ای از نمودار را لمس کنید.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 250, child: _ReadingLineChart(points: points)),
          ],
        ),
      ),
    );
  }

  static String _metricName(String metric) {
    return switch (metric) {
      'operating_hours' => 'ساعت کارکرد',
      'temperature' => 'دما',
      'pressure' => 'فشار',
      'vibration' => 'لرزش',
      _ => metric.replaceAll('_', ' '),
    };
  }
}

class _ReadingLineChart extends StatelessWidget {
  final List<_ReadingPoint> points;

  const _ReadingLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final readings = points.map((point) => point.reading.value).toList();
    final minValue = readings.reduce((a, b) => a < b ? a : b);
    final maxValue = readings.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final padding = range == 0
        ? (maxValue.abs() * 0.1).clamp(1.0, 10.0)
        : range * 0.15;
    final spots = points
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.reading.value))
        .toList();

    return LineChart(
      LineChartData(
        minX: -0.5,
        maxX: points.length - 0.5,
        minY: minValue - padding,
        maxY: maxValue + padding,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.outlineVariant.withValues(alpha: 0.45),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              if (spot.spotIndex < 0 || spot.spotIndex >= points.length) {
                return null;
              }
              final reading = points[spot.spotIndex].reading;
              return LineTooltipItem(
                '${AppDateUtils.formatDisplay(reading.recordedAt)}\n'
                '${_formatValue(reading.value)} ${reading.unit}',
                TextStyle(
                  color: colors.onInverseSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: colors.primary,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: points.length > 1,
              color: colors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _titles(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final interval = ((points.length - 1) / 3).ceilToDouble();
    final labelInterval = interval < 1 ? 1 : interval.toInt();
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: labelInterval.toDouble(),
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if ((value - index).abs() > 0.01 ||
                index < 0 ||
                index >= points.length ||
                (index % labelInterval != 0 && index != points.length - 1)) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              space: 2,
              fitInside: SideTitleFitInsideData.fromTitleMeta(
                meta,
                distanceFromEdge: 2,
              ),
              child: SizedBox(
                width: 42,
                child: Text(
                  AppDateUtils.formatJalaliShort(
                    points[index].reading.recordedAt,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatValue(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}

class _ReadingPoint {
  final AssetReading reading;

  const _ReadingPoint(this.reading);
}
