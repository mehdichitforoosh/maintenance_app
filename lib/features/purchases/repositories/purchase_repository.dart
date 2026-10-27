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

  PurchaseRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<PurchaseOrder>> getPurchaseOrders(
    String facilityId, {
    PurchaseOrderStatus? status,
  }) async {
    final db = await _dbHelper.db;
    var where =
        '${PurchaseOrderTable.facilityId} = ? AND ${PurchaseOrderTable.deletedAt} IS NULL';
    var args = <dynamic>[facilityId];

    if (status != null) {
      where += ' AND ${PurchaseOrderTable.status} = ?';
      args.add(status.toDbString());
    }

    final results = await db.query(
      _tableName,
      where: where,
      whereArgs: args,
      orderBy: '${PurchaseOrderTable.orderDate} DESC',
    );
    return results.map((m) => PurchaseOrder.fromMap(m)).toList();
  }

  Future<PurchaseOrder?> getPurchaseOrderById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where:
          '${PurchaseOrderTable.id} = ? AND ${PurchaseOrderTable.deletedAt} IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return PurchaseOrder.fromMap(results.first);
  }

  Future<List<String>> getSupplierNames(String facilityId) async {
    final db = await _dbHelper.db;
    final results = await db.rawQuery(
      '''
      SELECT DISTINCT TRIM(${PurchaseOrderTable.supplierName}) AS supplier_name
      FROM $_tableName
      WHERE ${PurchaseOrderTable.facilityId} = ?
        AND ${PurchaseOrderTable.deletedAt} IS NULL
        AND ${PurchaseOrderTable.supplierName} IS NOT NULL
        AND TRIM(${PurchaseOrderTable.supplierName}) != ''
      ORDER BY supplier_name COLLATE NOCASE
      ''',
      [facilityId],
    );
    return results
        .map((row) => row['supplier_name'] as String)
        .toList(growable: false);
  }

  Future<List<PurchaseOrderItem>> getOrderItems(String purchaseOrderId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      PurchaseOrderItemTable.tableName,
      where:
          '${PurchaseOrderItemTable.purchaseOrderId} = ? AND ${PurchaseOrderItemTable.deletedAt} IS NULL',
      whereArgs: [purchaseOrderId],
    );
    return results.map((m) => PurchaseOrderItem.fromMap(m)).toList();
  }

  Future<Map<String, double>> getReceivedQuantities(
    String purchaseOrderId,
  ) async {
    final db = await _dbHelper.db;
    final rows = await db.rawQuery(
      '''
      SELECT st.${StockTransactionTable.purchaseOrderItemId} AS order_item_id,
        COALESCE(SUM(st.${StockTransactionTable.quantity}), 0) AS received_quantity
      FROM ${StockTransactionTable.tableName} st
      JOIN ${PurchaseOrderItemTable.tableName} poi
        ON poi.${PurchaseOrderItemTable.id} = st.${StockTransactionTable.purchaseOrderItemId}
      WHERE poi.${PurchaseOrderItemTable.purchaseOrderId} = ?
        AND st.${StockTransactionTable.transactionType} = 'PURCHASE_RECEIPT'
        AND st.${StockTransactionTable.deletedAt} IS NULL
      GROUP BY st.${StockTransactionTable.purchaseOrderItemId}
      ''',
      [purchaseOrderId],
    );
    return {
      for (final row in rows)
        row['order_item_id'] as String: (row['received_quantity'] as num)
            .toDouble(),
    };
  }

  Future<PurchaseOrder> createPurchaseOrder({
    required String facilityId,
    required String supplierName,
    required String orderDate,
    String? expectedDate,
    String? notes,
    required List<Map<String, dynamic>>
    items, // itemId, orderedQuantity, unitPrice
  }) async {
    _validateOrderItems(items);
    final db = await _dbHelper.db;
    final id = IdGenerator.generate();
    final now = AppDateUtils.nowUtcIso();
    final poNumber =
        'PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

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

  Future<PurchaseOrder> updatePurchaseOrder({
    required PurchaseOrder order,
    required List<Map<String, dynamic>> items,
  }) async {
    _validateOrderItems(items);
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    final updated = order.copyWith(updatedAt: now);
    var savedStatus = updated.status;

    await db.transaction((txn) async {
      final orderRows = await txn.query(
        _tableName,
        columns: [PurchaseOrderTable.status],
        where:
            '${PurchaseOrderTable.id} = ? AND ${PurchaseOrderTable.deletedAt} IS NULL',
        whereArgs: [order.id],
        limit: 1,
      );
      if (orderRows.isEmpty) throw StateError('سفارش خرید یافت نشد.');
      final currentStatus = PurchaseOrderStatus.fromDbString(
        orderRows.first[PurchaseOrderTable.status] as String?,
      );
      final existingRows = await txn.query(
        PurchaseOrderItemTable.tableName,
        where: '${PurchaseOrderItemTable.purchaseOrderId} = ?',
        whereArgs: [order.id],
      );
      final receivedRows = await txn.rawQuery(
        '''
        SELECT st.${StockTransactionTable.purchaseOrderItemId} AS order_item_id,
          COALESCE(SUM(st.${StockTransactionTable.quantity}), 0) AS received_quantity
        FROM ${StockTransactionTable.tableName} st
        JOIN ${PurchaseOrderItemTable.tableName} poi
          ON poi.${PurchaseOrderItemTable.id} = st.${StockTransactionTable.purchaseOrderItemId}
        WHERE poi.${PurchaseOrderItemTable.purchaseOrderId} = ?
          AND st.${StockTransactionTable.transactionType} = 'PURCHASE_RECEIPT'
          AND st.${StockTransactionTable.deletedAt} IS NULL
        GROUP BY st.${StockTransactionTable.purchaseOrderItemId}
        ''',
        [order.id],
      );
      final receivedQuantities = {
        for (final row in receivedRows)
          row['order_item_id'] as String: (row['received_quantity'] as num)
              .toDouble(),
      };
      final currentItems = existingRows
          .where((row) => row[PurchaseOrderItemTable.deletedAt] == null)
          .toList();
      final submittedByItemId = {
        for (final item in items) item['item_id'] as String: item,
      };
      final submittedItemsChanged = !_sameActiveOrderItems(existingRows, items);

      if ((currentStatus == PurchaseOrderStatus.received ||
              currentStatus == PurchaseOrderStatus.cancelled) &&
          submittedItemsChanged) {
        throw StateError(
          currentStatus == PurchaseOrderStatus.received
              ? 'سفارش تکمیل‌شده قابل تغییر نیست؛ برای اقلام جدید سفارش دیگری بسازید.'
              : 'سفارش لغوشده قابل تغییر نیست.',
        );
      }

      for (final row in currentItems) {
        final itemId = row[PurchaseOrderItemTable.itemId] as String;
        final orderItemId = row[PurchaseOrderItemTable.id] as String;
        final received = receivedQuantities[orderItemId] ?? 0;
        final submitted = submittedByItemId[itemId];
        if (received > 0 && submitted == null) {
          throw StateError('قلمی که برای آن رسید ثبت شده قابل حذف نیست.');
        }
        if (received > 0 && submitted != null) {
          if (submitted['ordered_quantity'] is! num ||
              (submitted['ordered_quantity'] as num) < received) {
            throw StateError(
              'مقدار سفارش نمی‌تواند کمتر از مقدار دریافت‌شده باشد.',
            );
          }
          if (submitted['item_id'] != itemId) {
            throw StateError('کالای دارای رسید قابل جایگزینی نیست.');
          }
        }
      }

      final submittedItemIds = items
          .map((item) => item['item_id'] as String)
          .toSet();
      for (final row in currentItems) {
        if (!submittedItemIds.contains(row[PurchaseOrderItemTable.itemId])) {
          await txn.update(
            PurchaseOrderItemTable.tableName,
            {
              PurchaseOrderItemTable.deletedAt: now,
              PurchaseOrderItemTable.updatedAt: now,
              PurchaseOrderItemTable.syncStatus: 'pending',
            },
            where: '${PurchaseOrderItemTable.id} = ?',
            whereArgs: [row[PurchaseOrderItemTable.id]],
          );
        }
      }

      for (final item in items) {
        final itemId = item['item_id'] as String;
        final existing = existingRows
            .where((row) => row[PurchaseOrderItemTable.itemId] == itemId)
            .firstOrNull;
        if (existing == null) {
          await txn.insert(PurchaseOrderItemTable.tableName, {
            PurchaseOrderItemTable.id: IdGenerator.generate(),
            PurchaseOrderItemTable.purchaseOrderId: order.id,
            PurchaseOrderItemTable.itemId: itemId,
            PurchaseOrderItemTable.orderedQuantity: item['ordered_quantity'],
            PurchaseOrderItemTable.unitPrice: item['unit_price'],
            PurchaseOrderItemTable.notes: item['notes'],
            PurchaseOrderItemTable.createdAt: now,
            PurchaseOrderItemTable.updatedAt: now,
            PurchaseOrderItemTable.syncStatus: 'pending',
          });
        } else {
          final values = <String, Object?>{
            PurchaseOrderItemTable.orderedQuantity: item['ordered_quantity'],
            PurchaseOrderItemTable.unitPrice: item['unit_price'],
            PurchaseOrderItemTable.deletedAt: null,
            PurchaseOrderItemTable.updatedAt: now,
            PurchaseOrderItemTable.syncStatus: 'pending',
          };
          if (item.containsKey('notes')) {
            values[PurchaseOrderItemTable.notes] = item['notes'];
          }
          await txn.update(
            PurchaseOrderItemTable.tableName,
            values,
            where: '${PurchaseOrderItemTable.id} = ?',
            whereArgs: [existing[PurchaseOrderItemTable.id]],
          );
        }
      }

      final statusRows = await txn.rawQuery(
        '''
        SELECT poi.${PurchaseOrderItemTable.id} AS order_item_id,
          poi.${PurchaseOrderItemTable.orderedQuantity} AS ordered_quantity,
          COALESCE(SUM(st.${StockTransactionTable.quantity}), 0) AS received_quantity
        FROM ${PurchaseOrderItemTable.tableName} poi
        LEFT JOIN ${StockTransactionTable.tableName} st
          ON st.${StockTransactionTable.purchaseOrderItemId} = poi.${PurchaseOrderItemTable.id}
          AND st.${StockTransactionTable.transactionType} = 'PURCHASE_RECEIPT'
          AND st.${StockTransactionTable.deletedAt} IS NULL
        WHERE poi.${PurchaseOrderItemTable.purchaseOrderId} = ?
          AND poi.${PurchaseOrderItemTable.deletedAt} IS NULL
        GROUP BY poi.${PurchaseOrderItemTable.id}
        ''',
        [order.id],
      );
      final hasAnyReceipt = statusRows.any(
        (row) => (row['received_quantity'] as num) > 0,
      );
      final allLinesReceived =
          statusRows.isNotEmpty &&
          statusRows.every(
            (row) =>
                (row['received_quantity'] as num) >=
                (row['ordered_quantity'] as num),
          );
      final recalculatedStatus = hasAnyReceipt
          ? allLinesReceived
                ? PurchaseOrderStatus.received
                : PurchaseOrderStatus.partiallyReceived
          : currentStatus;
      savedStatus = recalculatedStatus;
      final updatedOrder = updated.copyWith(status: recalculatedStatus);
      await txn.update(
        _tableName,
        updatedOrder.toMap(),
        where: '${PurchaseOrderTable.id} = ?',
        whereArgs: [order.id],
      );
    });

    return updated.copyWith(status: savedStatus);
  }

  bool _sameActiveOrderItems(
    List<Map<String, Object?>> existingRows,
    List<Map<String, dynamic>> items,
  ) {
    final existing = existingRows
        .where((row) => row[PurchaseOrderItemTable.deletedAt] == null)
        .map(
          (row) => (
            itemId: row[PurchaseOrderItemTable.itemId] as String,
            quantity: (row[PurchaseOrderItemTable.orderedQuantity] as num)
                .toDouble(),
            unitPrice: (row[PurchaseOrderItemTable.unitPrice] as num)
                .toDouble(),
          ),
        )
        .toList();
    final submitted = items
        .map(
          (item) => (
            itemId: item['item_id'] as String,
            quantity: (item['ordered_quantity'] as num).toDouble(),
            unitPrice: (item['unit_price'] as num).toDouble(),
          ),
        )
        .toList();
    if (existing.length != submitted.length) return false;
    return existing.every(
      (row) => submitted.any(
        (item) =>
            item.itemId == row.itemId &&
            item.quantity == row.quantity &&
            item.unitPrice == row.unitPrice,
      ),
    );
  }

  void _validateOrderItems(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      throw ArgumentError('سفارش خرید باید حداقل یک قلم داشته باشد.');
    }
    final itemIds = <String>{};
    for (final item in items) {
      final itemId = item['item_id'];
      final quantity = item['ordered_quantity'];
      final unitPrice = item['unit_price'];
      if (itemId is! String || itemId.trim().isEmpty) {
        throw ArgumentError('کالای سفارش معتبر نیست.');
      }
      if (!itemIds.add(itemId)) {
        throw ArgumentError('هر کالا فقط یک‌بار در سفارش ثبت می‌شود.');
      }
      if (quantity is! num || !quantity.isFinite || quantity <= 0) {
        throw ArgumentError('مقدار سفارش باید بیشتر از صفر باشد.');
      }
      if (unitPrice is! num || !unitPrice.isFinite || unitPrice < 0) {
        throw ArgumentError('قیمت واحد نمی‌تواند منفی باشد.');
      }
    }
  }

  Future<void> receiveItems({
    required String purchaseOrderId,
    required List<Map<String, dynamic>>
    receivedLines, // purchaseOrderItemId, receivedQuantity
  }) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();

    await db.transaction((txn) async {
      final orderRows = await txn.query(
        _tableName,
        columns: [PurchaseOrderTable.status],
        where:
            '${PurchaseOrderTable.id} = ? AND ${PurchaseOrderTable.deletedAt} IS NULL',
        whereArgs: [purchaseOrderId],
        limit: 1,
      );
      if (orderRows.isEmpty) throw StateError('سفارش خرید یافت نشد.');
      final status = PurchaseOrderStatus.fromDbString(
        orderRows.first[PurchaseOrderTable.status] as String?,
      );
      if (status == PurchaseOrderStatus.cancelled ||
          status == PurchaseOrderStatus.received) {
        throw StateError('این سفارش امکان ثبت رسید جدید ندارد.');
      }

      for (final line in receivedLines) {
        final poiId = line['purchase_order_item_id'] as String;
        final qty = (line['received_quantity'] as num).toDouble();
        if (!qty.isFinite || qty < 0) {
          throw ArgumentError('مقدار دریافتی باید صفر یا بیشتر باشد.');
        }
        if (qty <= 0) continue;

        // Fetch PO item
        final poiMaps = await txn.query(
          PurchaseOrderItemTable.tableName,
          where:
              '${PurchaseOrderItemTable.id} = ? AND ${PurchaseOrderItemTable.purchaseOrderId} = ? AND ${PurchaseOrderItemTable.deletedAt} IS NULL',
          whereArgs: [poiId, purchaseOrderId],
          limit: 1,
        );
        if (poiMaps.isEmpty) {
          throw StateError('قلم سفارش برای ثبت رسید معتبر نیست.');
        }
        final poi = PurchaseOrderItem.fromMap(poiMaps.first);

        // Check already received quantity
        final recRes = await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(${StockTransactionTable.quantity}), 0) as total_received
          FROM ${StockTransactionTable.tableName}
          WHERE ${StockTransactionTable.purchaseOrderItemId} = ? AND ${StockTransactionTable.deletedAt} IS NULL
        ''',
          [poiId],
        );
        final totalReceived = (recRes.first['total_received'] as num)
            .toDouble();
        final remaining = poi.orderedQuantity - totalReceived;

        if (qty > remaining) {
          throw StateError(
            'مقدار دریافتی بیشتر از مقدار سفارش‌داده شده باقی‌مانده است.',
          );
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
      final items = await txn.query(
        PurchaseOrderItemTable.tableName,
        where:
            '${PurchaseOrderItemTable.purchaseOrderId} = ? AND ${PurchaseOrderItemTable.deletedAt} IS NULL',
        whereArgs: [purchaseOrderId],
      );
      bool allFullyReceived = true;
      bool anyReceived = false;

      for (final item in items) {
        final poiId = item[PurchaseOrderItemTable.id] as String;
        final ordered = (item[PurchaseOrderItemTable.orderedQuantity] as num)
            .toDouble();

        final recRes = await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(${StockTransactionTable.quantity}), 0) as total_received
          FROM ${StockTransactionTable.tableName}
          WHERE ${StockTransactionTable.purchaseOrderItemId} = ? AND ${StockTransactionTable.deletedAt} IS NULL
        ''',
          [poiId],
        );
        final received = (recRes.first['total_received'] as num).toDouble();

        if (received > 0) anyReceived = true;
        if (received < ordered) allFullyReceived = false;
      }

      if (items.isEmpty) throw StateError('سفارش خرید هیچ قلمی ندارد.');
      final newStatus = allFullyReceived && anyReceived
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
