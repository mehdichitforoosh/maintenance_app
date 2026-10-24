import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/asset_table.dart';
import '../../../core/storage/database/tables/maintenance_plan_material_table.dart';
import '../../../core/storage/database/tables/maintenance_plan_table.dart';
import '../../../core/storage/database/tables/inventory_item_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_plan_material.dart';

class MaintenancePlanRepository {
  static const String _tableName = MaintenancePlanTable.tableName;
  final DatabaseHelper _dbHelper;

  MaintenancePlanRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<MaintenancePlan>> getPlans(String assetId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where:
          '${MaintenancePlanTable.assetId} = ? AND ${MaintenancePlanTable.deletedAt} IS NULL',
      whereArgs: [assetId],
      orderBy: '${MaintenancePlanTable.title} ASC',
    );
    return results.map((m) => MaintenancePlan.fromMap(m)).toList();
  }

  Future<List<MaintenancePlan>> getAllActivePlans(String facilityId) async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery(
      '''
      SELECT p.* FROM $_tableName p
      JOIN ${AssetTable.tableName} a ON p.${MaintenancePlanTable.assetId} = a.${AssetTable.id}
      WHERE a.${AssetTable.facilityId} = ? AND p.${MaintenancePlanTable.isActive} = 1 AND p.${MaintenancePlanTable.deletedAt} IS NULL AND a.${AssetTable.deletedAt} IS NULL
    ''',
      [facilityId],
    );
    return results.map((m) => MaintenancePlan.fromMap(m)).toList();
  }

  Future<MaintenancePlan?> getPlanById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where:
          '${MaintenancePlanTable.id} = ? AND ${MaintenancePlanTable.deletedAt} IS NULL',
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
    double? nextDueMeterValue,
    String? conditionConfigJson,
    String? oneTimeDueAt,
    String? startDate,
    String? nextDueAt,
    ScheduleAnchor scheduleAnchor = ScheduleAnchor.completionDate,
    bool isActive = true,
    List<Map<String, dynamic>> materials = const [],
  }) async {
    final selectedMaterials = _validatePlanMaterials(materials);
    _validatePlanFields(
      title: title,
      scheduleType: scheduleType,
      calendarIntervalValue: calendarIntervalValue,
      calendarIntervalUnit: calendarIntervalUnit,
      meterName: meterName?.trim(),
      meterInterval: meterInterval,
      meterUnit: meterUnit?.trim(),
      lastCompletedMeterValue: null,
      nextDueMeterValue: nextDueMeterValue,
      conditionConfigJson: conditionConfigJson,
      oneTimeDueAt: oneTimeDueAt,
      nextDueAt: nextDueAt ?? startDate,
    );
    final db = await _dbHelper.db;
    final id = IdGenerator.generate();
    final now = AppDateUtils.nowUtcIso();

    String? resolvedNextDue = nextDueAt ?? startDate;
    if (scheduleType == ScheduleType.calendar &&
        resolvedNextDue == null &&
        calendarIntervalValue != null &&
        calendarIntervalUnit != null) {
      resolvedNextDue = AppDateUtils.toUtcIso(
        AppDateUtils.addCalendarInterval(
          DateTime.now(),
          calendarIntervalValue,
          calendarIntervalUnit.toDbString(),
        ),
      );
    }

    final plan = MaintenancePlan(
      id: id,
      assetId: assetId,
      title: title.trim(),
      description: description,
      activityType: activityType,
      priority: priority,
      scheduleType: scheduleType,
      calendarIntervalValue: calendarIntervalValue,
      calendarIntervalUnit: calendarIntervalUnit,
      meterName: meterName,
      meterInterval: meterInterval,
      meterUnit: meterUnit,
      nextDueMeterValue: scheduleType == ScheduleType.meter
          ? nextDueMeterValue
          : null,
      conditionConfigJson: conditionConfigJson,
      oneTimeDueAt: oneTimeDueAt,
      startDate: startDate,
      nextDueAt: resolvedNextDue,
      scheduleAnchor: scheduleAnchor,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert(_tableName, plan.toMap());
      await _savePlanMaterials(
        txn,
        planId: id,
        selectedByItem: selectedMaterials,
        now: now,
        merge: false,
      );
    });
    return plan;
  }

  Future<MaintenancePlan> updatePlan(
    MaintenancePlan plan, {
    List<Map<String, dynamic>>? materials,
  }) async {
    final selectedMaterials = materials == null
        ? null
        : _validatePlanMaterials(materials);
    _validatePlanFields(
      title: plan.title,
      scheduleType: plan.scheduleType,
      calendarIntervalValue: plan.calendarIntervalValue,
      calendarIntervalUnit: plan.calendarIntervalUnit,
      meterName: plan.meterName,
      meterInterval: plan.meterInterval,
      meterUnit: plan.meterUnit,
      lastCompletedMeterValue: plan.lastCompletedMeterValue,
      nextDueMeterValue: plan.nextDueMeterValue,
      conditionConfigJson: plan.conditionConfigJson,
      oneTimeDueAt: plan.oneTimeDueAt,
      nextDueAt: plan.nextDueAt ?? plan.startDate,
    );
    final db = await _dbHelper.db;
    final nextDueAt = plan.scheduleType == ScheduleType.calendar
        ? plan.nextDueAt ??
              plan.startDate ??
              AppDateUtils.toUtcIso(
                AppDateUtils.addCalendarInterval(
                  DateTime.now(),
                  plan.calendarIntervalValue!,
                  plan.calendarIntervalUnit!.toDbString(),
                ),
              )
        : plan.nextDueAt;
    final updated = plan.copyWith(
      title: plan.title.trim(),
      meterName: plan.meterName?.trim(),
      meterUnit: plan.meterUnit?.trim(),
      nextDueAt: nextDueAt,
      clearNextDueAt: plan.scheduleType != ScheduleType.calendar,
      clearLastCompletedMeterValue: plan.scheduleType != ScheduleType.meter,
      clearNextDueMeterValue: plan.scheduleType != ScheduleType.meter,
      updatedAt: AppDateUtils.nowUtcIso(),
    );
    await db.transaction((txn) async {
      final count = await txn.update(
        _tableName,
        updated.toMap(),
        where:
            '${MaintenancePlanTable.id} = ? AND ${MaintenancePlanTable.deletedAt} IS NULL',
        whereArgs: [plan.id],
      );
      if (count == 0) throw StateError('برنامه نگهداری پیدا نشد.');
      if (selectedMaterials != null) {
        await _savePlanMaterials(
          txn,
          planId: plan.id,
          selectedByItem: selectedMaterials,
          now: updated.updatedAt,
          merge: false,
        );
      }
    });
    return updated;
  }

  void _validatePlanFields({
    required String title,
    required ScheduleType scheduleType,
    int? calendarIntervalValue,
    CalendarUnit? calendarIntervalUnit,
    String? meterName,
    double? meterInterval,
    String? meterUnit,
    double? lastCompletedMeterValue,
    double? nextDueMeterValue,
    String? conditionConfigJson,
    String? oneTimeDueAt,
    String? nextDueAt,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'عنوان برنامه الزامی است.');
    }

    switch (scheduleType) {
      case ScheduleType.calendar:
        if (calendarIntervalValue == null ||
            calendarIntervalValue <= 0 ||
            calendarIntervalUnit == null) {
          throw ArgumentError('فاصله و واحد زمان‌بندی تقویمی باید معتبر باشد.');
        }
        if (nextDueAt != null && DateTime.tryParse(nextDueAt) == null) {
          throw ArgumentError.value(
            nextDueAt,
            'nextDueAt',
            'تاریخ سررسید معتبر نیست.',
          );
        }
      case ScheduleType.meter:
        if (meterName == null ||
            meterName.trim().isEmpty ||
            meterInterval == null ||
            !meterInterval.isFinite ||
            meterInterval <= 0 ||
            meterUnit == null ||
            meterUnit.trim().isEmpty ||
            nextDueMeterValue == null ||
            !nextDueMeterValue.isFinite ||
            nextDueMeterValue < 0 ||
            (lastCompletedMeterValue != null &&
                (!lastCompletedMeterValue.isFinite ||
                    lastCompletedMeterValue < 0)) ||
            (lastCompletedMeterValue != null &&
                nextDueMeterValue <= lastCompletedMeterValue)) {
          throw ArgumentError('مشخصات زمان‌بندی بر اساس کارکرد معتبر نیست.');
        }
      case ScheduleType.condition:
        _validateConditionConfig(conditionConfigJson);
      case ScheduleType.oneTime:
        if (oneTimeDueAt == null || DateTime.tryParse(oneTimeDueAt) == null) {
          throw ArgumentError('تاریخ اجرای برنامه یک‌باره معتبر نیست.');
        }
      case ScheduleType.manual:
        break;
    }
  }

  void _validateConditionConfig(String? conditionConfigJson) {
    if (conditionConfigJson == null || conditionConfigJson.trim().isEmpty) {
      throw ArgumentError('شرط اجرای برنامه الزامی است.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(conditionConfigJson);
    } on FormatException {
      throw ArgumentError('ساختار شرط اجرای برنامه معتبر نیست.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw ArgumentError('ساختار شرط اجرای برنامه معتبر نیست.');
    }
    final metric = decoded['metric'];
    final operator = decoded['operator'];
    final threshold = decoded['threshold'];
    final unit = decoded['unit'];
    if (metric is! String ||
        metric.trim().isEmpty ||
        operator is! String ||
        !{'gt', 'gte', 'lt', 'lte', 'eq'}.contains(operator) ||
        threshold is! num ||
        !threshold.isFinite ||
        unit is! String ||
        unit.trim().isEmpty) {
      throw ArgumentError('مشخصات شرط اجرای برنامه معتبر نیست.');
    }
  }

  Future<void> deletePlan(String id) async {
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    await db.update(
      _tableName,
      {
        MaintenancePlanTable.deletedAt: now,
        MaintenancePlanTable.updatedAt: now,
      },
      where: '${MaintenancePlanTable.id} = ?',
      whereArgs: [id],
    );
  }

  Future<List<MaintenancePlanMaterial>> getPlanMaterials(String planId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      MaintenancePlanMaterialTable.tableName,
      where:
          '${MaintenancePlanMaterialTable.maintenancePlanId} = ? AND ${MaintenancePlanMaterialTable.deletedAt} IS NULL',
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
    await savePlanMaterials(
      planId: planId,
      materials: [
        {
          'item_id': itemId,
          'planned_quantity': plannedQuantity,
          'notes': notes,
        },
      ],
      merge: true,
    );
  }

  Future<void> savePlanMaterials({
    required String planId,
    required List<Map<String, dynamic>> materials,
    bool merge = false,
  }) async {
    final selectedByItem = _validatePlanMaterials(materials);
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();

    await db.transaction(
      (txn) => _savePlanMaterials(
        txn,
        planId: planId,
        selectedByItem: selectedByItem,
        now: now,
        merge: merge,
      ),
    );
  }

  Map<String, Map<String, dynamic>> _validatePlanMaterials(
    List<Map<String, dynamic>> materials,
  ) {
    final selectedByItem = <String, Map<String, dynamic>>{};
    for (final material in materials) {
      final itemId = material['item_id'];
      final quantity = material['planned_quantity'];
      final notes = material['notes'];
      if (itemId is! String || itemId.trim().isEmpty) {
        throw ArgumentError('کالای برنامه نگهداری معتبر نیست.');
      }
      if (quantity is! num || !quantity.toDouble().isFinite || quantity <= 0) {
        throw ArgumentError('مقدار برنامه‌ریزی‌شده باید بزرگ‌تر از صفر باشد.');
      }
      if (notes != null && notes is! String) {
        throw ArgumentError('توضیحات قلم برنامه نگهداری معتبر نیست.');
      }
      final normalizedItemId = itemId.trim();
      if (selectedByItem.containsKey(normalizedItemId)) {
        throw ArgumentError('هر کالا فقط یک‌بار در برنامه قابل ثبت است.');
      }
      selectedByItem[normalizedItemId] = material;
    }
    return selectedByItem;
  }

  Future<void> _savePlanMaterials(
    DatabaseExecutor txn, {
    required String planId,
    required Map<String, Map<String, dynamic>> selectedByItem,
    required String now,
    required bool merge,
  }) async {
    final plans = await txn.query(
      _tableName,
      columns: [MaintenancePlanTable.id],
      where:
          '${MaintenancePlanTable.id} = ? AND ${MaintenancePlanTable.deletedAt} IS NULL',
      whereArgs: [planId],
      limit: 1,
    );
    if (plans.isEmpty) throw StateError('برنامه نگهداری پیدا نشد.');

    for (final entry in selectedByItem.entries) {
      final itemId = entry.key;
      final itemRows = await txn.query(
        InventoryItemTable.tableName,
        columns: [InventoryItemTable.id, InventoryItemTable.isActive],
        where:
            '${InventoryItemTable.id} = ? AND ${InventoryItemTable.deletedAt} IS NULL',
        whereArgs: [itemId],
        limit: 1,
      );
      if (itemRows.isEmpty) {
        throw ArgumentError('کالای انتخاب‌شده موجود یا فعال نیست.');
      }

      final existing = await txn.query(
        MaintenancePlanMaterialTable.tableName,
        where:
            '${MaintenancePlanMaterialTable.maintenancePlanId} = ? AND ${MaintenancePlanMaterialTable.itemId} = ?',
        whereArgs: [planId, itemId],
        limit: 1,
      );
      if ((itemRows.single[InventoryItemTable.isActive] as int) != 1 &&
          (existing.isEmpty ||
              existing.single[MaintenancePlanMaterialTable.deletedAt] !=
                  null)) {
        throw ArgumentError('کالای انتخاب‌شده غیرفعال است.');
      }
      final notes = entry.value['notes'] as String?;
      final data = {
        MaintenancePlanMaterialTable.plannedQuantity:
            (entry.value['planned_quantity'] as num).toDouble(),
        MaintenancePlanMaterialTable.notes: notes?.trim().isEmpty ?? true
            ? null
            : notes?.trim(),
        MaintenancePlanMaterialTable.deletedAt: null,
        MaintenancePlanMaterialTable.updatedAt: now,
        MaintenancePlanMaterialTable.syncStatus: 'pending',
      };
      if (existing.isEmpty) {
        await txn.insert(MaintenancePlanMaterialTable.tableName, {
          MaintenancePlanMaterialTable.id: IdGenerator.generate(),
          MaintenancePlanMaterialTable.maintenancePlanId: planId,
          MaintenancePlanMaterialTable.itemId: itemId,
          ...data,
          MaintenancePlanMaterialTable.createdAt: now,
        });
      } else {
        await txn.update(
          MaintenancePlanMaterialTable.tableName,
          data,
          where: '${MaintenancePlanMaterialTable.id} = ?',
          whereArgs: [existing.first[MaintenancePlanMaterialTable.id]],
        );
      }
    }

    if (!merge) {
      final activeRows = await txn.query(
        MaintenancePlanMaterialTable.tableName,
        columns: [
          MaintenancePlanMaterialTable.id,
          MaintenancePlanMaterialTable.itemId,
        ],
        where:
            '${MaintenancePlanMaterialTable.maintenancePlanId} = ? AND ${MaintenancePlanMaterialTable.deletedAt} IS NULL',
        whereArgs: [planId],
      );
      for (final row in activeRows) {
        final itemId = row[MaintenancePlanMaterialTable.itemId] as String;
        if (!selectedByItem.containsKey(itemId)) {
          await txn.update(
            MaintenancePlanMaterialTable.tableName,
            {
              MaintenancePlanMaterialTable.deletedAt: now,
              MaintenancePlanMaterialTable.updatedAt: now,
              MaintenancePlanMaterialTable.syncStatus: 'pending',
            },
            where: '${MaintenancePlanMaterialTable.id} = ?',
            whereArgs: [row[MaintenancePlanMaterialTable.id]],
          );
        }
      }
    }
  }
}
