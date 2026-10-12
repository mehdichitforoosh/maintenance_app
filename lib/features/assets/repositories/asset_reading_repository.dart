import '../../../core/storage/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../../maintenance/services/condition_evaluator.dart';
import '../models/asset_reading.dart';

class AssetReadingRepository {
  final DatabaseHelper _dbHelper;

  AssetReadingRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<AssetReading>> getReadings(String assetId, {String? metricName}) async {
    final db = await _dbHelper.db;
    var where = 'asset_id = ? AND deleted_at IS NULL';
    var args = <dynamic>[assetId];

    if (metricName != null && metricName.isNotEmpty) {
      where += ' AND metric_name = ?';
      args.add(metricName);
    }

    final results = await db.query(
      'asset_readings',
      where: where,
      whereArgs: args,
      orderBy: 'recorded_at DESC',
    );
    return results.map((m) => AssetReading.fromMap(m)).toList();
  }

  Future<AssetReading?> getLatestReading(String assetId, String metricName) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'asset_readings',
      where: 'asset_id = ? AND metric_name = ? AND deleted_at IS NULL',
      whereArgs: [assetId, metricName],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return AssetReading.fromMap(results.first);
  }

  Future<AssetReading> recordReading({
    required String assetId,
    required String metricName,
    required double value,
    required String unit,
    String? recordedAt,
    String? notes,
  }) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();
    final recTime = recordedAt ?? nowIso;
    final id = IdGenerator.generate();

    final reading = AssetReading(
      id: id,
      assetId: assetId,
      metricName: metricName,
      value: value,
      unit: unit,
      recordedAt: recTime,
      notes: notes,
      createdAt: nowIso,
      updatedAt: nowIso,
    );

    await db.transaction((txn) async {
      await txn.insert('asset_readings', reading.toMap());

      // Check condition-based maintenance plans for this asset
      final assetMap = await txn.query('assets', where: 'id = ?', whereArgs: [assetId], limit: 1);
      if (assetMap.isNotEmpty) {
        final facilityId = assetMap.first['facility_id'] as String;
        final plans = await txn.query(
          'maintenance_plans',
          where: 'asset_id = ? AND schedule_type = ? AND is_active = 1 AND deleted_at IS NULL',
          whereArgs: [assetId, 'CONDITION'],
        );

        for (final planMap in plans) {
          final configJson = planMap['condition_config_json'] as String?;
          if (ConditionEvaluator.evaluate(configJson, reading)) {
            // Trigger condition maintenance task
            final planId = planMap['id'] as String;
            final occurrenceKey = 'condition:${reading.id}';
            
            // Check if task exists
            final existing = await txn.query(
              'work_order_tasks',
              where: 'maintenance_plan_id = ? AND source_occurrence_key = ? AND deleted_at IS NULL',
              whereArgs: [planId, occurrenceKey],
            );

            if (existing.isEmpty) {
              // Create PM work order task for condition trigger
              // Find or create open work order
              var woId = '';
              final wos = await txn.query(
                'work_orders',
                where: 'facility_id = ? AND status = ? AND work_order_type = ? AND deleted_at IS NULL',
                whereArgs: [facilityId, 'OPEN', 'CORRECTIVE'],
                limit: 1,
              );
              if (wos.isNotEmpty) {
                woId = wos.first['id'] as String;
              } else {
                woId = IdGenerator.generate();
                final woNum = 'WO-CM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                await txn.insert('work_orders', {
                  'id': woId,
                  'facility_id': facilityId,
                  'work_order_number': woNum,
                  'title': 'دستورکار اضطراری سنسور/شرط',
                  'work_order_type': 'CORRECTIVE',
                  'priority': 'HIGH',
                  'status': 'OPEN',
                  'created_at': nowIso,
                  'updated_at': nowIso,
                  'sync_status': 'pending',
                });
              }

              await txn.insert('work_order_tasks', {
                'id': IdGenerator.generate(),
                'work_order_id': woId,
                'asset_id': assetId,
                'maintenance_plan_id': planId,
                'title': 'رفع شرط بحرانی: ${planMap['title']}',
                'description': 'خوانش بحرانی با مقدار ${reading.value} ${reading.unit} ثبت شد.',
                'activity_type': planMap['activity_type'],
                'status': 'PENDING',
                'triggering_reading_id': reading.id,
                'source_occurrence_key': occurrenceKey,
                'created_at': nowIso,
                'updated_at': nowIso,
                'sync_status': 'pending',
              });
            }
          }
        }
      }
    });

    return reading;
  }
}
