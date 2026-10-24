import 'dart:convert';
import '../../assets/models/asset_reading.dart';

class ConditionEvaluator {
  /// Evaluates a reading against a condition using the same canonical unit.
  static bool evaluate(String? conditionConfigJson, AssetReading reading) {
    if (conditionConfigJson == null || conditionConfigJson.isEmpty) {
      return false;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(conditionConfigJson);
    } on FormatException {
      return false;
    }

    if (decoded is! Map<String, dynamic>) return false;
    final targetMetric = decoded['metric'];
    final operator = decoded['operator'];
    final thresholdValue = decoded['threshold'];
    final targetUnit = decoded['unit'];
    if (targetMetric is! String ||
        targetMetric.trim().isEmpty ||
        operator is! String ||
        thresholdValue is! num ||
        !thresholdValue.isFinite ||
        targetUnit is! String ||
        targetUnit.trim().isEmpty ||
        !reading.value.isFinite) {
      return false;
    }

    if (reading.metricName.trim().toLowerCase() !=
            targetMetric.trim().toLowerCase() ||
        _normalizeUnit(reading.unit) != _normalizeUnit(targetUnit)) {
      return false;
    }

    final threshold = thresholdValue.toDouble();
    switch (operator) {
      case 'gt':
        return reading.value > threshold;
      case 'gte':
        return reading.value >= threshold;
      case 'lt':
        return reading.value < threshold;
      case 'lte':
        return reading.value <= threshold;
      case 'eq':
        return (reading.value - threshold).abs() < 0.0001;
      default:
        return false;
    }
  }

  static String _normalizeUnit(String unit) {
    final normalized = unit.trim().toLowerCase().replaceAll(' ', '');
    return switch (normalized) {
      'celsius' || '°c' => 'c',
      'fahrenheit' || '°f' => 'f',
      _ => normalized,
    };
  }
}
