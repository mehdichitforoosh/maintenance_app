import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/purchase_order_item_table.dart';
import '../../../core/storage/database/tables/purchase_order_table.dart';
import '../../../core/storage/database/tables/stock_transaction_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';

class PurchaseRepository {
  static const String _tableName = PurchaseOrderTable.tableName;
  final DatabaseHelper _dbHelper;

  PurchaseRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<PurchaseOrder>> getPurchaseOrders(String facilityId, {PurchaseOrderStatus? status}) async {
    final db = await _dbHelper.db;
    var where = '${PurchaseOrderTable.facilityId} = ? AND ${PurchaseOrderTable.deletedAt} IS NULL';
    var args = <dynamic>[facilityId];

    if (status != null) {
      where += ' AND ${PurchaseOrderTable.status} = ?';
      args.add(status.toDbString());
    }

    final results = await db.query(_tableName, where: where, whereArgs: args, orderBy: '${PurchaseOrderTable.orderDate} DESC');
    return results.map((m) => PurchaseOrder.fromMap(m)).toList();
  }

  Future<PurchaseOrder?> getPurchaseOrderById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(_tableName, where: '${PurchaseOrderTable.id} = ? AND ${PurchaseOrderTable.deletedAt} IS NULL', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return PurchaseOrder.fromMap(results.first);
  }

  Future<List<PurchaseOrderItem>> getOrderItems(String purchaseOrderId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      PurchaseOrderItemTable.tableName,
      where: '${PurchaseOrderItemTable.purchaseOrderId} = ? AND ${PurchaseOrderItemTable.deletedAt} IS NULL',
      whereArgs: [purchaseOrderId],
    );
    return results.map((m) => PurchaseOrderItem.fromMap(m)).toList();
  }

  Future<PurchaseOrder> createPurchaseOrder({
    required String facilityId,
    required String supplierName,
    required String orderDate,
    String? expectedDate,
    String? notes,
    required List<Map<String, dynamic>> items, // itemId, orderedQuantity, unitPrice
  }) async {
    final db = await _dbHelper.db;
    final id = IdGenerator.generate();
    final now = AppDateUtils.nowUtcIso();
    final poNumber = 'PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

    final order = PurchaseOrder(
      id: id,
      facilityId: facilityId,
      purchaseOrderNumber: poNumber,
      supplierName: supplierName,
      orderDate: orderDate,
      expectedDate: expectedDate,
      status: PurchaseOrderStatus.ordered,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert(_tableName, order.toMap());
      for (final item in items) {
        await txn.insert(PurchaseOrderItemTable.tableName, {
          PurchaseOrderItemTable.id: IdGenerator.generate(),
          PurchaseOrderItemTable.purchaseOrderId: id,
          PurchaseOrderItemTable.itemId: item['item_id'],
          PurchaseOrderItemTable.orderedQuantity: item['ordered_quantity'],
          PurchaseOrderItemTable.unitPrice: item['unit_price'],
          PurchaseOrderItemTable.notes: item['notes'],
          PurchaseOrderItemTable.createdAt: now,
          PurchaseOrderItemTable.updatedAt: now,
          PurchaseOrderItemTable.syncStatus: 'pending',
        });
      }
    });

    return order;
  }

  Future<PurchaseOrder> updatePurchaseOrder(PurchaseOrder order) async {
    final db = await _dbHelper.db;
    final updated = order.copyWith(updatedAt: AppDateUtils.nowUtcIso());
    await db.update(
      _tableName,
      updated.toMap(),
      where: '${PurchaseOrderTable.id} = ?',
      whereArgs: [order.id],
    );
    return updated;
  }

  Future<void> receiveItems({
    required String purchaseOrderId,
    required List<Map<String, dynamic>> receivedLines, // purchaseOrderItemId, receivedQuantity
  }) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();

    await db.transaction((txn) async {
      for (final line in receivedLines) {
        final poiId = line['purchase_order_item_id'] as String;
        final qty = (line['received_quantity'] as num).toDouble();
        if (qty <= 0) continue;

        // Fetch PO item
        final poiMaps = await txn.query(PurchaseOrderItemTable.tableName, where: '${PurchaseOrderItemTable.id} = ?', whereArgs: [poiId], limit: 1);
        if (poiMaps.isEmpty) continue;
        final poi = PurchaseOrderItem.fromMap(poiMaps.first);

        // Check already received quantity
        final recRes = await txn.rawQuery('''
          SELECT COALESCE(SUM(${StockTransactionTable.quantity}), 0) as total_received
          FROM ${StockTransactionTable.tableName}
          WHERE ${StockTransactionTable.purchaseOrderItemId} = ? AND ${StockTransactionTable.deletedAt} IS NULL
        ''', [poiId]);
        final totalReceived = (recRes.first['total_received'] as num).toDouble();
        final remaining = poi.orderedQuantity - totalReceived;

        if (qty > remaining) {
          throw StateError('مقدار دریافتی بیشتر از مقدار سفارش‌داده شده باقی‌مانده است.');
        }

        // Insert stock transaction (PURCHASE_RECEIPT)
        await txn.insert(StockTransactionTable.tableName, {
          StockTransactionTable.id: IdGenerator.generate(),
          StockTransactionTable.itemId: poi.itemId,
          StockTransactionTable.transactionType: 'PURCHASE_RECEIPT',
          StockTransactionTable.quantity: qty,
          StockTransactionTable.unitCost: poi.unitPrice,
          StockTransactionTable.transactionDate: nowIso,
          StockTransactionTable.purchaseOrderItemId: poiId,
          StockTransactionTable.createdAt: nowIso,
          StockTransactionTable.updatedAt: nowIso,
          StockTransactionTable.syncStatus: 'pending',
        });
      }

      // Re-calculate PO status (RECEIVED or PARTIALLY_RECEIVED)
      final items = await txn.query(PurchaseOrderItemTable.tableName, where: '${PurchaseOrderItemTable.purchaseOrderId} = ? AND ${PurchaseOrderItemTable.deletedAt} IS NULL', whereArgs: [purchaseOrderId]);
      bool allFullyReceived = true;
      bool anyReceived = false;

      for (final item in items) {
        final poiId = item[PurchaseOrderItemTable.id] as String;
        final ordered = (item[PurchaseOrderItemTable.orderedQuantity] as num).toDouble();

        final recRes = await txn.rawQuery('''
          SELECT COALESCE(SUM(${StockTransactionTable.quantity}), 0) as total_received
          FROM ${StockTransactionTable.tableName}
          WHERE ${StockTransactionTable.purchaseOrderItemId} = ? AND ${StockTransactionTable.deletedAt} IS NULL
        ''', [poiId]);
        final received = (recRes.first['total_received'] as num).toDouble();

        if (received > 0) anyReceived = true;
        if (received < ordered) allFullyReceived = false;
      }

      final newStatus = allFullyReceived
          ? 'RECEIVED'
          : (anyReceived ? 'PARTIALLY_RECEIVED' : 'ORDERED');

      await txn.update(
        _tableName,
        {
          PurchaseOrderTable.status: newStatus,
          PurchaseOrderTable.updatedAt: nowIso,
        },
        where: '${PurchaseOrderTable.id} = ?',
        whereArgs: [purchaseOrderId],
      );
    });
  }
}
