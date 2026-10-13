import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/asset_table.dart';
import '../../../core/storage/database/tables/inventory_item_table.dart';
import '../../../core/storage/database/tables/stock_transaction_table.dart';
import '../../../core/storage/database/tables/work_order_table.dart';
import '../../../core/storage/database/tables/work_order_task_table.dart';

class DashboardRepository {
  final DatabaseHelper _dbHelper;

  DashboardRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Map<String, int>> getSummaryCounts(String facilityId) async {
    final db = await _dbHelper.db;
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
