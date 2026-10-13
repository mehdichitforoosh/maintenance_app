import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/asset_reading_table.dart';
import '../../../core/storage/database/tables/asset_table.dart';
import '../../../core/storage/database/tables/maintenance_plan_table.dart';
import '../../../core/storage/database/tables/work_order_table.dart';
import '../../../core/storage/database/tables/work_order_task_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../../maintenance/services/condition_evaluator.dart';
import '../models/asset_reading.dart';

class AssetReadingRepository {
  static const String _tableName = AssetReadingTable.tableName;
  final DatabaseHelper _dbHelper;

  AssetReadingRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<AssetReading>> getReadings(String assetId, {String? metricName}) async {
    final db = await _dbHelper.db;
    var where = '${AssetReadingTable.assetId} = ? AND ${AssetReadingTable.deletedAt} IS NULL';
    var args = <dynamic>[assetId];

    if (metricName != null && metricName.isNotEmpty) {
      where += ' AND ${AssetReadingTable.metricName} = ?';
      args.add(metricName);
    }

    final results = await db.query(
      _tableName,
      where: where,
      whereArgs: args,
      orderBy: '${AssetReadingTable.recordedAt} DESC',
    );
    return results.map((m) => AssetReading.fromMap(m)).toList();
  }

  Future<AssetReading?> getLatestReading(String assetId, String metricName) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where: '${AssetReadingTable.assetId} = ? AND ${AssetReadingTable.metricName} = ? AND ${AssetReadingTable.deletedAt} IS NULL',
      whereArgs: [assetId, metricName],
      orderBy: '${AssetReadingTable.recordedAt} DESC',
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
      await txn.insert(_tableName, reading.toMap());

      // Check condition-based maintenance plans for this asset
      final assetMap = await txn.query(AssetTable.tableName, where: '${AssetTable.id} = ?', whereArgs: [assetId], limit: 1);
      if (assetMap.isNotEmpty) {
        final facilityId = assetMap.first[AssetTable.facilityId] as String;
        final plans = await txn.query(
          MaintenancePlanTable.tableName,
          where: '${MaintenancePlanTable.assetId} = ? AND ${MaintenancePlanTable.scheduleType} = ? AND ${MaintenancePlanTable.isActive} = 1 AND ${MaintenancePlanTable.deletedAt} IS NULL',
          whereArgs: [assetId, 'CONDITION'],
        );

        for (final planMap in plans) {
          final configJson = planMap[MaintenancePlanTable.conditionConfigJson] as String?;
          if (ConditionEvaluator.evaluate(configJson, reading)) {
            // Trigger condition maintenance task
            final planId = planMap[MaintenancePlanTable.id] as String;
            final occurrenceKey = 'condition:${reading.id}';

            // Check if task exists
            final existing = await txn.query(
              WorkOrderTaskTable.tableName,
              where: '${WorkOrderTaskTable.maintenancePlanId} = ? AND ${WorkOrderTaskTable.sourceOccurrenceKey} = ? AND ${WorkOrderTaskTable.deletedAt} IS NULL',
              whereArgs: [planId, occurrenceKey],
            );

            if (existing.isEmpty) {
              // Create PM work order task for condition trigger
              // Find or create open work order
              var woId = '';
              final wos = await txn.query(
                WorkOrderTable.tableName,
                where: '${WorkOrderTable.facilityId} = ? AND ${WorkOrderTable.status} = ? AND ${WorkOrderTable.workOrderType} = ? AND ${WorkOrderTable.deletedAt} IS NULL',
                whereArgs: [facilityId, 'OPEN', 'CORRECTIVE'],
                limit: 1,
              );
              if (wos.isNotEmpty) {
                woId = wos.first[WorkOrderTable.id] as String;
              } else {
                woId = IdGenerator.generate();
                final woNum = 'WO-CM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                await txn.insert(WorkOrderTable.tableName, {
                  WorkOrderTable.id: woId,
                  WorkOrderTable.facilityId: facilityId,
                  WorkOrderTable.workOrderNumber: woNum,
                  WorkOrderTable.title: 'دستورکار اضطراری سنسور/شرط',
                  WorkOrderTable.workOrderType: 'CORRECTIVE',
                  WorkOrderTable.priority: 'HIGH',
                  WorkOrderTable.status: 'OPEN',
                  WorkOrderTable.createdAt: nowIso,
                  WorkOrderTable.updatedAt: nowIso,
                  WorkOrderTable.syncStatus: 'pending',
                });
              }

              await txn.insert(WorkOrderTaskTable.tableName, {
                WorkOrderTaskTable.id: IdGenerator.generate(),
                WorkOrderTaskTable.workOrderId: woId,
                WorkOrderTaskTable.assetId: assetId,
                WorkOrderTaskTable.maintenancePlanId: planId,
                WorkOrderTaskTable.title: 'رفع شرط بحرانی: ${planMap[MaintenancePlanTable.title]}',
                WorkOrderTaskTable.description: 'خوانش بحرانی با مقدار ${reading.value} ${reading.unit} ثبت شد.',
                WorkOrderTaskTable.activityType: planMap[MaintenancePlanTable.activityType],
                WorkOrderTaskTable.status: 'PENDING',
                WorkOrderTaskTable.triggeringReadingId: reading.id,
                WorkOrderTaskTable.sourceOccurrenceKey: occurrenceKey,
                WorkOrderTaskTable.createdAt: nowIso,
                WorkOrderTaskTable.updatedAt: nowIso,
                WorkOrderTaskTable.syncStatus: 'pending',
              });
            }
          }
        }
      }
    });

    return reading;
  }
}
