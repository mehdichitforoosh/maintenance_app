import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/maintenance_plan_table.dart';
import '../../../core/storage/database/tables/stock_transaction_table.dart';
import '../../../core/storage/database/tables/work_order_material_table.dart';
import '../../../core/storage/database/tables/work_order_table.dart';
import '../../../core/storage/database/tables/work_order_task_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/work_order.dart';
import '../models/work_order_material.dart';
import '../models/work_order_task.dart';
import '../../maintenance/models/maintenance_plan.dart';

class WorkOrderRepository {
  static const String _tableName = WorkOrderTable.tableName;
  final DatabaseHelper _dbHelper;

  WorkOrderRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<WorkOrder>> getWorkOrders(String facilityId, {WorkOrderStatus? status, WorkOrderType? type}) async {
    final db = await _dbHelper.db;
    var where = '${WorkOrderTable.facilityId} = ? AND ${WorkOrderTable.deletedAt} IS NULL';
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
      where: '${WorkOrderTaskTable.workOrderId} = ? AND ${WorkOrderTaskTable.deletedAt} IS NULL',
      whereArgs: [workOrderId],
    );
    return results.map((m) => WorkOrderTask.fromMap(m)).toList();
  }

  Future<List<WorkOrderMaterial>> getMaterialsForTask(String taskId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      WorkOrderMaterialTable.tableName,
      where: '${WorkOrderMaterialTable.workOrderTaskId} = ? AND ${WorkOrderMaterialTable.deletedAt} IS NULL',
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
    final woNumber = 'WO-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

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

  Future<void> updateWorkOrderStatus(String workOrderId, WorkOrderStatus newStatus) async {
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
    required String title,
    String? description,
    ActivityType activityType = ActivityType.inspection,
    String? plannedDueAt,
  }) async {
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    await db.insert(WorkOrderTaskTable.tableName, {
      WorkOrderTaskTable.id: IdGenerator.generate(),
      WorkOrderTaskTable.workOrderId: workOrderId,
      WorkOrderTaskTable.assetId: assetId,
      WorkOrderTaskTable.title: title,
      WorkOrderTaskTable.description: description,
      WorkOrderTaskTable.activityType: activityType.toDbString(),
      WorkOrderTaskTable.status: 'PENDING',
      WorkOrderTaskTable.plannedDueAt: plannedDueAt,
      WorkOrderTaskTable.createdAt: now,
      WorkOrderTaskTable.updatedAt: now,
      WorkOrderTaskTable.syncStatus: 'pending',
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
    await db.insert(
      WorkOrderMaterialTable.tableName,
      {
        WorkOrderMaterialTable.id: IdGenerator.generate(),
        WorkOrderMaterialTable.workOrderTaskId: workOrderTaskId,
        WorkOrderMaterialTable.itemId: itemId,
        WorkOrderMaterialTable.plannedQuantity: plannedQuantity,
        WorkOrderMaterialTable.actualQuantity: actualQuantity,
        WorkOrderMaterialTable.unitCostAtUse: unitCostAtUse,
        WorkOrderMaterialTable.notes: notes,
        WorkOrderMaterialTable.createdAt: now,
        WorkOrderMaterialTable.updatedAt: now,
        WorkOrderMaterialTable.syncStatus: 'pending',
      },
    );
  }

  Future<void> completeTask({
    required String taskId,
    required TaskResult result,
    required String? findings,
    required int? laborMinutes,
    required int? downtimeMinutes,
    List<Map<String, dynamic>>? consumedMaterials, // itemId, quantity, unitCost
  }) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();

    await db.transaction((txn) async {
      // 1. Fetch task
      final taskMaps = await txn.query(WorkOrderTaskTable.tableName, where: '${WorkOrderTaskTable.id} = ?', whereArgs: [taskId], limit: 1);
      if (taskMaps.isEmpty) throw ArgumentError('وظیفه یافت نشد.');
      final task = WorkOrderTask.fromMap(taskMaps.first);

      // 2. Consume materials & check stock
      if (consumedMaterials != null) {
        for (final mat in consumedMaterials) {
          final itemId = mat['item_id'] as String;
          final qty = (mat['quantity'] as num).toDouble();
          final cost = (mat['unit_cost'] as num?)?.toDouble() ?? 0.0;

          // Check current stock
          final stockRes = await txn.rawQuery('''
            SELECT COALESCE(SUM(
              CASE 
                WHEN ${StockTransactionTable.transactionType} IN ('PURCHASE_RECEIPT', 'ADJUSTMENT_IN', 'RETURN') THEN ${StockTransactionTable.quantity}
                WHEN ${StockTransactionTable.transactionType} IN ('MAINTENANCE_CONSUMPTION', 'ADJUSTMENT_OUT') THEN -${StockTransactionTable.quantity}
                ELSE 0 
              END
            ), 0) as current_stock
            FROM ${StockTransactionTable.tableName}
            WHERE ${StockTransactionTable.itemId} = ? AND ${StockTransactionTable.deletedAt} IS NULL
          ''', [itemId]);

          final currentStock = (stockRes.first['current_stock'] as num).toDouble();
          if (currentStock < qty) {
            throw StateError('موجودی انبار برای اقلام کافی نیست. موجودی فعلی: $currentStock، مقدار درخواستی: $qty');
          }

          // Insert work_order_material record
          final womId = IdGenerator.generate();
          await txn.insert(WorkOrderMaterialTable.tableName, {
            WorkOrderMaterialTable.id: womId,
            WorkOrderMaterialTable.workOrderTaskId: taskId,
            WorkOrderMaterialTable.itemId: itemId,
            WorkOrderMaterialTable.actualQuantity: qty,
            WorkOrderMaterialTable.unitCostAtUse: cost,
            WorkOrderMaterialTable.createdAt: nowIso,
            WorkOrderMaterialTable.updatedAt: nowIso,
            WorkOrderMaterialTable.syncStatus: 'pending',
          });

          // Insert stock transaction (MAINTENANCE_CONSUMPTION)
          await txn.insert(StockTransactionTable.tableName, {
            StockTransactionTable.id: IdGenerator.generate(),
            StockTransactionTable.itemId: itemId,
            StockTransactionTable.transactionType: 'MAINTENANCE_CONSUMPTION',
            StockTransactionTable.quantity: qty,
            StockTransactionTable.unitCost: cost,
            StockTransactionTable.transactionDate: nowIso,
            StockTransactionTable.workOrderMaterialId: womId,
            StockTransactionTable.createdAt: nowIso,
            StockTransactionTable.updatedAt: nowIso,
            StockTransactionTable.syncStatus: 'pending',
          });
        }
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
          WorkOrderTaskTable.completedAt: nowIso,
          WorkOrderTaskTable.updatedAt: nowIso,
        },
        where: '${WorkOrderTaskTable.id} = ?',
        whereArgs: [taskId],
      );

      // 4. If task came from maintenance plan, update plan schedule
      if (task.maintenancePlanId != null) {
        final planMaps = await txn.query(MaintenancePlanTable.tableName, where: '${MaintenancePlanTable.id} = ?', whereArgs: [task.maintenancePlanId], limit: 1);
        if (planMaps.isNotEmpty) {
          final plan = MaintenancePlan.fromMap(planMaps.first);
          if (plan.scheduleType == ScheduleType.calendar && plan.calendarIntervalValue != null && plan.calendarIntervalUnit != null) {
            final nextDue = AppDateUtils.toUtcIso(
              AppDateUtils.addCalendarInterval(DateTime.now(), plan.calendarIntervalValue!, plan.calendarIntervalUnit!.toDbString()),
            );
            await txn.update(
              MaintenancePlanTable.tableName,
              {
                MaintenancePlanTable.lastCompletedAt: nowIso,
                MaintenancePlanTable.nextDueAt: nextDue,
                MaintenancePlanTable.updatedAt: nowIso,
              },
              where: '${MaintenancePlanTable.id} = ?',
              whereArgs: [plan.id],
            );
          }
        }
      }

      // 5. Check if work order can be completed (if all tasks are completed)
      final remainingTasks = await txn.query(
        WorkOrderTaskTable.tableName,
        where: '${WorkOrderTaskTable.workOrderId} = ? AND ${WorkOrderTaskTable.status} NOT IN (?, ?) AND ${WorkOrderTaskTable.deletedAt} IS NULL',
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
      where: '${WorkOrderTaskTable.workOrderId} = ? AND ${WorkOrderTaskTable.status} NOT IN (?, ?, ?) AND ${WorkOrderTaskTable.deletedAt} IS NULL',
      whereArgs: [workOrderId, 'COMPLETED', 'SKIPPED', 'CANCELLED'],
    );

    if (openTasks.isNotEmpty) {
      throw StateError('امکان بستن دستورکار وجود ندارد چون دارای وظایف باز است.');
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
