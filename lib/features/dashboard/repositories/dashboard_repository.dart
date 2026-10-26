import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/asset_table.dart';
import '../../../core/storage/database/tables/inventory_item_table.dart';
import '../../../core/storage/database/tables/stock_transaction_table.dart';
import '../../../core/storage/database/tables/work_order_material_table.dart';
import '../../../core/storage/database/tables/work_order_table.dart';
import '../../../core/storage/database/tables/work_order_task_table.dart';
import '../../maintenance/services/maintenance_scheduler.dart';

class DashboardRepository {
  final DatabaseHelper _dbHelper;

  DashboardRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Map<String, int>> getSummaryCounts(String facilityId) async {
    final db = await _dbHelper.db;
    await MaintenanceScheduler.runScheduler(db, facilityId);

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // 1. Due today tasks
    final dueTodayRes = await db.rawQuery('''
      SELECT COUNT(t.${WorkOrderTaskTable.id}) as count
      FROM ${WorkOrderTaskTable.tableName} t
      JOIN ${WorkOrderTable.tableName} w ON t.${WorkOrderTaskTable.workOrderId} = w.${WorkOrderTable.id}
      WHERE w.${WorkOrderTable.facilityId} = ? AND t.${WorkOrderTaskTable.status} = 'PENDING' AND t.${WorkOrderTaskTable.plannedDueAt} LIKE ? AND t.${WorkOrderTaskTable.deletedAt} IS NULL AND w.${WorkOrderTable.deletedAt} IS NULL
    ''', [facilityId, '$todayStr%']);
    final dueToday = (dueTodayRes.first['count'] as num).toInt();

    // 2. Overdue tasks
    final overdueRes = await db.rawQuery('''
      SELECT COUNT(t.${WorkOrderTaskTable.id}) as count
      FROM ${WorkOrderTaskTable.tableName} t
      JOIN ${WorkOrderTable.tableName} w ON t.${WorkOrderTaskTable.workOrderId} = w.${WorkOrderTable.id}
      WHERE w.${WorkOrderTable.facilityId} = ? AND t.${WorkOrderTaskTable.status} = 'PENDING' AND t.${WorkOrderTaskTable.plannedDueAt} < ? AND t.${WorkOrderTaskTable.deletedAt} IS NULL AND w.${WorkOrderTable.deletedAt} IS NULL
    ''', [facilityId, todayStr]);
    final overdue = (overdueRes.first['count'] as num).toInt();

    // 3. Open work orders
    final openWoRes = await db.rawQuery('''
      SELECT COUNT(${WorkOrderTable.id}) as count
      FROM ${WorkOrderTable.tableName}
      WHERE ${WorkOrderTable.facilityId} = ? AND ${WorkOrderTable.status} IN ('OPEN', 'IN_PROGRESS', 'ON_HOLD') AND ${WorkOrderTable.deletedAt} IS NULL
    ''', [facilityId]);
    final openWorkOrders = (openWoRes.first['count'] as num).toInt();

    // 4. Low-stock items
    final items = await db.rawQuery('''
      SELECT i.${InventoryItemTable.id}, i.${InventoryItemTable.minimumStock},
      COALESCE((
        SELECT SUM(
          CASE 
            WHEN ${StockTransactionTable.transactionType} IN ('PURCHASE_RECEIPT', 'ADJUSTMENT_IN', 'RETURN') THEN ${StockTransactionTable.quantity}
            WHEN ${StockTransactionTable.transactionType} IN ('MAINTENANCE_CONSUMPTION', 'ADJUSTMENT_OUT') THEN -${StockTransactionTable.quantity}
            ELSE 0 
          END
        ) FROM ${StockTransactionTable.tableName} WHERE ${StockTransactionTable.itemId} = i.${InventoryItemTable.id} AND ${StockTransactionTable.deletedAt} IS NULL
      ), 0) as current_stock
      FROM ${InventoryItemTable.tableName} i
      WHERE i.${InventoryItemTable.isActive} = 1 AND i.${InventoryItemTable.deletedAt} IS NULL
    ''');
    int lowStockCount = 0;
    for (final row in items) {
      final minStock = (row[InventoryItemTable.minimumStock] as num).toDouble();
      final currStock = (row['current_stock'] as num).toDouble();
      if (currStock <= minStock) {
        lowStockCount++;
      }
    }

    return {
      'due_today': dueToday,
      'overdue': overdue,
      'open_work_orders': openWorkOrders,
      'low_stock': lowStockCount,
    };
  }

  Future<Map<String, int>> getWorkOrderStatusDistribution(String facilityId) async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery('''
      SELECT ${WorkOrderTable.status}, COUNT(*) as count
      FROM ${WorkOrderTable.tableName}
      WHERE ${WorkOrderTable.facilityId} = ? AND ${WorkOrderTable.deletedAt} IS NULL
      GROUP BY ${WorkOrderTable.status}
    ''', [facilityId]);

