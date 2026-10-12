import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';

class PurchaseRepository {
  final DatabaseHelper _dbHelper;

  PurchaseRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<PurchaseOrder>> getPurchaseOrders(String facilityId, {PurchaseOrderStatus? status}) async {
    final db = await _dbHelper.db;
    var where = 'facility_id = ? AND deleted_at IS NULL';
    var args = <dynamic>[facilityId];

    if (status != null) {
      where += ' AND status = ?';
      args.add(status.toDbString());
    }

    final results = await db.query('purchase_orders', where: where, whereArgs: args, orderBy: 'order_date DESC');
    return results.map((m) => PurchaseOrder.fromMap(m)).toList();
  }

  Future<PurchaseOrder?> getPurchaseOrderById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query('purchase_orders', where: 'id = ? AND deleted_at IS NULL', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return PurchaseOrder.fromMap(results.first);
  }

  Future<List<PurchaseOrderItem>> getOrderItems(String purchaseOrderId) async {
    final db = await _dbHelper.db;
    final results = await db.query('purchase_order_items', where: 'purchase_order_id = ? AND deleted_at IS NULL', whereArgs: [purchaseOrderId]);
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
      await txn.insert('purchase_orders', order.toMap());
      for (final item in items) {
        await txn.insert('purchase_order_items', {
          'id': IdGenerator.generate(),
          'purchase_order_id': id,
          'item_id': item['item_id'],
          'ordered_quantity': item['ordered_quantity'],
          'unit_price': item['unit_price'],
          'notes': item['notes'],
          'created_at': now,
          'updated_at': now,
          'sync_status': 'pending',
        });
      }
    });

    return order;
  }

  Future<PurchaseOrder> updatePurchaseOrder(PurchaseOrder order) async {
    final db = await _dbHelper.db;
    final updated = order.copyWith(updatedAt: AppDateUtils.nowUtcIso());
    await db.update(
      'purchase_orders',
      updated.toMap(),
      where: 'id = ?',
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
        final poiMaps = await txn.query('purchase_order_items', where: 'id = ?', whereArgs: [poiId], limit: 1);
        if (poiMaps.isEmpty) continue;
        final poi = PurchaseOrderItem.fromMap(poiMaps.first);

        // Check already received quantity
        final recRes = await txn.rawQuery('''
          SELECT COALESCE(SUM(quantity), 0) as total_received
          FROM stock_transactions
          WHERE purchase_order_item_id = ? AND deleted_at IS NULL
        ''', [poiId]);
        final totalReceived = (recRes.first['total_received'] as num).toDouble();
        final remaining = poi.orderedQuantity - totalReceived;

        if (qty > remaining) {
          throw StateError('مقدار دریافتی بیشتر از مقدار سفارش‌داده شده باقی‌مانده است.');
        }

        // Insert stock transaction (PURCHASE_RECEIPT)
        await txn.insert('stock_transactions', {
          'id': IdGenerator.generate(),
          'item_id': poi.itemId,
          'transaction_type': 'PURCHASE_RECEIPT',
          'quantity': qty,
          'unit_cost': poi.unitPrice,
          'transaction_date': nowIso,
          'purchase_order_item_id': poiId,
          'created_at': nowIso,
          'updated_at': nowIso,
          'sync_status': 'pending',
        });
      }

      // Re-calculate PO status (RECEIVED or PARTIALLY_RECEIVED)
      final items = await txn.query('purchase_order_items', where: 'purchase_order_id = ? AND deleted_at IS NULL', whereArgs: [purchaseOrderId]);
      bool allFullyReceived = true;
      bool anyReceived = false;

      for (final item in items) {
        final poiId = item['id'] as String;
        final ordered = (item['ordered_quantity'] as num).toDouble();

        final recRes = await txn.rawQuery('''
          SELECT COALESCE(SUM(quantity), 0) as total_received
          FROM stock_transactions
          WHERE purchase_order_item_id = ? AND deleted_at IS NULL
        ''', [poiId]);
        final received = (recRes.first['total_received'] as num).toDouble();

        if (received > 0) anyReceived = true;
        if (received < ordered) allFullyReceived = false;
      }

      final newStatus = allFullyReceived
          ? 'RECEIVED'
          : (anyReceived ? 'PARTIALLY_RECEIVED' : 'ORDERED');

      await txn.update(
        'purchase_orders',
        {'status': newStatus, 'updated_at': nowIso},
        where: 'id = ?',
        whereArgs: [purchaseOrderId],
      );
    });
  }
}
