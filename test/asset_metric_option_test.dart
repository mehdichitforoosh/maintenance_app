import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/features/assets/models/asset_metric_option.dart';
import 'package:maintenance_app/features/assets/models/asset_reading.dart';

void main() {
  test('builds unique metric/unit options from the latest valid readings', () {
    AssetReading reading({
      required String id,
      required String metric,
      required String unit,
      required double value,
      required String recordedAt,
      String? supersededByReadingId,
      String? deletedAt,
    }) {
      return AssetReading(
        id: id,
        assetId: 'asset-1',
        metricName: metric,
        value: value,
        unit: unit,
        recordedAt: recordedAt,
        createdAt: recordedAt,
        updatedAt: recordedAt,
        supersededByReadingId: supersededByReadingId,
        deletedAt: deletedAt,
      );
    }

    final options = AssetMetricOption.fromReadings([
      reading(
        id: 'old-hours',
        metric: 'operating_hours',
        unit: 'h',
        value: 100,
        recordedAt: '2026-10-25T10:00:00Z',
      ),
      reading(
        id: 'latest-hours',
        metric: 'OPERATING_HOURS',
        unit: 'H',
        value: 120,
        recordedAt: '2026-10-26T10:00:00Z',
      ),
      reading(
        id: 'other-unit',
        metric: 'operating_hours',
        unit: 'cycles',
        value: 20,
        recordedAt: '2026-10-26T11:00:00Z',
      ),
      reading(
        id: 'corrected-old',
        metric: 'temperature',
        unit: '°C',
        value: 75,
        recordedAt: '2026-10-26T12:00:00Z',
        supersededByReadingId: 'corrected-new',
      ),
      reading(
        id: 'deleted',
        metric: 'pressure',
        unit: 'bar',
        value: 3,
        recordedAt: '2026-10-26T13:00:00Z',
        deletedAt: '2026-10-26T14:00:00Z',
      ),
    ]);

    expect(options, hasLength(2));
    expect(options.first.metricName, 'OPERATING_HOURS');
    expect(options.first.unit, 'H');
    expect(options.first.latestValue, 120);
    expect(options.last.unit, 'cycles');
  });
}
