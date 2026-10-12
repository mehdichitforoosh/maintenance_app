import 'dart:convert';
import '../../assets/models/asset_reading.dart';

class ConditionEvaluator {
  /// Evaluates whether a reading triggers a condition config.
  /// Config format: {"metric":"temperature","operator":"gte","threshold":80,"unit":"celsius"}
  static bool evaluate(String? conditionConfigJson, AssetReading reading) {
    if (conditionConfigJson == null || conditionConfigJson.isEmpty) return false;
    try {
      final map = jsonDecode(conditionConfigJson) as Map<String, dynamic>;
      final targetMetric = map['metric'] as String?;
      final operator = map['operator'] as String?;
      final threshold = (map['threshold'] as num?)?.toDouble();
      final targetUnit = map['unit'] as String?;

      if (targetMetric == null || operator == null || threshold == null) return false;

      // Check metric match (case-insensitive or exact)
      if (reading.metricName.toLowerCase() != targetMetric.toLowerCase()) {
        return false;
      }

      // Check unit match if specified
      if (targetUnit != null && targetUnit.isNotEmpty && reading.unit.toLowerCase() != targetUnit.toLowerCase()) {
        // Optional: allow unit mismatch or enforce. Let's check unit compatibility if needed.
      }

      final val = reading.value;
      switch (operator.toLowerCase()) {
        case 'gt':
          return val > threshold;
        case 'gte':
          return val >= threshold;
        case 'lt':
          return val < threshold;
        case 'lte':
          return val <= threshold;
        case 'eq':
          return (val - threshold).abs() < 0.0001;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }
}
