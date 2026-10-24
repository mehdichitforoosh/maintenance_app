import 'package:sqflite/sqflite.dart';

import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/asset_reading_table.dart';
import '../../../core/storage/database/tables/asset_table.dart';
import '../../../core/storage/database/tables/alert_event_table.dart';
import '../../../core/storage/database/tables/maintenance_plan_table.dart';
import '../../../core/storage/database/tables/work_order_table.dart';
import '../../../core/storage/database/tables/work_order_task_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../../maintenance/services/condition_evaluator.dart';
import '../../maintenance/services/maintenance_plan_material_seeder.dart';
import '../models/asset_reading.dart';

class AssetReadingCorrectionResult {
  final AssetReading reading;
  final int generatedConditionTaskCount;
  final int openConditionTaskCount;
  final int previouslyTriggeredTaskCount;

  const AssetReadingCorrectionResult({
    required this.reading,
    required this.generatedConditionTaskCount,
    required this.openConditionTaskCount,
    required this.previouslyTriggeredTaskCount,
  });
}

class _ConditionTaskGenerationResult {
  final int generatedCount;
  final int openTaskCount;

  const _ConditionTaskGenerationResult(this.generatedCount, this.openTaskCount);
}

class AssetReadingRepository {
  static const String _tableName = AssetReadingTable.tableName;
  final DatabaseHelper _dbHelper;

  AssetReadingRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<AssetReading>> getReadings(
    String assetId, {
    String? metricName,
  }) async {
    final db = await _dbHelper.db;
    var where =
        '${AssetReadingTable.assetId} = ? AND ${AssetReadingTable.deletedAt} IS NULL';
    var args = <dynamic>[assetId];

    if (metricName != null && metricName.isNotEmpty) {
      where += ' AND ${AssetReadingTable.metricName} = ?';
      args.add(metricName);
    }

    final results = await db.query(
      _tableName,
      where: where,
      whereArgs: args,
      orderBy:
          '${AssetReadingTable.recordedAt} DESC, ${AssetReadingTable.createdAt} DESC, rowid DESC',
    );
    return results.map((m) => AssetReading.fromMap(m)).toList();
  }

