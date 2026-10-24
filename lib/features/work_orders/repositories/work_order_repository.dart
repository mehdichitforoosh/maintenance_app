import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/inventory_item_table.dart';
import '../../../core/storage/database/tables/asset_reading_table.dart';
import '../../../core/storage/database/tables/alert_event_table.dart';
import '../../../core/storage/database/tables/maintenance_plan_table.dart';
import '../../../core/storage/database/tables/stock_transaction_table.dart';
import '../../../core/storage/database/tables/work_order_material_table.dart';
import '../../../core/storage/database/tables/work_order_table.dart';
import '../../../core/storage/database/tables/work_order_task_event_table.dart';
import '../../../core/storage/database/tables/work_order_task_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/number_format_utils.dart';
import '../models/work_order.dart';
import '../models/work_order_material.dart';
import '../models/work_order_task.dart';
import '../../maintenance/models/maintenance_plan.dart';
import '../../maintenance/services/maintenance_plan_material_seeder.dart';
import '../../assets/models/asset_reading.dart';

class WorkOrderRepository {
  static const String _tableName = WorkOrderTable.tableName;
  final DatabaseHelper _dbHelper;

  WorkOrderRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getTaskEvents(String taskId) async {
    final db = await _dbHelper.db;
    return db.query(
      WorkOrderTaskEventTable.tableName,
      where: '${WorkOrderTaskEventTable.workOrderTaskId} = ?',
      whereArgs: [taskId],
      orderBy: '${WorkOrderTaskEventTable.createdAt} DESC, rowid DESC',
    );
  }

  Future<Map<String, dynamic>> _taskSnapshot(
    Transaction txn,
    String taskId,
  ) async {
    final tasks = await txn.query(
      WorkOrderTaskTable.tableName,
      where: '${WorkOrderTaskTable.id} = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    final materials = await txn.query(
      WorkOrderMaterialTable.tableName,
      where:
          '${WorkOrderMaterialTable.workOrderTaskId} = ? AND ${WorkOrderMaterialTable.deletedAt} IS NULL',
      whereArgs: [taskId],
      orderBy: WorkOrderMaterialTable.itemId,
    );
    final task = tasks.isEmpty ? null : tasks.first;
    final workOrders = task == null
        ? const <Map<String, Object?>>[]
        : await txn.query(
            WorkOrderTable.tableName,
            where: '${WorkOrderTable.id} = ?',
            whereArgs: [task[WorkOrderTaskTable.workOrderId]],
            limit: 1,
          );
    return {
      'task': task,
      'work_order': workOrders.isEmpty ? null : workOrders.first,
      'materials': materials,
    };
  }

