import 'package:sqflite/sqflite.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_plan_material.dart';

class MaintenancePlanRepository {
  final DatabaseHelper _dbHelper;

  MaintenancePlanRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<MaintenancePlan>> getPlans(String assetId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'maintenance_plans',
      where: 'asset_id = ? AND deleted_at IS NULL',
      whereArgs: [assetId],
      orderBy: 'title ASC',
    );
    return results.map((m) => MaintenancePlan.fromMap(m)).toList();
  }

  Future<List<MaintenancePlan>> getAllActivePlans(String facilityId) async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery('''
      SELECT p.* FROM maintenance_plans p
      JOIN assets a ON p.asset_id = a.id
      WHERE a.facility_id = ? AND p.is_active = 1 AND p.deleted_at IS NULL AND a.deleted_at IS NULL
    ''', [facilityId]);
    return results.map((m) => MaintenancePlan.fromMap(m)).toList();
  }

  Future<MaintenancePlan?> getPlanById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'maintenance_plans',
      where: 'id = ? AND deleted_at IS NULL',
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

    await db.insert('maintenance_plans', plan.toMap());
    return plan;
  }

  Future<MaintenancePlan> updatePlan(MaintenancePlan plan) async {
    final db = await _dbHelper.db;
    final updated = plan.copyWith(updatedAt: AppDateUtils.nowUtcIso());
    await db.update(
      'maintenance_plans',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
    return updated;
  }

  Future<void> deletePlan(String id) async {
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    await db.update(
      'maintenance_plans',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MaintenancePlanMaterial>> getPlanMaterials(String planId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'maintenance_plan_materials',
      where: 'maintenance_plan_id = ? AND deleted_at IS NULL',
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
      'maintenance_plan_materials',
      {
        'id': IdGenerator.generate(),
        'maintenance_plan_id': planId,
        'item_id': itemId,
        'planned_quantity': plannedQuantity,
        'notes': notes,
        'created_at': now,
        'updated_at': now,
        'sync_status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