  Future<AssetReading?> getLatestReading(
    String assetId,
    String metricName,
  ) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where:
          '${AssetReadingTable.assetId} = ? AND ${AssetReadingTable.metricName} = ? AND ${AssetReadingTable.deletedAt} IS NULL AND ${AssetReadingTable.supersededByReadingId} IS NULL',
      whereArgs: [assetId, metricName],
      orderBy:
          '${AssetReadingTable.recordedAt} DESC, ${AssetReadingTable.createdAt} DESC, rowid DESC',
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
    if (metricName.trim().isEmpty || unit.trim().isEmpty || !value.isFinite) {
      throw ArgumentError('شاخص، واحد و مقدار خوانش باید معتبر باشند.');
    }
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
      await _validateMeterProgression(txn, reading);
      await txn.insert(_tableName, reading.toMap());
      await _generateConditionTasks(txn, reading: reading, now: nowIso);
      await _generateMeterTasks(txn, reading: reading, now: nowIso);
    });

    return reading;
  }

  Future<void> _validateMeterProgression(
    Transaction txn,
    AssetReading reading,
  ) async {
    final meterPlans = await txn.query(
      MaintenancePlanTable.tableName,
      columns: [MaintenancePlanTable.meterName, MaintenancePlanTable.meterUnit],
      where:
          '${MaintenancePlanTable.assetId} = ? AND ${MaintenancePlanTable.scheduleType} = ? AND ${MaintenancePlanTable.isActive} = 1 AND ${MaintenancePlanTable.deletedAt} IS NULL',
      whereArgs: [reading.assetId, 'METER'],
    );
    final isMeter = meterPlans.any(
      (plan) =>
          (plan[MaintenancePlanTable.meterName] as String?)
                  ?.trim()
                  .toLowerCase() ==
              reading.metricName.trim().toLowerCase() &&
          (plan[MaintenancePlanTable.meterUnit] as String?)
                  ?.trim()
                  .toLowerCase() ==
              reading.unit.trim().toLowerCase(),
    );
    if (!isMeter) return;
    if (reading.value < 0) {
      throw ArgumentError('خوانش کنتور نمی‌تواند منفی باشد.');
    }

    final latest = await txn.query(
      _tableName,
      where:
          '${AssetReadingTable.assetId} = ? AND LOWER(${AssetReadingTable.metricName}) = LOWER(?) AND LOWER(${AssetReadingTable.unit}) = LOWER(?) AND ${AssetReadingTable.deletedAt} IS NULL AND ${AssetReadingTable.supersededByReadingId} IS NULL',
      whereArgs: [reading.assetId, reading.metricName, reading.unit],
      orderBy:
          '${AssetReadingTable.recordedAt} DESC, ${AssetReadingTable.createdAt} DESC, rowid DESC',
      limit: 1,
    );
    if (latest.isNotEmpty &&
        reading.value < (latest.single[AssetReadingTable.value] as num)) {
      throw StateError(
        'مقدار کنتور از آخرین خوانش کمتر است؛ برای بازنشانی کنتور از فرایند اصلاح استفاده کنید.',
      );
    }
    if (latest.isNotEmpty) {
      final latestRecordedAt = DateTime.tryParse(
        latest.single[AssetReadingTable.recordedAt] as String,
      );
      final currentRecordedAt = DateTime.tryParse(reading.recordedAt);
      if (latestRecordedAt != null &&
          currentRecordedAt != null &&
          currentRecordedAt.isBefore(latestRecordedAt)) {
        throw StateError(
          'تاریخ خوانش کنتور نمی‌تواند پیش از آخرین خوانش باشد.',
        );
      }
    }
  }

  Future<AssetReadingCorrectionResult> correctReading({
    required String readingId,
    required double value,
    required String unit,
    required String recordedAt,
    required String reason,
    String? notes,
  }) async {
    if (!value.isFinite || value <= 0) {
      throw StateError('مقدار خوانش باید بزرگ‌تر از صفر باشد.');
    }
    if (unit.trim().isEmpty || reason.trim().isEmpty) {
      throw StateError('واحد و دلیل اصلاح الزامی است.');
    }
    final parsedRecordedAt = DateTime.tryParse(recordedAt);
    if (parsedRecordedAt == null) {
      throw StateError('تاریخ و زمان خوانش معتبر نیست.');
    }
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    late AssetReading replacement;
    var generatedConditionTaskCount = 0;
    var openConditionTaskCount = 0;
    var previouslyTriggeredTaskCount = 0;

    await db.transaction((txn) async {
      final rows = await txn.query(
        _tableName,
        where:
            '${AssetReadingTable.id} = ? AND ${AssetReadingTable.deletedAt} IS NULL',
        whereArgs: [readingId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('خوانش موردنظر پیدا نشد.');
      }

      final original = AssetReading.fromMap(rows.single);
      if (original.supersededByReadingId != null) {
        throw StateError('این خوانش قبلاً اصلاح شده است.');
      }

      replacement = AssetReading(
        id: IdGenerator.generate(),
        assetId: original.assetId,
        metricName: original.metricName,
        value: value,
        unit: unit.trim(),
        recordedAt: parsedRecordedAt.toUtc().toIso8601String(),
        notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await txn.insert(_tableName, replacement.toMap());
      await txn.update(
        _tableName,
        {
          AssetReadingTable.supersededByReadingId: replacement.id,
          AssetReadingTable.correctionReason: reason.trim(),
          AssetReadingTable.updatedAt: now,
          AssetReadingTable.syncStatus: 'pending',
        },
        where: '${AssetReadingTable.id} = ?',
        whereArgs: [original.id],
      );

      final linkedTasks = await txn.query(
        WorkOrderTaskTable.tableName,
        columns: [WorkOrderTaskTable.id, WorkOrderTaskTable.maintenancePlanId],
        where:
            '${WorkOrderTaskTable.triggeringReadingId} = ? AND ${WorkOrderTaskTable.deletedAt} IS NULL',
        whereArgs: [original.id],
      );
      previouslyTriggeredTaskCount = linkedTasks.length;
      final alreadyTriggeredPlanIds = linkedTasks
          .map((task) => task[WorkOrderTaskTable.maintenancePlanId])
          .whereType<String>()
          .toSet();
      final conditionResult = await _generateConditionTasks(
        txn,
        reading: replacement,
        now: now,
        excludedPlanIds: alreadyTriggeredPlanIds,
      );
      generatedConditionTaskCount = conditionResult.generatedCount;
      openConditionTaskCount = conditionResult.openTaskCount;
      await _generateMeterTasks(
        txn,
        reading: replacement,
        now: now,
        excludedPlanIds: alreadyTriggeredPlanIds,
      );
    });

    return AssetReadingCorrectionResult(
      reading: replacement,
      generatedConditionTaskCount: generatedConditionTaskCount,
      openConditionTaskCount: openConditionTaskCount,
      previouslyTriggeredTaskCount: previouslyTriggeredTaskCount,
    );
  }

  Future<_ConditionTaskGenerationResult> _generateConditionTasks(
    Transaction txn, {
    required AssetReading reading,
    required String now,
    Set<String> excludedPlanIds = const {},
  }) async {
    final assetRows = await txn.query(
      AssetTable.tableName,
      where: '${AssetTable.id} = ? AND ${AssetTable.deletedAt} IS NULL',
      whereArgs: [reading.assetId],
      limit: 1,
    );
    if (assetRows.isEmpty) {
      return const _ConditionTaskGenerationResult(0, 0);
    }

    final facilityId = assetRows.single[AssetTable.facilityId] as String;
    final plans = await txn.query(
      MaintenancePlanTable.tableName,
      where:
          '${MaintenancePlanTable.assetId} = ? AND ${MaintenancePlanTable.scheduleType} = ? AND ${MaintenancePlanTable.isActive} = 1 AND ${MaintenancePlanTable.deletedAt} IS NULL',
      whereArgs: [reading.assetId, 'CONDITION'],
    );
    var generatedCount = 0;
    var openTaskCount = 0;

    for (final plan in plans) {
      final configJson =
          plan[MaintenancePlanTable.conditionConfigJson] as String?;
      if (!ConditionEvaluator.evaluate(configJson, reading)) continue;

      final planId = plan[MaintenancePlanTable.id] as String;
      if (excludedPlanIds.contains(planId)) continue;
      final openTasks = await txn.query(
        WorkOrderTaskTable.tableName,
        columns: [WorkOrderTaskTable.id],
        where:
            '${WorkOrderTaskTable.maintenancePlanId} = ? AND ${WorkOrderTaskTable.status} IN (?, ?) AND ${WorkOrderTaskTable.deletedAt} IS NULL',
        whereArgs: [planId, 'PENDING', 'IN_PROGRESS'],
        limit: 1,
      );
      if (openTasks.isNotEmpty) {
        openTaskCount++;
        continue;
      }

      final occurrenceKey = 'condition:${reading.id}';
      final existingOccurrence = await txn.query(
        WorkOrderTaskTable.tableName,
        columns: [WorkOrderTaskTable.id],
        where:
            '${WorkOrderTaskTable.maintenancePlanId} = ? AND ${WorkOrderTaskTable.sourceOccurrenceKey} = ? AND ${WorkOrderTaskTable.deletedAt} IS NULL',
        whereArgs: [planId, occurrenceKey],
        limit: 1,
      );
      if (existingOccurrence.isNotEmpty) continue;

      final workOrders = await txn.query(
        WorkOrderTable.tableName,
        where:
            '${WorkOrderTable.facilityId} = ? AND ${WorkOrderTable.status} = ? AND ${WorkOrderTable.workOrderType} = ? AND ${WorkOrderTable.deletedAt} IS NULL',
        whereArgs: [facilityId, 'OPEN', 'CORRECTIVE'],
        limit: 1,
      );
      late String workOrderId;
      if (workOrders.isNotEmpty) {
        workOrderId = workOrders.single[WorkOrderTable.id] as String;
      } else {
        workOrderId = IdGenerator.generate();
        final workOrderNumber =
            'WO-CM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
        await txn.insert(WorkOrderTable.tableName, {
          WorkOrderTable.id: workOrderId,
          WorkOrderTable.facilityId: facilityId,
          WorkOrderTable.workOrderNumber: workOrderNumber,
          WorkOrderTable.title: 'دستورکار اضطراری سنسور/شرط',
          WorkOrderTable.workOrderType: 'CORRECTIVE',
          WorkOrderTable.priority: 'HIGH',
          WorkOrderTable.status: 'OPEN',
          WorkOrderTable.createdAt: now,
          WorkOrderTable.updatedAt: now,
          WorkOrderTable.syncStatus: 'pending',
        });
      }

      final taskId = IdGenerator.generate();
      await txn.insert(WorkOrderTaskTable.tableName, {
        WorkOrderTaskTable.id: taskId,
        WorkOrderTaskTable.workOrderId: workOrderId,
        WorkOrderTaskTable.assetId: reading.assetId,
        WorkOrderTaskTable.maintenancePlanId: planId,
        WorkOrderTaskTable.title:
            'رفع شرط بحرانی: ${plan[MaintenancePlanTable.title]}',
        WorkOrderTaskTable.description:
            'خوانش بحرانی با مقدار ${AppNumberFormat.decimal(reading.value)} ${reading.unit} ثبت شد.',
        WorkOrderTaskTable.activityType:
            plan[MaintenancePlanTable.activityType],
        WorkOrderTaskTable.status: 'PENDING',
        WorkOrderTaskTable.triggeringReadingId: reading.id,
        WorkOrderTaskTable.sourceOccurrenceKey: occurrenceKey,
        WorkOrderTaskTable.createdAt: now,
        WorkOrderTaskTable.updatedAt: now,
        WorkOrderTaskTable.syncStatus: 'pending',
      });
      await MaintenancePlanMaterialSeeder.seedTaskMaterials(
        txn,
        planId: planId,
        taskId: taskId,
        now: now,
      );
      generatedCount++;
    }
    return _ConditionTaskGenerationResult(generatedCount, openTaskCount);
  }

  Future<void> _generateMeterTasks(
    Transaction txn, {
    required AssetReading reading,
    required String now,
    Set<String> excludedPlanIds = const {},
  }) async {
    final assetRows = await txn.query(
      AssetTable.tableName,
      columns: [AssetTable.facilityId],
      where: '${AssetTable.id} = ? AND ${AssetTable.deletedAt} IS NULL',
      whereArgs: [reading.assetId],
      limit: 1,
    );
    if (assetRows.isEmpty) return;
    final facilityId = assetRows.single[AssetTable.facilityId] as String;
    final plans = await txn.query(
      MaintenancePlanTable.tableName,
      where:
          '${MaintenancePlanTable.assetId} = ? AND ${MaintenancePlanTable.scheduleType} = ? AND ${MaintenancePlanTable.isActive} = 1 AND ${MaintenancePlanTable.deletedAt} IS NULL',
      whereArgs: [reading.assetId, 'METER'],
    );

    for (final plan in plans) {
      final planId = plan[MaintenancePlanTable.id] as String;
      if (excludedPlanIds.contains(planId)) continue;
      final meterName = plan[MaintenancePlanTable.meterName] as String?;
      final meterUnit = plan[MaintenancePlanTable.meterUnit] as String?;
      final targetValue = (plan[MaintenancePlanTable.nextDueMeterValue] as num?)
          ?.toDouble();
      if (meterName == null ||
          meterUnit == null ||
          targetValue == null ||
          !targetValue.isFinite ||
          reading.metricName.trim().toLowerCase() !=
              meterName.trim().toLowerCase() ||
          reading.value < targetValue) {
        continue;
      }

      final occurrenceKey = 'meter:${meterName.trim()}:$targetValue';
      final existing = await txn.query(
        WorkOrderTaskTable.tableName,
        columns: [WorkOrderTaskTable.id],
        where:
            '${WorkOrderTaskTable.maintenancePlanId} = ? AND ${WorkOrderTaskTable.sourceOccurrenceKey} = ? AND ${WorkOrderTaskTable.deletedAt} IS NULL',
        whereArgs: [planId, occurrenceKey],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;
      if (reading.unit.trim().toLowerCase() != meterUnit.trim().toLowerCase()) {
        continue;
      }

      final openTasks = await txn.query(
        WorkOrderTaskTable.tableName,
        columns: [WorkOrderTaskTable.id],
        where:
            '${WorkOrderTaskTable.maintenancePlanId} = ? AND ${WorkOrderTaskTable.status} IN (?, ?) AND ${WorkOrderTaskTable.deletedAt} IS NULL',
        whereArgs: [planId, 'PENDING', 'IN_PROGRESS'],
        limit: 1,
      );
      if (openTasks.isNotEmpty) continue;

      final workOrders = await txn.query(
        WorkOrderTable.tableName,
        where:
            '${WorkOrderTable.facilityId} = ? AND ${WorkOrderTable.status} = ? AND ${WorkOrderTable.workOrderType} = ? AND ${WorkOrderTable.deletedAt} IS NULL',
        whereArgs: [facilityId, 'OPEN', 'PREVENTIVE'],
        limit: 1,
      );
      late String workOrderId;
      if (workOrders.isNotEmpty) {
        workOrderId = workOrders.single[WorkOrderTable.id] as String;
      } else {
        workOrderId = IdGenerator.generate();
        final suffix = DateTime.now().millisecondsSinceEpoch
            .toString()
            .substring(5);
        await txn.insert(WorkOrderTable.tableName, {
          WorkOrderTable.id: workOrderId,
          WorkOrderTable.facilityId: facilityId,
          WorkOrderTable.workOrderNumber: 'WO-PM-$suffix',
          WorkOrderTable.title: 'دستورکار پیشگیرانه خودکار',
          WorkOrderTable.workOrderType: 'PREVENTIVE',
          WorkOrderTable.priority: plan[MaintenancePlanTable.priority],
          WorkOrderTable.status: 'OPEN',
          WorkOrderTable.createdAt: now,
          WorkOrderTable.updatedAt: now,
          WorkOrderTable.syncStatus: 'pending',
        });
      }

      final taskId = IdGenerator.generate();
      await txn.insert(WorkOrderTaskTable.tableName, {
        WorkOrderTaskTable.id: taskId,
        WorkOrderTaskTable.workOrderId: workOrderId,
        WorkOrderTaskTable.assetId: reading.assetId,
        WorkOrderTaskTable.maintenancePlanId: planId,
        WorkOrderTaskTable.title:
            '${plan[MaintenancePlanTable.title]} (سررسید کارکرد)',
        WorkOrderTaskTable.description: plan[MaintenancePlanTable.description],
        WorkOrderTaskTable.activityType:
            plan[MaintenancePlanTable.activityType],
        WorkOrderTaskTable.status: 'PENDING',
        WorkOrderTaskTable.plannedMeterValue: targetValue,
        WorkOrderTaskTable.triggeringReadingId: reading.id,
        WorkOrderTaskTable.sourceOccurrenceKey: occurrenceKey,
        WorkOrderTaskTable.createdAt: now,
        WorkOrderTaskTable.updatedAt: now,
        WorkOrderTaskTable.syncStatus: 'pending',
      });
      await MaintenancePlanMaterialSeeder.seedTaskMaterials(
        txn,
        planId: planId,
        taskId: taskId,
        now: now,
      );
      final deduplicationKey = 'alert:plan:$planId:$occurrenceKey';
      await txn.insert(AlertEventTable.tableName, {
        AlertEventTable.id: IdGenerator.generate(),
        AlertEventTable.facilityId: facilityId,
        AlertEventTable.alertType: 'MAINTENANCE_DUE',
        AlertEventTable.severity:
            plan[MaintenancePlanTable.priority] == 'CRITICAL'
            ? 'CRITICAL'
            : 'WARNING',
        AlertEventTable.status: 'ACTIVE',
        AlertEventTable.title:
            'سررسید کارکرد: ${plan[MaintenancePlanTable.title]}',
        AlertEventTable.message:
            'شاخص ${reading.metricName} به مقدار هدف $targetValue ${reading.unit} رسیده است.',
        AlertEventTable.assetId: reading.assetId,
        AlertEventTable.maintenancePlanId: planId,
        AlertEventTable.workOrderTaskId: taskId,
        AlertEventTable.deduplicationKey: deduplicationKey,
        AlertEventTable.triggeredAt: now,
        AlertEventTable.createdAt: now,
        AlertEventTable.updatedAt: now,
        AlertEventTable.syncStatus: 'pending',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