    final map = <String, int>{};
    for (final r in results) {
      map[r[WorkOrderTable.status] as String] = (r['count'] as num).toInt();
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> getCompletedTaskTrend(String facilityId, {int days = 7}) async {
    final db = await _dbHelper.db;
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    final startDay = start.toIso8601String().substring(0, 10);
    final endDay = end.toIso8601String().substring(0, 10);

    final results = await db.rawQuery('''
      WITH RECURSIVE day_series(day) AS (
        SELECT ?
        UNION ALL
        SELECT date(day, '+1 day')
        FROM day_series
        WHERE day < ?
      )
      SELECT d.day AS day_label,
             COALESCE(COUNT(t.${WorkOrderTaskTable.id}), 0) AS task_count
      FROM day_series d
      LEFT JOIN ${WorkOrderTaskTable.tableName} t
        ON date(t.${WorkOrderTaskTable.completedAt}) = d.day
       AND t.${WorkOrderTaskTable.status} = 'COMPLETED'
       AND t.${WorkOrderTaskTable.deletedAt} IS NULL
      LEFT JOIN ${WorkOrderTable.tableName} w
        ON w.${WorkOrderTable.id} = t.${WorkOrderTaskTable.workOrderId}
       AND w.${WorkOrderTable.facilityId} = ?
       AND w.${WorkOrderTable.deletedAt} IS NULL
      GROUP BY d.day
      ORDER BY d.day ASC
    ''', [startDay, endDay, facilityId]);

    return results
        .map((row) => {
              'day': row['day_label'] as String,
              'count': (row['task_count'] as num?)?.toInt() ?? 0,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMaterialConsumptionTrend(String facilityId, {int days = 7}) async {
    final db = await _dbHelper.db;
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    final startDay = start.toIso8601String().substring(0, 10);
    final endDay = end.toIso8601String().substring(0, 10);

    final results = await db.rawQuery('''
      WITH RECURSIVE day_series(day) AS (
        SELECT ?
        UNION ALL
        SELECT date(day, '+1 day')
        FROM day_series
        WHERE day < ?
      )
      SELECT d.day AS day_label,
             COALESCE(SUM(st.${StockTransactionTable.quantity}), 0) AS consumed_qty
      FROM day_series d
      LEFT JOIN ${StockTransactionTable.tableName} st
        ON date(st.${StockTransactionTable.transactionDate}) = d.day
       AND st.${StockTransactionTable.transactionType} = 'MAINTENANCE_CONSUMPTION'
       AND st.${StockTransactionTable.deletedAt} IS NULL
      LEFT JOIN ${WorkOrderMaterialTable.tableName} wom
        ON wom.${WorkOrderMaterialTable.id} = st.${StockTransactionTable.workOrderMaterialId}
       AND wom.${WorkOrderMaterialTable.deletedAt} IS NULL
      LEFT JOIN ${WorkOrderTaskTable.tableName} wt
        ON wt.${WorkOrderTaskTable.id} = wom.${WorkOrderMaterialTable.workOrderTaskId}
       AND wt.${WorkOrderTaskTable.deletedAt} IS NULL
      LEFT JOIN ${WorkOrderTable.tableName} w
        ON w.${WorkOrderTable.id} = wt.${WorkOrderTaskTable.workOrderId}
       AND w.${WorkOrderTable.facilityId} = ?
       AND w.${WorkOrderTable.deletedAt} IS NULL
      GROUP BY d.day
      ORDER BY d.day ASC
    ''', [startDay, endDay, facilityId]);

    return results
        .map((row) => {
              'day': row['day_label'] as String,
              'quantity': (row['consumed_qty'] as num?)?.toDouble() ?? 0.0,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTopConsumedMaterials(String facilityId, {int limit = 5}) async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery('''
      SELECT i.${InventoryItemTable.name},
             i.${InventoryItemTable.unit},
             SUM(st.${StockTransactionTable.quantity}) AS total_qty
      FROM ${StockTransactionTable.tableName} st
      JOIN ${WorkOrderMaterialTable.tableName} wom
        ON wom.${WorkOrderMaterialTable.id} = st.${StockTransactionTable.workOrderMaterialId}
       AND wom.${WorkOrderMaterialTable.deletedAt} IS NULL
      JOIN ${InventoryItemTable.tableName} i
        ON i.${InventoryItemTable.id} = wom.${WorkOrderMaterialTable.itemId}
       AND i.${InventoryItemTable.deletedAt} IS NULL
      JOIN ${WorkOrderTaskTable.tableName} wt
        ON wt.${WorkOrderTaskTable.id} = wom.${WorkOrderMaterialTable.workOrderTaskId}
       AND wt.${WorkOrderTaskTable.deletedAt} IS NULL
      JOIN ${WorkOrderTable.tableName} w
        ON w.${WorkOrderTable.id} = wt.${WorkOrderTaskTable.workOrderId}
       AND w.${WorkOrderTable.facilityId} = ?
       AND w.${WorkOrderTable.deletedAt} IS NULL
      WHERE st.${StockTransactionTable.transactionType} = 'MAINTENANCE_CONSUMPTION'
        AND st.${StockTransactionTable.deletedAt} IS NULL
      GROUP BY i.${InventoryItemTable.id}, i.${InventoryItemTable.name}, i.${InventoryItemTable.unit}
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [facilityId, limit]);

    return results
        .map((row) => {
              'name': row[InventoryItemTable.name] as String,
              'unit': row[InventoryItemTable.unit] as String,
              'quantity': (row['total_qty'] as num?)?.toDouble() ?? 0.0,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTodayTasks(String facilityId) async {
    final db = await _dbHelper.db;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final results = await db.rawQuery('''
      SELECT t.*, a.${AssetTable.name} as asset_name, w.${WorkOrderTable.workOrderNumber}
      FROM ${WorkOrderTaskTable.tableName} t
      JOIN ${WorkOrderTable.tableName} w ON t.${WorkOrderTaskTable.workOrderId} = w.${WorkOrderTable.id}
      JOIN ${AssetTable.tableName} a ON t.${WorkOrderTaskTable.assetId} = a.${AssetTable.id}
      WHERE w.${WorkOrderTable.facilityId} = ? AND t.${WorkOrderTaskTable.status} = 'PENDING' AND t.${WorkOrderTaskTable.plannedDueAt} LIKE ? AND t.${WorkOrderTaskTable.deletedAt} IS NULL AND w.${WorkOrderTable.deletedAt} IS NULL
    ''', [facilityId, '$todayStr%']);
    return results;
  }
}