  Future<void> _insertTaskEvent(
    Transaction txn, {
    required String taskId,
    required String eventType,
    required String now,
    String? reason,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) async {
    await txn.insert(WorkOrderTaskEventTable.tableName, {
      WorkOrderTaskEventTable.id: IdGenerator.generate(),
      WorkOrderTaskEventTable.workOrderTaskId: taskId,
      WorkOrderTaskEventTable.eventType: eventType,
      WorkOrderTaskEventTable.reason: reason,
      WorkOrderTaskEventTable.beforeJson: before == null
          ? null
          : jsonEncode(before),
      WorkOrderTaskEventTable.afterJson: after == null
          ? null
          : jsonEncode(after),
      WorkOrderTaskEventTable.createdAt: now,
    });
  }

  Future<void> _reconcileMaterialStock(
    Transaction txn, {
    required Map<String, dynamic> material,
    required double targetQuantity,
    required String now,
  }) async {
    final itemId = material[WorkOrderMaterialTable.itemId] as String;
    final materialId = material[WorkOrderMaterialTable.id] as String;
    final cost = (material[WorkOrderMaterialTable.unitCostAtUse] as num?)
        ?.toDouble();
    final postedRows = await txn.rawQuery(
      '''
        SELECT COALESCE(SUM(
          CASE
            WHEN ${StockTransactionTable.transactionType} = 'MAINTENANCE_CONSUMPTION' THEN ${StockTransactionTable.quantity}
            WHEN ${StockTransactionTable.transactionType} = 'RETURN' THEN -${StockTransactionTable.quantity}
            ELSE 0
          END
        ), 0) AS posted_quantity
        FROM ${StockTransactionTable.tableName}
        WHERE ${StockTransactionTable.workOrderMaterialId} = ?
          AND ${StockTransactionTable.deletedAt} IS NULL
      ''',
      [materialId],
    );
    final postedQuantity = (postedRows.first['posted_quantity'] as num)
        .toDouble();
    final difference = targetQuantity - postedQuantity;
    if (difference.abs() < 0.000001) return;

    final isConsumption = difference > 0;
    if (isConsumption) {
      final stockRows = await txn.rawQuery(
        '''
          SELECT COALESCE(SUM(
            CASE
              WHEN ${StockTransactionTable.transactionType} IN ('PURCHASE_RECEIPT', 'ADJUSTMENT_IN', 'RETURN') THEN ${StockTransactionTable.quantity}
              WHEN ${StockTransactionTable.transactionType} IN ('MAINTENANCE_CONSUMPTION', 'ADJUSTMENT_OUT') THEN -${StockTransactionTable.quantity}
              ELSE 0
            END
          ), 0) AS current_stock
          FROM ${StockTransactionTable.tableName}
          WHERE ${StockTransactionTable.itemId} = ?
            AND ${StockTransactionTable.deletedAt} IS NULL
        ''',
        [itemId],
      );
      final stock = (stockRows.first['current_stock'] as num).toDouble();
      if (stock < difference) {
        throw StateError(
          'موجودی کالا کافی نیست. موجودی فعلی: ${AppNumberFormat.decimal(stock)}، مقدار درخواستی: ${AppNumberFormat.decimal(difference)}',
        );
      }
    }

    await txn.insert(StockTransactionTable.tableName, {
      StockTransactionTable.id: IdGenerator.generate(),
      StockTransactionTable.itemId: itemId,
      StockTransactionTable.transactionType: isConsumption
          ? 'MAINTENANCE_CONSUMPTION'
          : 'RETURN',
      StockTransactionTable.quantity: difference.abs(),
      StockTransactionTable.unitCost: cost,
      StockTransactionTable.transactionDate: now,
      StockTransactionTable.workOrderMaterialId: materialId,
      StockTransactionTable.createdAt: now,
      StockTransactionTable.updatedAt: now,
      StockTransactionTable.syncStatus: 'pending',
    });
  }

  Future<void> reopenCompletedTask({
    required String taskId,
    required String reason,
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      throw ArgumentError('دلیل بازگشایی وظیفه را وارد کنید.');
    }
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();

    await db.transaction((txn) async {
      final tasks = await txn.query(
        WorkOrderTaskTable.tableName,
        where:
            '${WorkOrderTaskTable.id} = ? AND ${WorkOrderTaskTable.deletedAt} IS NULL',
        whereArgs: [taskId],
        limit: 1,
      );
      if (tasks.isEmpty) throw ArgumentError('وظیفه یافت نشد.');
      final task = WorkOrderTask.fromMap(tasks.first);
      if (task.status != TaskStatus.completed) {
        throw StateError('فقط وظیفه تکمیل‌شده را می‌توان بازگشایی کرد.');
      }

      final before = await _taskSnapshot(txn, taskId);
      await txn.update(
        WorkOrderTaskTable.tableName,
        {
          WorkOrderTaskTable.status: 'IN_PROGRESS',
          WorkOrderTaskTable.result: null,
          WorkOrderTaskTable.completedAt: null,
          WorkOrderTaskTable.findings: null,
          WorkOrderTaskTable.failureDescription: null,
          WorkOrderTaskTable.followUpRequired: 0,
          WorkOrderTaskTable.laborMinutes: null,
          WorkOrderTaskTable.downtimeMinutes: null,
          WorkOrderTaskTable.completionMeterValue: null,
          WorkOrderTaskTable.completionMeterName: null,
          WorkOrderTaskTable.completionMeterUnit: null,
          WorkOrderTaskTable.updatedAt: now,
          WorkOrderTaskTable.syncStatus: 'pending',
        },
        where: '${WorkOrderTaskTable.id} = ?',
        whereArgs: [taskId],
      );
      await txn.update(
        WorkOrderTable.tableName,
        {
          WorkOrderTable.status: 'IN_PROGRESS',
          WorkOrderTable.completedAt: null,
          WorkOrderTable.closedAt: null,
          WorkOrderTable.updatedAt: now,
          WorkOrderTable.syncStatus: 'pending',
        },
        where: '${WorkOrderTable.id} = ?',
        whereArgs: [task.workOrderId],
      );
      final after = await _taskSnapshot(txn, taskId);
      await _insertTaskEvent(
        txn,
        taskId: taskId,
        eventType: 'REOPENED',
        reason: normalizedReason,
        before: before,
        after: after,
        now: now,
      );
    });
  }

  Future<void> correctCompletedTask({
    required String taskId,
    required String reason,
    required TaskResult result,
    required String? findings,
    required int laborMinutes,
    required int downtimeMinutes,
    required List<Map<String, dynamic>> actualMaterials,
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      throw ArgumentError('دلیل اصلاح اطلاعات را وارد کنید.');
    }
    if (laborMinutes < 0 || downtimeMinutes < 0) {
      throw ArgumentError('زمان کار و توقف نمی‌توانند منفی باشند.');
    }
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();

    await db.transaction((txn) async {
      final tasks = await txn.query(
        WorkOrderTaskTable.tableName,
        where:
            '${WorkOrderTaskTable.id} = ? AND ${WorkOrderTaskTable.deletedAt} IS NULL',
        whereArgs: [taskId],
        limit: 1,
      );
      if (tasks.isEmpty) throw ArgumentError('وظیفه یافت نشد.');
      if (tasks.first[WorkOrderTaskTable.status] != 'COMPLETED') {
        throw StateError('اصلاح اطلاعات فقط برای وظیفه تکمیل‌شده مجاز است.');
      }

      final requestedByItem = <String, double>{};
      for (final entry in actualMaterials) {
        final itemId = entry['item_id'];
        final quantity = entry['quantity'];
        if (itemId is! String ||
            quantity is! num ||
            !quantity.toDouble().isFinite ||
            quantity < 0 ||
            requestedByItem.containsKey(itemId)) {
          throw ArgumentError('اطلاعات مقدار متریال نامعتبر یا تکراری است.');
        }
        requestedByItem[itemId] = quantity.toDouble();
      }

      final before = await _taskSnapshot(txn, taskId);
      final existingRows = await txn.query(
        WorkOrderMaterialTable.tableName,
        where:
            '${WorkOrderMaterialTable.workOrderTaskId} = ? AND ${WorkOrderMaterialTable.deletedAt} IS NULL',
        whereArgs: [taskId],
      );
      final materialByItem = {
        for (final row in existingRows)
          row[WorkOrderMaterialTable.itemId] as String: row,
      };

      for (final entry in requestedByItem.entries) {
        final itemId = entry.key;
        final existing = materialByItem[itemId];
        if (existing == null) {
          final itemRows = await txn.query(
            InventoryItemTable.tableName,
            columns: [InventoryItemTable.defaultUnitCost],
            where:
                '${InventoryItemTable.id} = ? AND ${InventoryItemTable.deletedAt} IS NULL AND ${InventoryItemTable.isActive} = 1',
            whereArgs: [itemId],
            limit: 1,
          );
          if (itemRows.isEmpty) {
            throw ArgumentError('کالای جدید باید در انبار فعال باشد.');
          }
          final materialId = IdGenerator.generate();
          final cost =
              (itemRows.first[InventoryItemTable.defaultUnitCost] as num?)
                  ?.toDouble();
          await txn.insert(WorkOrderMaterialTable.tableName, {
            WorkOrderMaterialTable.id: materialId,
            WorkOrderMaterialTable.workOrderTaskId: taskId,
            WorkOrderMaterialTable.itemId: itemId,
            WorkOrderMaterialTable.actualQuantity: entry.value,
            WorkOrderMaterialTable.unitCostAtUse: cost,
            WorkOrderMaterialTable.createdAt: now,
            WorkOrderMaterialTable.updatedAt: now,
            WorkOrderMaterialTable.syncStatus: 'pending',
          });
          materialByItem[itemId] = {
            WorkOrderMaterialTable.id: materialId,
            WorkOrderMaterialTable.itemId: itemId,
            WorkOrderMaterialTable.actualQuantity: entry.value,
            WorkOrderMaterialTable.unitCostAtUse: cost,
          };
        } else {
          await txn.update(
            WorkOrderMaterialTable.tableName,
            {
              WorkOrderMaterialTable.actualQuantity: entry.value,
              WorkOrderMaterialTable.updatedAt: now,
              WorkOrderMaterialTable.syncStatus: 'pending',
            },
            where: '${WorkOrderMaterialTable.id} = ?',
            whereArgs: [existing[WorkOrderMaterialTable.id]],
          );
          materialByItem[itemId] = {
            ...existing,
            WorkOrderMaterialTable.actualQuantity: entry.value,
          };
        }
      }

      for (final entry in materialByItem.entries) {
        final target = requestedByItem[entry.key] ?? 0;
        final material = entry.value;
        await txn.update(
          WorkOrderMaterialTable.tableName,
          {
            WorkOrderMaterialTable.actualQuantity: target,
            WorkOrderMaterialTable.updatedAt: now,
            WorkOrderMaterialTable.syncStatus: 'pending',
          },
          where: '${WorkOrderMaterialTable.id} = ?',
          whereArgs: [material[WorkOrderMaterialTable.id]],
        );
        await _reconcileMaterialStock(
          txn,
          material: material,
          targetQuantity: target,
          now: now,
        );
      }

      await txn.update(
        WorkOrderTaskTable.tableName,
        {
          WorkOrderTaskTable.result: result.toDbString(),
          WorkOrderTaskTable.findings: findings,
          WorkOrderTaskTable.laborMinutes: laborMinutes,
          WorkOrderTaskTable.downtimeMinutes: downtimeMinutes,
          WorkOrderTaskTable.updatedAt: now,
          WorkOrderTaskTable.syncStatus: 'pending',
        },
        where: '${WorkOrderTaskTable.id} = ?',
        whereArgs: [taskId],
      );
      final after = await _taskSnapshot(txn, taskId);
      await _insertTaskEvent(
        txn,
        taskId: taskId,
        eventType: 'COMPLETION_CORRECTED',
        reason: normalizedReason,
        before: before,
        after: after,
        now: now,
      );
    });
  }

  Future<List<WorkOrder>> getWorkOrders(
    String facilityId, {
    WorkOrderStatus? status,
    WorkOrderType? type,
  }) async {
    final db = await _dbHelper.db;
    var where =
        '${WorkOrderTable.facilityId} = ? AND ${WorkOrderTable.deletedAt} IS NULL';
    var args = <dynamic>[facilityId];

    if (status != null) {
      where += ' AND ${WorkOrderTable.status} = ?';
      args.add(status.toDbString());
    }
    if (type != null) {
      where += ' AND ${WorkOrderTable.workOrderType} = ?';
      args.add(type.toDbString());
    }

    final results = await db.query(
      _tableName,
      where: where,
      whereArgs: args,
      orderBy: '${WorkOrderTable.createdAt} DESC',
    );
    return results.map((m) => WorkOrder.fromMap(m)).toList();
  }

  Future<WorkOrder?> getWorkOrderById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where: '${WorkOrderTable.id} = ? AND ${WorkOrderTable.deletedAt} IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return WorkOrder.fromMap(results.first);
  }

