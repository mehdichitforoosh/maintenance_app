import 'asset_reading.dart';

class AssetMetricOption {
  final String metricName;
  final String unit;
  final double latestValue;

  const AssetMetricOption({
    required this.metricName,
    required this.unit,
    required this.latestValue,
  });

  String get key =>
      '${metricName.trim().toLowerCase()}\u0000'
      '${unit.trim().toLowerCase()}';

  static List<AssetMetricOption> fromReadings(List<AssetReading> readings) {
    final latestByMetric = <String, AssetReading>{};
    for (final reading in readings) {
      if (reading.deletedAt != null || reading.supersededByReadingId != null) {
        continue;
      }

      final key =
          '${reading.metricName.trim().toLowerCase()}\u0000'
          '${reading.unit.trim().toLowerCase()}';
      final current = latestByMetric[key];
      final recordedAt = DateTime.tryParse(reading.recordedAt);
      final currentRecordedAt = current == null
          ? null
          : DateTime.tryParse(current.recordedAt);
      if (current == null ||
          (recordedAt != null &&
              (currentRecordedAt == null ||
                  recordedAt.isAfter(currentRecordedAt)))) {
        latestByMetric[key] = reading;
      }
    }

    return latestByMetric.values
        .map(
          (reading) => AssetMetricOption(
            metricName: reading.metricName,
            unit: reading.unit,
            latestValue: reading.value,
          ),
        )
        .toList()
      ..sort((a, b) {
        final metricComparison = a.metricName.compareTo(b.metricName);
        return metricComparison != 0
            ? metricComparison
            : a.unit.compareTo(b.unit);
      });
  }
}
