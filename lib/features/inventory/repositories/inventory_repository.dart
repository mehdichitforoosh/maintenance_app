import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/inventory_item.dart';
import '../models/stock_transaction.dart';

class InventoryRepository {
  final DatabaseHelper _dbHelper;

  InventoryRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<InventoryItem>> getItems({String? searchQuery, bool activeOnly = true}) async {
    final db = await _dbHelper.db;
    var where = 'deleted_at IS NULL';
    var args = <dynamic>[];

    if (activeOnly) {
      where += ' AND is_active = 1';
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      where += ' AND (name LIKE ? OR code LIKE ?)';
      args.add('%${searchQuery.trim()}%');
      args.add('%${searchQuery.trim()}%');
    }

    final results = await db.query('inventory_items', where: where, whereArgs: args, orderBy: 'name ASC');
    return results.map((m) => InventoryItem.fromMap(m)).toList();
  }

  Future<InventoryItem?> getItemById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query('inventory_items', where: 'id = ? AND deleted_at IS NULL', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return InventoryItem.fromMap(results.first);
  }

  Future<double> getCurrentStock(String itemId) async {
    final db = await _dbHelper.db;
    final res = await db.rawQuery('''
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
    return (res.first['current_stock'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery('''
      SELECT i.*, 
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

    final lowStock = <Map<String, dynamic>>[];
    for (final row in results) {
      final item = InventoryItem.fromMap(row);
      final stock = (row['current_stock'] as num).toDouble();
      if (stock <= item.minimumStock) {
        lowStock.add({...row, 'calculated_stock': stock});
      }
    }
    return lowStock;
  }

  Future<InventoryItem> createItem({
    required String name,
    required String code,
    ItemType itemType = ItemType.consumable,
    required String unit,
    String? description,
    double minimumStock = 0.0,
    double? defaultUnitCost,
  }) async {
    final db = await _dbHelper.db;
    final id = IdGenerator.generate();
    final now = AppDateUtils.nowUtcIso();

    final item = InventoryItem(
      id: id,
      name: name,
      code: code,
      itemType: itemType,
      unit: unit,
      description: description,
      minimumStock: minimumStock,
      defaultUnitCost: defaultUnitCost,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('inventory_items', item.toMap());
    return item;
  }

  Future<InventoryItem> updateItem(InventoryItem item) async {
    final db = await _dbHelper.db;
    final updated = item.copyWith(updatedAt: AppDateUtils.nowUtcIso());
    await db.update(
      'inventory_items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    return updated;
  }

  Future<void> adjustStock({
    required String itemId,
    required TransactionType type,
    required double quantity,
    double? unitCost,
    String? notes,
  }) async {
    if (type != TransactionType.adjustmentIn && type != TransactionType.adjustmentOut) {
      throw ArgumentError('نوع تراکنش تعدیل نامعتبر است.');
    }

    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();

    await db.transaction((txn) async {
      if (type == TransactionType.adjustmentOut) {
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
        if (currentStock < quantity) {
          throw StateError('موجودی کافی برای خروج/تعدیل نیست. موجودی فعلی: $currentStock');
        }
      }

      await txn.insert('stock_transactions', {
        'id': IdGenerator.generate(),
        'item_id': itemId,
        'transaction_type': type.toDbString(),
        'quantity': quantity,
        'unit_cost': unitCost,
        'transaction_date': nowIso,
        'notes': notes,
        'created_at': nowIso,
        'updated_at': nowIso,
        'sync_status': 'pending',
      });
    });
  }

  Future<List<StockTransaction>> getStockTransactions(String itemId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'stock_transactions',
      where: 'item_id = ? AND deleted_at IS NULL',
      whereArgs: [itemId],
      orderBy: 'transaction_date DESC',
    );
    return results.map((m) => StockTransaction.fromMap(m)).toList();
  }
}