  Future<List<WorkOrderTask>> getTasksForWorkOrder(String workOrderId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      WorkOrderTaskTable.tableName,
      where:
          '${WorkOrderTaskTable.workOrderId} = ? AND ${WorkOrderTaskTable.deletedAt} IS NULL',
      whereArgs: [workOrderId],
    );
    return results.map((m) => WorkOrderTask.fromMap(m)).toList();
  }

  Future<List<WorkOrderTask>> getTasksForAsset(String assetId) async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery(
      '''
        SELECT task.*
        FROM ${WorkOrderTaskTable.tableName} AS task
        INNER JOIN ${WorkOrderTable.tableName} AS work_order
          ON work_order.${WorkOrderTable.id} = task.${WorkOrderTaskTable.workOrderId}
        WHERE task.${WorkOrderTaskTable.assetId} = ?
          AND task.${WorkOrderTaskTable.deletedAt} IS NULL
          AND work_order.${WorkOrderTable.deletedAt} IS NULL
        ORDER BY task.${WorkOrderTaskTable.completedAt} DESC,
          task.${WorkOrderTaskTable.createdAt} DESC
      ''',
      [assetId],
    );
    return results.map((row) => WorkOrderTask.fromMap(row)).toList();
  }

  Future<List<WorkOrderTask>> getTasksForMaintenancePlan(
    String maintenancePlanId,
  ) async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery(
      '''
        SELECT task.*
        FROM ${WorkOrderTaskTable.tableName} AS task
        INNER JOIN ${WorkOrderTable.tableName} AS work_order
          ON work_order.${WorkOrderTable.id} = task.${WorkOrderTaskTable.workOrderId}
        WHERE task.${WorkOrderTaskTable.maintenancePlanId} = ?
          AND task.${WorkOrderTaskTable.deletedAt} IS NULL
          AND work_order.${WorkOrderTable.deletedAt} IS NULL
        ORDER BY task.${WorkOrderTaskTable.completedAt} DESC,
          task.${WorkOrderTaskTable.createdAt} DESC
      ''',
      [maintenancePlanId],
    );
    return results.map((row) => WorkOrderTask.fromMap(row)).toList();
  }

  Future<List<WorkOrderMaterial>> getMaterialsForTask(String taskId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      WorkOrderMaterialTable.tableName,
      where:
          '${WorkOrderMaterialTable.workOrderTaskId} = ? AND ${WorkOrderMaterialTable.deletedAt} IS NULL',
      whereArgs: [taskId],
    );
    return results.map((m) => WorkOrderMaterial.fromMap(m)).toList();
  }

  Future<WorkOrder> createWorkOrder({
    required String facilityId,
    required String title,
    String? description,
    required WorkOrderType workOrderType,
    Priority priority = Priority.medium,
    String? scheduledAt,
    String? notes,
    List<Map<String, dynamic>>? initialTasks, // assetId, title, activityType
  }) async {
    final db = await _dbHelper.db;
    final id = IdGenerator.generate();
    final now = AppDateUtils.nowUtcIso();
    final woNumber =
        'WO-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

    final workOrder = WorkOrder(
      id: id,
      facilityId: facilityId,
      workOrderNumber: woNumber,
      title: title,
      description: description,
      workOrderType: workOrderType,
      priority: priority,
      status: WorkOrderStatus.open,
      scheduledAt: scheduledAt,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert(_tableName, workOrder.toMap());

      if (initialTasks != null) {
        for (final t in initialTasks) {
          await txn.insert(WorkOrderTaskTable.tableName, {
            WorkOrderTaskTable.id: IdGenerator.generate(),
            WorkOrderTaskTable.workOrderId: id,
            WorkOrderTaskTable.assetId: t['asset_id'],
            WorkOrderTaskTable.title: t['title'],
            WorkOrderTaskTable.description: t['description'],
            WorkOrderTaskTable.activityType: t['activity_type'] ?? 'INSPECTION',
            WorkOrderTaskTable.status: 'PENDING',
            WorkOrderTaskTable.createdAt: now,
            WorkOrderTaskTable.updatedAt: now,
            WorkOrderTaskTable.syncStatus: 'pending',
          });
        }
      }
    });

    return workOrder;
  }

  Future<WorkOrder> updateWorkOrder(WorkOrder order) async {
    final db = await _dbHelper.db;
    final updated = order.copyWith(updatedAt: AppDateUtils.nowUtcIso());
    await db.update(
      _tableName,
      updated.toMap(),
      where: '${WorkOrderTable.id} = ?',
      whereArgs: [order.id],
    );
    return updated;
  }

  Future<void> updateWorkOrderStatus(
    String workOrderId,
    WorkOrderStatus newStatus,
  ) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();
    final updates = <String, dynamic>{
      WorkOrderTable.status: newStatus.toDbString(),
      WorkOrderTable.updatedAt: nowIso,
    };
    if (newStatus == WorkOrderStatus.completed) {
      updates[WorkOrderTable.completedAt] = nowIso;
      updates[WorkOrderTable.closedAt] = nowIso;
    } else if (newStatus == WorkOrderStatus.inProgress) {
      updates[WorkOrderTable.startedAt] = nowIso;
    }

    await db.update(
      _tableName,
      updates,
      where: '${WorkOrderTable.id} = ?',
      whereArgs: [workOrderId],
    );
  }

  Future<void> addTaskToWorkOrder({
    required String workOrderId,
    required String assetId,
    String? maintenancePlanId,
    required String title,
    String? description,
    ActivityType activityType = ActivityType.inspection,
    String? plannedDueAt,
  }) async {
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    double? plannedMeterValue;
    await db.transaction((txn) async {
      if (maintenancePlanId != null) {
        final plans = await txn.query(
          MaintenancePlanTable.tableName,
          where:
              '${MaintenancePlanTable.id} = ? AND ${MaintenancePlanTable.deletedAt} IS NULL',
          whereArgs: [maintenancePlanId],
          limit: 1,
        );
        if (plans.isEmpty ||
            plans.first[MaintenancePlanTable.assetId] != assetId) {
          throw ArgumentError(
            'برنامه نگهداری انتخاب‌شده به تجهیز وظیفه مرتبط نیست.',
          );
        }
        if (plans.first[MaintenancePlanTable.scheduleType] == 'METER') {
          plannedMeterValue =
              (plans.first[MaintenancePlanTable.nextDueMeterValue] as num?)
                  ?.toDouble();
          if (plannedMeterValue == null || !plannedMeterValue!.isFinite) {
            throw StateError('مقدار هدف کارکرد برنامه معتبر نیست.');
          }
        }
      }
      final taskId = IdGenerator.generate();
      await txn.insert(WorkOrderTaskTable.tableName, {
        WorkOrderTaskTable.id: taskId,
        WorkOrderTaskTable.workOrderId: workOrderId,
        WorkOrderTaskTable.assetId: assetId,
        WorkOrderTaskTable.maintenancePlanId: maintenancePlanId,
        WorkOrderTaskTable.title: title,
        WorkOrderTaskTable.description: description,
        WorkOrderTaskTable.activityType: activityType.toDbString(),
        WorkOrderTaskTable.status: 'PENDING',
        WorkOrderTaskTable.plannedDueAt: plannedDueAt,
        WorkOrderTaskTable.plannedMeterValue: plannedMeterValue,
        WorkOrderTaskTable.createdAt: now,
        WorkOrderTaskTable.updatedAt: now,
        WorkOrderTaskTable.syncStatus: 'pending',
      });
      if (maintenancePlanId != null) {
        await MaintenancePlanMaterialSeeder.seedTaskMaterials(
          txn,
          planId: maintenancePlanId,
          taskId: taskId,
          now: now,
        );
      }
    });
  }

  Future<void> addMaterialToTask({
    required String workOrderTaskId,
    required String itemId,
    double? plannedQuantity,
    double? actualQuantity,
    double? unitCostAtUse,
    String? notes,
  }) async {
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    for (final value in [plannedQuantity, actualQuantity, unitCostAtUse]) {
      if (value != null && (!value.isFinite || value < 0)) {
        throw ArgumentError(
          'مقادیر متریال باید عددی معتبر و صفر یا بزرگ‌تر باشند.',
        );
      }
    }

    await db.transaction((txn) async {
      final taskRows = await txn.query(
        WorkOrderTaskTable.tableName,
        columns: [WorkOrderTaskTable.status],
        where:
            '${WorkOrderTaskTable.id} = ? AND ${WorkOrderTaskTable.deletedAt} IS NULL',
        whereArgs: [workOrderTaskId],
        limit: 1,
      );
      if (taskRows.isEmpty) throw ArgumentError('وظیفه یافت نشد.');
      final taskStatus = taskRows.first[WorkOrderTaskTable.status];
      if (taskStatus != 'PENDING' && taskStatus != 'IN_PROGRESS') {
        throw StateError(
          'برای وظیفه تکمیل‌شده یا لغوشده نمی‌توان متریال ثبت کرد.',
        );
      }

      final itemRows = await txn.query(
        InventoryItemTable.tableName,
        columns: [InventoryItemTable.defaultUnitCost],
        where:
            '${InventoryItemTable.id} = ? AND ${InventoryItemTable.deletedAt} IS NULL AND ${InventoryItemTable.isActive} = 1',
        whereArgs: [itemId],
        limit: 1,
      );
      if (itemRows.isEmpty) {
        throw ArgumentError('کالای انتخاب‌شده موجود یا فعال نیست.');
      }

      final existingRows = await txn.query(
        WorkOrderMaterialTable.tableName,
        columns: [WorkOrderMaterialTable.id],
        where:
            '${WorkOrderMaterialTable.workOrderTaskId} = ? AND ${WorkOrderMaterialTable.itemId} = ? AND ${WorkOrderMaterialTable.deletedAt} IS NULL',
        whereArgs: [workOrderTaskId, itemId],
        limit: 1,
      );
      if (existingRows.isNotEmpty) {
        throw StateError('این کالا قبلاً به همین وظیفه افزوده شده است.');
      }

      final resolvedUnitCost =
          unitCostAtUse ??
          (actualQuantity != null
              ? (itemRows.first[InventoryItemTable.defaultUnitCost] as num?)
                    ?.toDouble()
              : null);
      await txn.insert(WorkOrderMaterialTable.tableName, {
        WorkOrderMaterialTable.id: IdGenerator.generate(),
        WorkOrderMaterialTable.workOrderTaskId: workOrderTaskId,
        WorkOrderMaterialTable.itemId: itemId,
        WorkOrderMaterialTable.plannedQuantity: plannedQuantity,
        WorkOrderMaterialTable.actualQuantity: actualQuantity,
        WorkOrderMaterialTable.unitCostAtUse: resolvedUnitCost,
        WorkOrderMaterialTable.notes: notes,
        WorkOrderMaterialTable.createdAt: now,
        WorkOrderMaterialTable.updatedAt: now,
        WorkOrderMaterialTable.syncStatus: 'pending',
      });
    });
  }

  Future<void> completeTask({
    required String taskId,
    required TaskResult result,
    required String? findings,
    required int? laborMinutes,
    required int? downtimeMinutes,
    List<Map<String, dynamic>>? consumedMaterials, // itemId, quantity, unitCost
    double? completionMeterValue,
  }) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();

    await db.transaction((txn) async {
      // 1. Fetch task
      final taskMaps = await txn.query(
        WorkOrderTaskTable.tableName,
        where: '${WorkOrderTaskTable.id} = ?',
        whereArgs: [taskId],
        limit: 1,
      );
      if (taskMaps.isEmpty) throw ArgumentError('وظیفه یافت نشد.');
      final task = WorkOrderTask.fromMap(taskMaps.first);
      if (task.status != TaskStatus.pending &&
          task.status != TaskStatus.inProgress) {
        throw StateError('این وظیفه قبلاً تکمیل یا لغو شده است.');
      }
      MaintenancePlan? meterPlan;
      if (task.maintenancePlanId != null) {
        final planRows = await txn.query(
          MaintenancePlanTable.tableName,
          where: '${MaintenancePlanTable.id} = ?',
          whereArgs: [task.maintenancePlanId],
          limit: 1,
        );
        if (planRows.isNotEmpty) {
          final plan = MaintenancePlan.fromMap(planRows.single);
          if (plan.scheduleType == ScheduleType.meter) {
            meterPlan = plan;
            if (completionMeterValue == null ||
                !completionMeterValue.isFinite ||
                completionMeterValue < 0 ||
                completionMeterValue < (task.plannedMeterValue ?? 0)) {
              throw ArgumentError(
                'مقدار نهایی کارکرد باید معتبر و حداقل به‌اندازه مقدار هدف باشد.',
              );
            }
            final latestMeterRows = await txn.query(
              AssetReadingTable.tableName,
              columns: [
                AssetReadingTable.value,
                AssetReadingTable.metricName,
                AssetReadingTable.recordedAt,
              ],
              where:
                  '${AssetReadingTable.assetId} = ? AND LOWER(${AssetReadingTable.metricName}) = LOWER(?) AND LOWER(${AssetReadingTable.unit}) = LOWER(?) AND ${AssetReadingTable.deletedAt} IS NULL AND ${AssetReadingTable.supersededByReadingId} IS NULL',
              whereArgs: [task.assetId, plan.meterName, plan.meterUnit],
              orderBy:
                  '${AssetReadingTable.recordedAt} DESC, ${AssetReadingTable.createdAt} DESC, rowid DESC',
              limit: 1,
            );
            if (latestMeterRows.isNotEmpty &&
                completionMeterValue <
                    (latestMeterRows.single[AssetReadingTable.value] as num)) {
              throw ArgumentError('خوانش نهایی از آخرین خوانش کنتور کمتر است.');
            }
            if (latestMeterRows.isNotEmpty) {
              final latestMeterTime = DateTime.tryParse(
                latestMeterRows.single[AssetReadingTable.recordedAt] as String,
              );
              final completionTime = DateTime.parse(nowIso);
              if (latestMeterTime != null &&
                  completionTime.isBefore(latestMeterTime)) {
                throw ArgumentError(
                  'زمان تکمیل نمی‌تواند پیش از آخرین خوانش کنتور باشد.',
                );
              }
            }
          }
        }
      }
      if (completionMeterValue != null && meterPlan == null) {
        throw ArgumentError('این وظیفه برنامه زمان‌بندی بر اساس کارکرد ندارد.');
      }
      if (task.plannedMeterValue != null && meterPlan == null) {
        throw StateError('برنامه کارکرد مرتبط با این وظیفه پیدا نشد.');
      }
      final before = await _taskSnapshot(txn, taskId);
      final latestEvents = await txn.query(
        WorkOrderTaskEventTable.tableName,
        columns: [WorkOrderTaskEventTable.eventType],
        where: '${WorkOrderTaskEventTable.workOrderTaskId} = ?',
        whereArgs: [taskId],
        orderBy: '${WorkOrderTaskEventTable.createdAt} DESC, rowid DESC',
        limit: 1,
      );
      final isReopened =
          latestEvents.isNotEmpty &&
          latestEvents.first[WorkOrderTaskEventTable.eventType] == 'REOPENED';

      // 2. Save additional actual quantities, then post all usage atomically.
      final incomingByItem = <String, Map<String, dynamic>>{};
      if (consumedMaterials != null) {
        for (final mat in consumedMaterials) {
          final itemId = mat['item_id'] as String;
          final qtyValue = mat['quantity'];
          if (qtyValue is! num ||
              !qtyValue.toDouble().isFinite ||
              qtyValue <= 0) {
            throw ArgumentError('مقدار مصرف باید عددی بزرگ‌تر از صفر باشد.');
          }
          if (incomingByItem.containsKey(itemId)) {
            throw ArgumentError(
              'یک کالا در فهرست مصرفی بیش از یک بار انتخاب شده است.',
            );
          }
          incomingByItem[itemId] = mat;
        }
      }

      for (final entry in incomingByItem.entries) {
        final itemId = entry.key;
        final material = entry.value;
        var qty = (material['quantity'] as num).toDouble();
        final itemRows = await txn.query(
          InventoryItemTable.tableName,
          columns: [InventoryItemTable.defaultUnitCost],
          where:
              '${InventoryItemTable.id} = ? AND ${InventoryItemTable.deletedAt} IS NULL AND ${InventoryItemTable.isActive} = 1',
          whereArgs: [itemId],
          limit: 1,
        );
        if (itemRows.isEmpty) {
          throw ArgumentError('کالای انتخاب‌شده موجود یا فعال نیست.');
        }
        final cost =
            (material['unit_cost'] as num?)?.toDouble() ??
            (itemRows.first[InventoryItemTable.defaultUnitCost] as num?)
                ?.toDouble();
        if (cost != null && (!cost.isFinite || cost < 0)) {
          throw ArgumentError(
            'بهای واحد باید عددی معتبر و صفر یا بزرگ‌تر باشد.',
          );
        }

        final existingRows = await txn.query(
          WorkOrderMaterialTable.tableName,
          columns: [
            WorkOrderMaterialTable.id,
            WorkOrderMaterialTable.actualQuantity,
          ],
          where:
              '${WorkOrderMaterialTable.workOrderTaskId} = ? AND ${WorkOrderMaterialTable.itemId} = ? AND ${WorkOrderMaterialTable.deletedAt} IS NULL',
          whereArgs: [taskId, itemId],
          limit: 1,
        );
        if (isReopened && existingRows.isNotEmpty) {
          qty +=
              (existingRows.first[WorkOrderMaterialTable.actualQuantity]
                      as num?)
                  ?.toDouble() ??
              0;
        }
        if (existingRows.isEmpty) {
          await txn.insert(WorkOrderMaterialTable.tableName, {
            WorkOrderMaterialTable.id: IdGenerator.generate(),
            WorkOrderMaterialTable.workOrderTaskId: taskId,
            WorkOrderMaterialTable.itemId: itemId,
            WorkOrderMaterialTable.actualQuantity: qty,
            WorkOrderMaterialTable.unitCostAtUse: cost,
            WorkOrderMaterialTable.createdAt: nowIso,
            WorkOrderMaterialTable.updatedAt: nowIso,
            WorkOrderMaterialTable.syncStatus: 'pending',
          });
        } else {
          await txn.update(
            WorkOrderMaterialTable.tableName,
            {
              WorkOrderMaterialTable.actualQuantity: qty,
              WorkOrderMaterialTable.unitCostAtUse: cost,
              WorkOrderMaterialTable.updatedAt: nowIso,
              WorkOrderMaterialTable.syncStatus: 'pending',
            },
            where: '${WorkOrderMaterialTable.id} = ?',
            whereArgs: [existingRows.first[WorkOrderMaterialTable.id]],
          );
        }
      }

      final actualMaterials = await txn.query(
        WorkOrderMaterialTable.tableName,
        where:
            '${WorkOrderMaterialTable.workOrderTaskId} = ? AND ${WorkOrderMaterialTable.actualQuantity} > 0 AND ${WorkOrderMaterialTable.deletedAt} IS NULL',
        whereArgs: [taskId],
      );
      for (final material in actualMaterials) {
        final qty = (material[WorkOrderMaterialTable.actualQuantity] as num)
            .toDouble();
        await _reconcileMaterialStock(
          txn,
          material: material,
          targetQuantity: qty,
          now: nowIso,
        );
      }

      // 3. Update task status
      await txn.update(
        WorkOrderTaskTable.tableName,
        {
          WorkOrderTaskTable.status: 'COMPLETED',
          WorkOrderTaskTable.result: result.toDbString(),
          WorkOrderTaskTable.findings: findings,
          WorkOrderTaskTable.laborMinutes: laborMinutes,
          WorkOrderTaskTable.downtimeMinutes: downtimeMinutes,
          WorkOrderTaskTable.completionMeterValue: completionMeterValue,
          WorkOrderTaskTable.completionMeterName: meterPlan?.meterName,
          WorkOrderTaskTable.completionMeterUnit: meterPlan?.meterUnit,
          WorkOrderTaskTable.completedAt: nowIso,
          WorkOrderTaskTable.updatedAt: nowIso,
        },
        where: '${WorkOrderTaskTable.id} = ?',
        whereArgs: [taskId],
      );
      final after = await _taskSnapshot(txn, taskId);
      await _insertTaskEvent(
        txn,
        taskId: taskId,
        eventType: 'COMPLETED',
        before: before,
        after: after,
        now: nowIso,
      );
      await txn.update(
        AlertEventTable.tableName,
        {
          AlertEventTable.status: 'RESOLVED',
          AlertEventTable.resolvedAt: nowIso,
          AlertEventTable.updatedAt: nowIso,
          AlertEventTable.syncStatus: 'pending',
        },
        where:
            '${AlertEventTable.workOrderTaskId} = ? AND ${AlertEventTable.status} IN (?, ?) AND ${AlertEventTable.deletedAt} IS NULL',
        whereArgs: [taskId, 'ACTIVE', 'ACKNOWLEDGED'],
      );

      // 4. If task came from maintenance plan, update plan schedule
      if (task.maintenancePlanId != null) {
        final planMaps = await txn.query(
          MaintenancePlanTable.tableName,
          where:
              '${MaintenancePlanTable.id} = ? AND ${MaintenancePlanTable.deletedAt} IS NULL',
          whereArgs: [task.maintenancePlanId],
          limit: 1,
        );
        if (planMaps.isNotEmpty) {
          final plan = MaintenancePlan.fromMap(planMaps.first);
          final planUpdates = <String, Object?>{
            MaintenancePlanTable.lastCompletedAt: nowIso,
            MaintenancePlanTable.updatedAt: nowIso,
            MaintenancePlanTable.syncStatus: 'pending',
          };
          if (plan.scheduleType == ScheduleType.calendar &&
              plan.calendarIntervalValue != null &&
              plan.calendarIntervalUnit != null) {
            final nextDue = AppDateUtils.toUtcIso(
              AppDateUtils.addCalendarInterval(
                DateTime.now(),
                plan.calendarIntervalValue!,
                plan.calendarIntervalUnit!.toDbString(),
              ),
            );
            planUpdates[MaintenancePlanTable.nextDueAt] = nextDue;
          } else if (plan.scheduleType == ScheduleType.meter &&
              completionMeterValue != null &&
              plan.meterInterval != null) {
            final latestCompletionReading = await txn.query(
              AssetReadingTable.tableName,
              columns: [AssetReadingTable.id],
              where:
                  '${AssetReadingTable.assetId} = ? AND LOWER(${AssetReadingTable.metricName}) = LOWER(?) AND LOWER(${AssetReadingTable.unit}) = LOWER(?) AND ${AssetReadingTable.value} = ? AND ${AssetReadingTable.recordedAt} = ? AND ${AssetReadingTable.deletedAt} IS NULL AND ${AssetReadingTable.supersededByReadingId} IS NULL',
              whereArgs: [
                task.assetId,
                plan.meterName,
                plan.meterUnit,
                completionMeterValue,
                nowIso,
              ],
              limit: 1,
            );
            if (latestCompletionReading.isEmpty) {
              final completionReading = AssetReading(
                id: IdGenerator.generate(),
                assetId: task.assetId,
                metricName: plan.meterName!,
                value: completionMeterValue,
                unit: plan.meterUnit!,
                recordedAt: nowIso,
                notes: 'خوانش ثبت‌شده هنگام تکمیل وظیفه ${task.title}',
                createdAt: nowIso,
                updatedAt: nowIso,
              );
              await txn.insert(
                AssetReadingTable.tableName,
                completionReading.toMap(),
              );
            }
            planUpdates[MaintenancePlanTable.lastCompletedMeterValue] =
                completionMeterValue;
            planUpdates[MaintenancePlanTable.nextDueMeterValue] =
                completionMeterValue + plan.meterInterval!;
          }
          await txn.update(
            MaintenancePlanTable.tableName,
            planUpdates,
            where: '${MaintenancePlanTable.id} = ?',
            whereArgs: [plan.id],
          );
        }
      }

      // 5. Check if work order can be completed (if all tasks are completed)
      final remainingTasks = await txn.query(
        WorkOrderTaskTable.tableName,
        where:
            '${WorkOrderTaskTable.workOrderId} = ? AND ${WorkOrderTaskTable.status} NOT IN (?, ?) AND ${WorkOrderTaskTable.deletedAt} IS NULL',
        whereArgs: [task.workOrderId, 'COMPLETED', 'CANCELLED'],
      );

      if (remainingTasks.isEmpty) {
        await txn.update(
          _tableName,
          {
            WorkOrderTable.status: 'COMPLETED',
            WorkOrderTable.completedAt: nowIso,
            WorkOrderTable.updatedAt: nowIso,
          },
          where: '${WorkOrderTable.id} = ?',
          whereArgs: [task.workOrderId],
        );
      }
    });
  }

  Future<void> closeWorkOrder(String workOrderId) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();

    // Verify no open tasks remain
    final openTasks = await db.query(
      WorkOrderTaskTable.tableName,
      where:
          '${WorkOrderTaskTable.workOrderId} = ? AND ${WorkOrderTaskTable.status} NOT IN (?, ?, ?) AND ${WorkOrderTaskTable.deletedAt} IS NULL',
      whereArgs: [workOrderId, 'COMPLETED', 'SKIPPED', 'CANCELLED'],
    );

    if (openTasks.isNotEmpty) {
      throw StateError(
        'امکان بستن دستورکار وجود ندارد چون دارای وظایف باز است.',
      );
    }

    await db.update(
      _tableName,
      {
        WorkOrderTable.status: 'COMPLETED',
        WorkOrderTable.closedAt: nowIso,
        WorkOrderTable.completedAt: nowIso,
        WorkOrderTable.updatedAt: nowIso,
      },
      where: '${WorkOrderTable.id} = ?',
      whereArgs: [workOrderId],
    );
  }
}
