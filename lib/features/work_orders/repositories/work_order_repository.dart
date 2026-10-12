import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/work_order.dart';
import '../models/work_order_material.dart';
import '../models/work_order_task.dart';
import '../../maintenance/models/maintenance_plan.dart';

class WorkOrderRepository {
  final DatabaseHelper _dbHelper;

  WorkOrderRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<WorkOrder>> getWorkOrders(String facilityId, {WorkOrderStatus? status, WorkOrderType? type}) async {
    final db = await _dbHelper.db;
    var where = 'facility_id = ? AND deleted_at IS NULL';
    var args = <dynamic>[facilityId];

    if (status != null) {
      where += ' AND status = ?';
      args.add(status.toDbString());
    }
    if (type != null) {
      where += ' AND work_order_type = ?';
      args.add(type.toDbString());
    }

    final results = await db.query(
      'work_orders',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return results.map((m) => WorkOrder.fromMap(m)).toList();
  }

  Future<WorkOrder?> getWorkOrderById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'work_orders',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return WorkOrder.fromMap(results.first);
  }

  Future<List<WorkOrderTask>> getTasksForWorkOrder(String workOrderId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'work_order_tasks',
      where: 'work_order_id = ? AND deleted_at IS NULL',
      whereArgs: [workOrderId],
    );
    return results.map((m) => WorkOrderTask.fromMap(m)).toList();
  }

  Future<List<WorkOrderMaterial>> getMaterialsForTask(String taskId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'work_order_materials',
      where: 'work_order_task_id = ? AND deleted_at IS NULL',
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
      await txn.insert('work_orders', workOrder.toMap());

      if (initialTasks != null) {
        for (final t in initialTasks) {
          await txn.insert('work_order_tasks', {
            'id': IdGenerator.generate(),
            'work_order_id': id,
            'asset_id': t['asset_id'],
            'title': t['title'],
            'description': t['description'],
            'activity_type': t['activity_type'] ?? 'INSPECTION',
            'status': 'PENDING',
            'created_at': now,
            'updated_at': now,
            'sync_status': 'pending',
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
      'work_orders',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
    return updated;
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
    await db.insert('work_order_tasks', {
      'id': IdGenerator.generate(),
      'work_order_id': workOrderId,
      'asset_id': assetId,
      'title': title,
      'description': description,
      'activity_type': activityType.toDbString(),
      'status': 'PENDING',
      'planned_due_at': plannedDueAt,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
    });
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
      final taskMaps = await txn.query('work_order_tasks', where: 'id = ?', whereArgs: [taskId], limit: 1);
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
                WHEN transaction_type IN ('PURCHASE_RECEIPT', 'ADJUSTMENT_IN', 'RETURN') THEN quantity
                WHEN transaction_type IN ('MAINTENANCE_CONSUMPTION', 'ADJUSTMENT_OUT') THEN -quantity
                ELSE 0 
              END
            ), 0) as current_stock
            FROM stock_transactions
            WHERE item_id = ? AND deleted_at IS NULL
          ''', [itemId]);

          final currentStock = (stockRes.first['current_stock'] as num).toDouble();
          if (currentStock < qty) {
            throw StateError('موجودی انبار برای اقلام کافی نیست. موجودی فعلی: $currentStock، مقدار درخواستی: $qty');
          }

          // Insert work_order_material record
          final womId = IdGenerator.generate();
          await txn.insert('work_order_materials', {
            'id': womId,
            'work_order_task_id': taskId,
            'item_id': itemId,
            'actual_quantity': qty,
            'unit_cost_at_use': cost,
            'created_at': nowIso,
            'updated_at': nowIso,
            'sync_status': 'pending',
          });

          // Insert stock transaction (MAINTENANCE_CONSUMPTION)
          await txn.insert('stock_transactions', {
            'id': IdGenerator.generate(),
            'item_id': itemId,
            'transaction_type': 'MAINTENANCE_CONSUMPTION',
            'quantity': qty,
            'unit_cost': cost,
            'transaction_date': nowIso,
            'work_order_material_id': womId,
            'created_at': nowIso,
            'updated_at': nowIso,
            'sync_status': 'pending',
          });
        }
      }

      // 3. Update task status
      await txn.update(
        'work_order_tasks',
        {
          'status': 'COMPLETED',
          'result': result.toDbString(),
          'findings': findings,
          'labor_minutes': laborMinutes,
          'downtime_minutes': downtimeMinutes,
          'completed_at': nowIso,
          'updated_at': nowIso,
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );

      // 4. If task came from maintenance plan, update plan schedule
      if (task.maintenancePlanId != null) {
        final planMaps = await txn.query('maintenance_plans', where: 'id = ?', whereArgs: [task.maintenancePlanId], limit: 1);
        if (planMaps.isNotEmpty) {
          final plan = MaintenancePlan.fromMap(planMaps.first);
          if (plan.scheduleType == ScheduleType.calendar && plan.calendarIntervalValue != null && plan.calendarIntervalUnit != null) {
            final nextDue = AppDateUtils.toUtcIso(
              AppDateUtils.addCalendarInterval(DateTime.now(), plan.calendarIntervalValue!, plan.calendarIntervalUnit!.toDbString()),
            );
            await txn.update(
              'maintenance_plans',
              {
                'last_completed_at': nowIso,
                'next_due_at': nextDue,
                'updated_at': nowIso,
              },
              where: 'id = ?',
              whereArgs: [plan.id],
            );
          }
        }
      }

      // 5. Check if work order can be completed (if all tasks are completed)
      final remainingTasks = await txn.query(
        'work_order_tasks',
        where: 'work_order_id = ? AND status NOT IN (?, ?) AND deleted_at IS NULL',
        whereArgs: [task.workOrderId, 'COMPLETED', 'CANCELLED'],
      );

      if (remainingTasks.isEmpty) {
        await txn.update(
          'work_orders',
          {
            'status': 'COMPLETED',
            'completed_at': nowIso,
            'updated_at': nowIso,
          },
          where: 'id = ?',
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
      'work_order_tasks',
      where: 'work_order_id = ? AND status NOT IN (?, ?, ?) AND deleted_at IS NULL',
      whereArgs: [workOrderId, 'COMPLETED', 'SKIPPED', 'CANCELLED'],
    );

    if (openTasks.isNotEmpty) {
      throw StateError('امکان بستن دستورکار وجود ندارد چون دارای وظایف باز است.');
    }

    await db.update(
      'work_orders',
      {
        'status': 'COMPLETED',
        'closed_at': nowIso,
        'completed_at': nowIso,
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: [workOrderId],
    );
  }
}
