import 'package:sqflite/sqflite.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/asset_table.dart';
import '../../../core/storage/database/tables/maintenance_plan_material_table.dart';
import '../../../core/storage/database/tables/maintenance_plan_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_plan_material.dart';

class MaintenancePlanRepository {
  static const String _tableName = MaintenancePlanTable.tableName;
  final DatabaseHelper _dbHelper;

  MaintenancePlanRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<MaintenancePlan>> getPlans(String assetId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where: '${MaintenancePlanTable.assetId} = ? AND ${MaintenancePlanTable.deletedAt} IS NULL',
      whereArgs: [assetId],
      orderBy: '${MaintenancePlanTable.title} ASC',
    );
    return results.map((m) => MaintenancePlan.fromMap(m)).toList();
  }

  Future<List<MaintenancePlan>> getAllActivePlans(String facilityId) async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery('''
      SELECT p.* FROM $_tableName p
      JOIN ${AssetTable.tableName} a ON p.${MaintenancePlanTable.assetId} = a.${AssetTable.id}
      WHERE a.${AssetTable.facilityId} = ? AND p.${MaintenancePlanTable.isActive} = 1 AND p.${MaintenancePlanTable.deletedAt} IS NULL AND a.${AssetTable.deletedAt} IS NULL
    ''', [facilityId]);
    return results.map((m) => MaintenancePlan.fromMap(m)).toList();
  }

  Future<MaintenancePlan?> getPlanById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where: '${MaintenancePlanTable.id} = ? AND ${MaintenancePlanTable.deletedAt} IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MaintenancePlan.fromMap(results.first);
  }

  Future<MaintenancePlan> createPlan({
    required String assetId,
    required String title,
    String? description,
    ActivityType activityType = ActivityType.inspection,
    Priority priority = Priority.medium,
    required ScheduleType scheduleType,
    int? calendarIntervalValue,
    CalendarUnit? calendarIntervalUnit,
    String? meterName,
    double? meterInterval,
    String? meterUnit,
    String? conditionConfigJson,
    String? oneTimeDueAt,
    String? startDate,
    String? nextDueAt,
    ScheduleAnchor scheduleAnchor = ScheduleAnchor.completionDate,
  }) async {
    final db = await _dbHelper.db;
    final id = IdGenerator.generate();
    final now = AppDateUtils.nowUtcIso();

    String? resolvedNextDue = nextDueAt ?? startDate;
    if (scheduleType == ScheduleType.calendar && resolvedNextDue == null && calendarIntervalValue != null && calendarIntervalUnit != null) {
      resolvedNextDue = AppDateUtils.toUtcIso(
        AppDateUtils.addCalendarInterval(DateTime.now(), calendarIntervalValue, calendarIntervalUnit.toDbString()),
      );
    }

    final plan = MaintenancePlan(
      id: id,
      assetId: assetId,
      title: title,
      description: description,
      activityType: activityType,
      priority: priority,
      scheduleType: scheduleType,
      calendarIntervalValue: calendarIntervalValue,
      calendarIntervalUnit: calendarIntervalUnit,
      meterName: meterName,
      meterInterval: meterInterval,
      meterUnit: meterUnit,
      nextDueMeterValue: meterInterval,
      conditionConfigJson: conditionConfigJson,
      oneTimeDueAt: oneTimeDueAt,
      startDate: startDate,
      nextDueAt: resolvedNextDue,
      scheduleAnchor: scheduleAnchor,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert(_tableName, plan.toMap());
    return plan;
  }

  Future<MaintenancePlan> updatePlan(MaintenancePlan plan) async {
    final db = await _dbHelper.db;
    final updated = plan.copyWith(updatedAt: AppDateUtils.nowUtcIso());
    await db.update(
      _tableName,
      updated.toMap(),
      where: '${MaintenancePlanTable.id} = ?',
      whereArgs: [plan.id],
    );
    return updated;
  }

  Future<void> deletePlan(String id) async {
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    await db.update(
      _tableName,
      {MaintenancePlanTable.deletedAt: now, MaintenancePlanTable.updatedAt: now},
      where: '${MaintenancePlanTable.id} = ?',
      whereArgs: [id],
    );
  }

  Future<List<MaintenancePlanMaterial>> getPlanMaterials(String planId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      MaintenancePlanMaterialTable.tableName,
      where: '${MaintenancePlanMaterialTable.maintenancePlanId} = ? AND ${MaintenancePlanMaterialTable.deletedAt} IS NULL',
      whereArgs: [planId],
    );
    return results.map((m) => MaintenancePlanMaterial.fromMap(m)).toList();
  }

  Future<void> addPlanMaterial({
    required String planId,
    required String itemId,
    required double plannedQuantity,
    String? notes,
  }) async {
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    await db.insert(
      MaintenancePlanMaterialTable.tableName,
      {
        MaintenancePlanMaterialTable.id: IdGenerator.generate(),
        MaintenancePlanMaterialTable.maintenancePlanId: planId,
        MaintenancePlanMaterialTable.itemId: itemId,
        MaintenancePlanMaterialTable.plannedQuantity: plannedQuantity,
        MaintenancePlanMaterialTable.notes: notes,
        MaintenancePlanMaterialTable.createdAt: now,
        MaintenancePlanMaterialTable.updatedAt: now,
        MaintenancePlanMaterialTable.syncStatus: 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
