import 'package:sqflite/sqflite.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/alert_event_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../maintenance/services/maintenance_scheduler.dart';
import '../models/alert_event.dart';

class AlertRepository {
  static const String _tableName = AlertEventTable.tableName;
  final DatabaseHelper _dbHelper;

  AlertRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Reconciles all dynamic system alerts (due maintenance, low stock items, overdue work orders)
  Future<void> reconcileAlerts(String facilityId) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();

    // 1. Run Maintenance Scheduler for due calendar and one-time plans
    await MaintenanceScheduler.runScheduler(db, facilityId);

    // 2. Reconcile Low Stock Alerts
    final inventoryItems = await db.rawQuery('''
      SELECT i.id, i.name, i.unit, i.minimum_stock,
      COALESCE((
        SELECT SUM(
          CASE 
            WHEN t.transaction_type IN ('PURCHASE_RECEIPT', 'ADJUSTMENT_IN', 'RETURN') THEN t.quantity
            WHEN t.transaction_type IN ('MAINTENANCE_CONSUMPTION', 'ADJUSTMENT_OUT') THEN -t.quantity
            ELSE 0 
          END
        ) FROM stock_transactions t WHERE t.item_id = i.id AND t.deleted_at IS NULL
      ), 0) as calculated_stock
      FROM inventory_items i
      WHERE i.is_active = 1 AND i.deleted_at IS NULL
    ''');

    for (final row in inventoryItems) {
      final itemId = row['id'] as String;
      final itemName = row['name'] as String;
      final unit = row['unit'] as String;
      final minStock = (row['minimum_stock'] as num).toDouble();
      final calcStock = (row['calculated_stock'] as num).toDouble();
      final dedupKey = 'alert:low_stock:$itemId';

      if (calcStock <= minStock) {
        final severity = calcStock <= 0 ? 'CRITICAL' : 'WARNING';
        final messageText =
            'موجودی فعلی (${AppNumberFormat.decimal(calcStock)} $unit) از حداقل موجودی (${AppNumberFormat.decimal(minStock)} $unit) کمتر است.';
        final titleText = 'موجودی کم: $itemName';
        await db.update(
          _tableName,
          {
            AlertEventTable.severity: severity,
            AlertEventTable.message: messageText,
            AlertEventTable.updatedAt: nowIso,
            AlertEventTable.syncStatus: 'pending',
          },
          where:
              'deduplication_key = ? AND status IN (?, ?) AND deleted_at IS NULL',
          whereArgs: [dedupKey, 'ACTIVE', 'ACKNOWLEDGED'],
        );
        final alertId = IdGenerator.generate();
        await db.insert(_tableName, {
          AlertEventTable.id: alertId,
          AlertEventTable.facilityId: facilityId,
          AlertEventTable.alertType: 'LOW_STOCK',
          AlertEventTable.severity: severity,
          AlertEventTable.status: 'ACTIVE',
          AlertEventTable.title: titleText,
          AlertEventTable.message: messageText,
          AlertEventTable.inventoryItemId: itemId,
          AlertEventTable.deduplicationKey: dedupKey,
          AlertEventTable.triggeredAt: nowIso,
          AlertEventTable.createdAt: nowIso,
          AlertEventTable.updatedAt: nowIso,
          AlertEventTable.syncStatus: 'pending',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        // Automatically resolve active low-stock alert if stock is replenished above minimum
        await db.update(
          _tableName,
          {
            AlertEventTable.status: 'RESOLVED',
            AlertEventTable.resolvedAt: nowIso,
            AlertEventTable.updatedAt: nowIso,
            AlertEventTable.syncStatus: 'pending',
          },
          where:
              'deduplication_key = ? AND status IN (?, ?) AND deleted_at IS NULL',
          whereArgs: [dedupKey, 'ACTIVE', 'ACKNOWLEDGED'],
        );
      }
    }

    // 3. Reconcile Overdue Work Orders / Tasks
    final overdueTasks = await db.rawQuery(
      '''
      SELECT t.id, t.title, t.asset_id, t.maintenance_plan_id, wo.facility_id
      FROM work_order_tasks t
      INNER JOIN work_orders wo ON wo.id = t.work_order_id
      WHERE wo.facility_id = ?
        AND t.planned_due_at IS NOT NULL
        AND t.planned_due_at < ?
        AND t.status IN ('PENDING', 'IN_PROGRESS')
        AND t.deleted_at IS NULL
        AND wo.deleted_at IS NULL
    ''',
      [facilityId, nowIso],
    );

    for (final row in overdueTasks) {
      final taskId = row['id'] as String;
      final title = row['title'] as String;
      final assetId = row['asset_id'] as String?;
      final planId = row['maintenance_plan_id'] as String?;
      final dedupKey = 'alert:overdue_task:$taskId';

      final titleText = 'عقب‌افتادگی دستورکار: $title';
      final messageText =  'زمان سررسید این دستورکار/وظیفه به پایان رسیده است.';

      await db.insert(_tableName, {
        AlertEventTable.id: IdGenerator.generate(),
        AlertEventTable.facilityId: facilityId,
        AlertEventTable.alertType: 'WORK_ORDER_OVERDUE',
        AlertEventTable.severity: 'CRITICAL',
        AlertEventTable.status: 'ACTIVE',
        AlertEventTable.title: titleText,
        AlertEventTable.message: messageText,
        AlertEventTable.assetId: assetId,
        AlertEventTable.maintenancePlanId: planId,
        AlertEventTable.workOrderTaskId: taskId,
        AlertEventTable.deduplicationKey: dedupKey,
        AlertEventTable.triggeredAt: nowIso,
        AlertEventTable.createdAt: nowIso,
        AlertEventTable.updatedAt: nowIso,
        AlertEventTable.syncStatus: 'pending',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<AlertEvent>> reconcileAndGetAlerts(
    String facilityId, {
    AlertStatus? status,
    AlertSeverity? severity,
  }) async {
    await reconcileAlerts(facilityId);
    return getAlerts(facilityId, status: status, severity: severity);
  }

  Future<List<AlertEvent>> getAlerts(
    String facilityId, {
    AlertStatus? status,
    AlertSeverity? severity,
  }) async {
    final db = await _dbHelper.db;
    var where =
        '${AlertEventTable.facilityId} = ? AND ${AlertEventTable.deletedAt} IS NULL';
    var args = <dynamic>[facilityId];

    if (status != null) {
      where += ' AND ${AlertEventTable.status} = ?';
      args.add(status.toDbString());
    }
    if (severity != null) {
      where += ' AND ${AlertEventTable.severity} = ?';
      args.add(severity.toDbString());
    }

    final results = await db.query(
      _tableName,
      where: where,
      whereArgs: args,
      orderBy: '${AlertEventTable.triggeredAt} DESC',
    );
    return results.map((m) => AlertEvent.fromMap(m)).toList();
  }

  Future<void> updateAlertStatus(String alertId, AlertStatus newStatus) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();
    final updates = <String, dynamic>{
      AlertEventTable.status: newStatus.toDbString(),
      AlertEventTable.updatedAt: nowIso,
    };
    if (newStatus == AlertStatus.acknowledged) {
      updates[AlertEventTable.acknowledgedAt] = nowIso;
    } else if (newStatus == AlertStatus.resolved) {
      updates[AlertEventTable.resolvedAt] = nowIso;
    }

    await db.update(
      _tableName,
      updates,
      where: '${AlertEventTable.id} = ?',
      whereArgs: [alertId],
    );
  }
}
