import '../../../core/storage/database/database_helper.dart';

class DashboardRepository {
  final DatabaseHelper _dbHelper;

  DashboardRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Map<String, int>> getSummaryCounts(String facilityId) async {
    final db = await _dbHelper.db;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // 1. Due today tasks
    final dueTodayRes = await db.rawQuery('''
      SELECT COUNT(t.id) as count
      FROM work_order_tasks t
      JOIN work_orders w ON t.work_order_id = w.id
      WHERE w.facility_id = ? AND t.status = 'PENDING' AND t.planned_due_at LIKE ? AND t.deleted_at IS NULL AND w.deleted_at IS NULL
    ''', [facilityId, '$todayStr%']);
    final dueToday = (dueTodayRes.first['count'] as num).toInt();

    // 2. Overdue tasks
    final overdueRes = await db.rawQuery('''
      SELECT COUNT(t.id) as count
      FROM work_order_tasks t
      JOIN work_orders w ON t.work_order_id = w.id
      WHERE w.facility_id = ? AND t.status = 'PENDING' AND t.planned_due_at < ? AND t.deleted_at IS NULL AND w.deleted_at IS NULL
    ''', [facilityId, todayStr]);
    final overdue = (overdueRes.first['count'] as num).toInt();

    // 3. Open work orders
    final openWoRes = await db.rawQuery('''
      SELECT COUNT(id) as count
      FROM work_orders
      WHERE facility_id = ? AND status IN ('OPEN', 'IN_PROGRESS', 'ON_HOLD') AND deleted_at IS NULL
    ''', [facilityId]);
    final openWorkOrders = (openWoRes.first['count'] as num).toInt();

    // 4. Low-stock items
    final items = await db.rawQuery('''
      SELECT i.id, i.minimum_stock,
      COALESCE((
        SELECT SUM(
          CASE 
            WHEN transaction_type IN ('PURCHASE_RECEIPT', 'ADJUSTMENT_IN', 'RETURN') THEN quantity
            WHEN transaction_type IN ('MAINTENANCE_CONSUMPTION', 'ADJUSTMENT_OUT') THEN -quantity
            ELSE 0 
          END
        ) FROM stock_transactions WHERE item_id = i.id AND deleted_at IS NULL
      ), 0) as current_stock
      FROM inventory_items i
      WHERE i.is_active = 1 AND i.deleted_at IS NULL
    ''');
    int lowStockCount = 0;
    for (final row in items) {
      final minStock = (row['minimum_stock'] as num).toDouble();
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

  Future<List<Map<String, dynamic>>> getTodayTasks(String facilityId) async {
    final db = await _dbHelper.db;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final results = await db.rawQuery('''
      SELECT t.*, a.name as asset_name, w.work_order_number
      FROM work_order_tasks t
      JOIN work_orders w ON t.work_order_id = w.id
      JOIN assets a ON t.asset_id = a.id
      WHERE w.facility_id = ? AND t.status = 'PENDING' AND t.planned_due_at LIKE ? AND t.deleted_at IS NULL AND w.deleted_at IS NULL
    ''', [facilityId, '$todayStr%']);
    return results;
  }
}
