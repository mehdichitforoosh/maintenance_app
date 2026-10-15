import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../models/asset_reading.dart';

class AssetReadingTrendChart extends StatefulWidget {
  final List<AssetReading> readings;

  const AssetReadingTrendChart({super.key, required this.readings});

  @override
  State<AssetReadingTrendChart> createState() => _AssetReadingTrendChartState();
}

class _AssetReadingTrendChartState extends State<AssetReadingTrendChart> {
  String? _selectedSeriesKey;

  @override
  Widget build(BuildContext context) {
    final series = _buildSeries();
    if (series.isEmpty) return const SizedBox.shrink();

    final selectedKey = series.any((item) => item.key == _selectedSeriesKey)
        ? _selectedSeriesKey!
        : series.first.key;
    final selectedSeries = series.firstWhere((item) => item.key == selectedKey);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'روند خوانش‌ها',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedKey,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'شاخص و واحد',
                isDense: true,
              ),
              items: series
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.key,
                      child: Text(
                        '${_metricName(item.metricName)} (${item.unit})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedSeriesKey = value);
              },
            ),
            const SizedBox(height: 12),
            if (selectedSeries.points.length == 1)
              _SingleReadingSummary(point: selectedSeries.points.single)
            else
              SizedBox(
                height: 220,
                child: _ReadingLineChart(series: selectedSeries),
              ),
          ],
        ),
      ),
    );
  }

  List<_ReadingSeries> _buildSeries() {
    final activeReadings = widget.readings.where(
      (reading) => reading.supersededByReadingId == null,
    );
    final grouped = <String, List<AssetReading>>{};

    for (final reading in activeReadings) {
      final key = '${reading.metricName}\u0000${reading.unit}';
      grouped.putIfAbsent(key, () => []).add(reading);
    }

    return grouped.entries
        .map((entry) {
          final readings = entry.value
            ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
          final validReadings = readings
              .where((reading) => DateTime.tryParse(reading.recordedAt) != null)
              .toList();
          return _ReadingSeries(
            key: entry.key,
            metricName: validReadings.firstOrNull?.metricName ?? '',
            unit: validReadings.firstOrNull?.unit ?? '',
            points: validReadings
                .map((reading) => _ReadingPoint(reading: reading))
                .toList(),
          );
        })
        .where((series) => series.points.isNotEmpty)
        .toList();
  }

  String _metricName(String metric) {
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
  final _ReadingSeries series;

  const _ReadingLineChart({required this.series});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final values = series.points.map((point) => point.reading.value);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final padding = range == 0
        ? (maxValue.abs() * 0.1).clamp(1.0, 10.0)
        : range * 0.15;
    final spots = series.points
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.reading.value))
        .toList();

    return LineChart(
      LineChartData(
        minX: -0.5,
        maxX: series.points.length - 0.5,
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
              if (spot.spotIndex < 0 ||
                  spot.spotIndex >= series.points.length) {
                return null;
              }
              final reading = series.points[spot.spotIndex].reading;
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
              show: true,
              color: colors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _titles(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final interval = ((series.points.length - 1) / 3).ceilToDouble();
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
                index >= series.points.length ||
                (index % labelInterval != 0 &&
                    index != series.points.length - 1)) {
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
                    series.points[index].reading.recordedAt,
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

class _SingleReadingSummary extends StatelessWidget {
  final _ReadingPoint point;

  const _SingleReadingSummary({required this.point});

  @override
  Widget build(BuildContext context) {
    final reading = point.reading;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${reading.value} ${reading.unit}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            AppDateUtils.formatDisplay(reading.recordedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ReadingSeries {
  final String key;
  final String metricName;
  final String unit;
  final List<_ReadingPoint> points;

  const _ReadingSeries({
    required this.key,
    required this.metricName,
    required this.unit,
    required this.points,
  });
}

class _ReadingPoint {
  final AssetReading reading;

  const _ReadingPoint({required this.reading});
}
