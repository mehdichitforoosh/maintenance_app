import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/inventory_item_table.dart';
import '../../../core/storage/database/tables/purchase_order_item_table.dart';
import '../../../core/storage/database/tables/purchase_order_table.dart';
import '../../../core/storage/database/tables/stock_transaction_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/number_format_utils.dart';
import '../models/inventory_item.dart';
import '../models/inventory_ledger_entry.dart';
import '../models/purchase_receipt_detail.dart';
import '../models/stock_transaction.dart';

class InventoryRepository {
  static const String _tableName = InventoryItemTable.tableName;
  final DatabaseHelper _dbHelper;

  InventoryRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<InventoryItem>> getItems({
    String? searchQuery,
    bool activeOnly = true,
  }) async {
    final db = await _dbHelper.db;
    var where = '${InventoryItemTable.deletedAt} IS NULL';
    var args = <dynamic>[];

    if (activeOnly) {
      where += ' AND ${InventoryItemTable.isActive} = 1';
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      where +=
          ' AND (${InventoryItemTable.name} LIKE ? OR ${InventoryItemTable.code} LIKE ?)';
      args.add('%${searchQuery.trim()}%');
      args.add('%${searchQuery.trim()}%');
    }

    final results = await db.query(
      _tableName,
      where: where,
      whereArgs: args,
      orderBy: '${InventoryItemTable.name} ASC',
    );
    return results.map((m) => InventoryItem.fromMap(m)).toList();
  }

