import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/features/assets/models/asset_reading.dart';
import 'package:maintenance_app/features/maintenance/services/condition_evaluator.dart';

void main() {
  final reading = AssetReading(
    id: 'reading-1',
    assetId: 'asset-1',
    metricName: 'temperature',
    value: 85,
    unit: '°C',
    recordedAt: '2026-10-21T10:00:00.000Z',
    createdAt: '2026-10-21T10:00:00.000Z',
    updatedAt: '2026-10-21T10:00:00.000Z',
  );

  test('matches the configured metric, operator, and equivalent unit labels', () {
    expect(
      ConditionEvaluator.evaluate(
        '{"metric":"temperature","operator":"gte","threshold":80,"unit":"celsius"}',
        reading,
      ),
      isTrue,
    );
  });

  test('does not compare values with incompatible units', () {
    expect(
      ConditionEvaluator.evaluate(
        '{"metric":"temperature","operator":"gte","threshold":80,"unit":"°F"}',
        reading,
      ),
      isFalse,
    );
  });

  test('returns false for malformed or incomplete condition configuration', () {
    expect(ConditionEvaluator.evaluate('{bad json', reading), isFalse);
    expect(
      ConditionEvaluator.evaluate(
        '{"metric":"temperature","operator":"gte","threshold":80}',
        reading,
      ),
      isFalse,
    );
  });
}