  Future<InventoryItem?> getItemById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where:
          '${InventoryItemTable.id} = ? AND ${InventoryItemTable.deletedAt} IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return InventoryItem.fromMap(results.first);
  }

  Future<double> getCurrentStock(String itemId) async {
    final db = await _dbHelper.db;
    final res = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(
        CASE 
          WHEN ${StockTransactionTable.transactionType} IN ('PURCHASE_RECEIPT', 'ADJUSTMENT_IN', 'RETURN') THEN ${StockTransactionTable.quantity}
          WHEN ${StockTransactionTable.transactionType} IN ('MAINTENANCE_CONSUMPTION', 'ADJUSTMENT_OUT') THEN -${StockTransactionTable.quantity}
          ELSE 0 
        END
      ), 0) as current_stock
      FROM ${StockTransactionTable.tableName}
      WHERE ${StockTransactionTable.itemId} = ? AND ${StockTransactionTable.deletedAt} IS NULL
    ''',
      [itemId],
    );
    return (res.first['current_stock'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery('''
      SELECT i.*, 
      COALESCE((
        SELECT SUM(
          CASE 
            WHEN ${StockTransactionTable.transactionType} IN ('PURCHASE_RECEIPT', 'ADJUSTMENT_IN', 'RETURN') THEN ${StockTransactionTable.quantity}
            WHEN ${StockTransactionTable.transactionType} IN ('MAINTENANCE_CONSUMPTION', 'ADJUSTMENT_OUT') THEN -${StockTransactionTable.quantity}
            ELSE 0 
          END
        ) FROM ${StockTransactionTable.tableName} WHERE ${StockTransactionTable.itemId} = i.${InventoryItemTable.id} AND ${StockTransactionTable.deletedAt} IS NULL
      ), 0) as current_stock
      FROM $_tableName i
      WHERE i.${InventoryItemTable.isActive} = 1 AND i.${InventoryItemTable.deletedAt} IS NULL
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
    bool isActive = true,
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
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert(_tableName, item.toMap());
    return item;
  }

  Future<InventoryItem> updateItem(InventoryItem item) async {
    final db = await _dbHelper.db;
    final updated = item.copyWith(updatedAt: AppDateUtils.nowUtcIso());
    await db.update(
      _tableName,
      updated.toMap(),
      where: '${InventoryItemTable.id} = ?',
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
    if (type != TransactionType.adjustmentIn &&
        type != TransactionType.adjustmentOut) {
      throw ArgumentError('نوع تراکنش تعدیل نامعتبر است.');
    }

    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();

    await db.transaction((txn) async {
      if (type == TransactionType.adjustmentOut) {
        final stockRes = await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(
            CASE 
              WHEN ${StockTransactionTable.transactionType} IN ('PURCHASE_RECEIPT', 'ADJUSTMENT_IN', 'RETURN') THEN ${StockTransactionTable.quantity}
              WHEN ${StockTransactionTable.transactionType} IN ('MAINTENANCE_CONSUMPTION', 'ADJUSTMENT_OUT') THEN -${StockTransactionTable.quantity}
              ELSE 0 
            END
          ), 0) as current_stock
          FROM ${StockTransactionTable.tableName}
          WHERE ${StockTransactionTable.itemId} = ? AND ${StockTransactionTable.deletedAt} IS NULL
        ''',
          [itemId],
        );
        final currentStock = (stockRes.first['current_stock'] as num)
            .toDouble();
        if (currentStock < quantity) {
          throw StateError(
            'موجودی کافی برای خروج/تعدیل نیست. موجودی فعلی: ${AppNumberFormat.decimal(currentStock)}',
          );
        }
      }

      await txn.insert(StockTransactionTable.tableName, {
        StockTransactionTable.id: IdGenerator.generate(),
        StockTransactionTable.itemId: itemId,
        StockTransactionTable.transactionType: type.toDbString(),
        StockTransactionTable.quantity: quantity,
        StockTransactionTable.unitCost: unitCost,
        StockTransactionTable.transactionDate: nowIso,
        StockTransactionTable.notes: notes,
        StockTransactionTable.createdAt: nowIso,
        StockTransactionTable.updatedAt: nowIso,
        StockTransactionTable.syncStatus: 'pending',
      });
    });
  }

  Future<List<StockTransaction>> getStockTransactions(String itemId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      StockTransactionTable.tableName,
      where:
          '${StockTransactionTable.itemId} = ? AND ${StockTransactionTable.deletedAt} IS NULL',
      whereArgs: [itemId],
      orderBy: '${StockTransactionTable.transactionDate} DESC',
    );
    return results.map((m) => StockTransaction.fromMap(m)).toList();
  }

  Future<List<InventoryLedgerEntry>> getStockLedger({
    TransactionType? transactionType,
    String? itemId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (fromDate != null &&
        toDate != null &&
        DateTime(
          fromDate.year,
          fromDate.month,
          fromDate.day,
        ).isAfter(DateTime(toDate.year, toDate.month, toDate.day))) {
      throw ArgumentError('تاریخ شروع نمی‌تواند بعد از تاریخ پایان باشد.');
    }

    final db = await _dbHelper.db;
    final conditions = <String>[
      'st.${StockTransactionTable.deletedAt} IS NULL',
      'i.${InventoryItemTable.deletedAt} IS NULL',
    ];
    final args = <Object?>[];
    if (transactionType != null) {
      conditions.add('st.${StockTransactionTable.transactionType} = ?');
      args.add(transactionType.toDbString());
    }
    if (itemId != null) {
      conditions.add('st.${StockTransactionTable.itemId} = ?');
      args.add(itemId);
    }
    if (fromDate != null) {
      final localStart = DateTime(fromDate.year, fromDate.month, fromDate.day);
      conditions.add('st.${StockTransactionTable.transactionDate} >= ?');
      args.add(localStart.toUtc().toIso8601String());
    }
    if (toDate != null) {
      final localEndExclusive = DateTime(
        toDate.year,
        toDate.month,
        toDate.day,
      ).add(const Duration(days: 1));
      conditions.add('st.${StockTransactionTable.transactionDate} < ?');
      args.add(localEndExclusive.toUtc().toIso8601String());
    }

    final results = await db.rawQuery('''
      SELECT st.*,
        i.${InventoryItemTable.name} AS item_name,
        i.${InventoryItemTable.code} AS item_code,
        i.${InventoryItemTable.unit} AS item_unit
      FROM ${StockTransactionTable.tableName} st
      JOIN ${InventoryItemTable.tableName} i
        ON i.${InventoryItemTable.id} = st.${StockTransactionTable.itemId}
      WHERE ${conditions.join(' AND ')}
      ORDER BY st.${StockTransactionTable.transactionDate} DESC,
        st.${StockTransactionTable.createdAt} DESC
      ''', args);

    return results.map((row) {
      final transaction = StockTransaction.fromMap(row);
      return InventoryLedgerEntry(
        transaction: transaction,
        itemName: row['item_name'] as String,
        itemCode: row['item_code'] as String,
        unit: row['item_unit'] as String,
      );
    }).toList();
  }

  Future<PurchaseReceiptDetail?> getPurchaseReceiptDetail(
    String transactionId,
  ) async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery(
      '''
      SELECT
        st.${StockTransactionTable.id} AS transaction_id,
        st.${StockTransactionTable.itemId} AS item_id,
        st.${StockTransactionTable.quantity} AS quantity,
        st.${StockTransactionTable.unitCost} AS unit_cost,
        st.${StockTransactionTable.transactionDate} AS transaction_date,
        st.${StockTransactionTable.notes} AS notes,
        i.${InventoryItemTable.name} AS item_name,
        i.${InventoryItemTable.code} AS item_code,
        i.${InventoryItemTable.unit} AS unit,
        po.${PurchaseOrderTable.id} AS purchase_order_id,
        po.${PurchaseOrderTable.purchaseOrderNumber} AS purchase_order_number,
        po.${PurchaseOrderTable.supplierName} AS supplier_name
      FROM ${StockTransactionTable.tableName} st
      JOIN ${PurchaseOrderItemTable.tableName} poi
        ON poi.${PurchaseOrderItemTable.id} = st.${StockTransactionTable.purchaseOrderItemId}
      JOIN ${PurchaseOrderTable.tableName} po
        ON po.${PurchaseOrderTable.id} = poi.${PurchaseOrderItemTable.purchaseOrderId}
      JOIN ${InventoryItemTable.tableName} i
        ON i.${InventoryItemTable.id} = st.${StockTransactionTable.itemId}
      WHERE st.${StockTransactionTable.id} = ?
        AND st.${StockTransactionTable.transactionType} = 'PURCHASE_RECEIPT'
        AND st.${StockTransactionTable.deletedAt} IS NULL
      LIMIT 1
      ''',
      [transactionId],
    );
    if (results.isEmpty) return null;
    return PurchaseReceiptDetail.fromMap(results.first);
  }
}
