import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/asset_table.dart';
import '../../../core/storage/database/tables/inventory_item_table.dart';
import '../../../core/storage/database/tables/purchase_order_item_table.dart';
import '../../../core/storage/database/tables/purchase_order_table.dart';
import '../../../core/storage/database/tables/stock_transaction_table.dart';
import '../../../core/storage/database/tables/work_order_table.dart';
import '../../../core/storage/database/tables/work_order_task_table.dart';
import '../../../core/storage/database/tables/work_order_material_table.dart';
import '../models/operational_report.dart';

class ReportRepository {
  final DatabaseHelper _dbHelper;

  ReportRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<OperationalReport> getOperationalReport({
    required String facilityId,
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    if (!endExclusive.isAfter(start)) {
      throw ArgumentError('بازه گزارش نامعتبر است.');
    }
    final db = await _dbHelper.db;
    final startUtc = start.toUtc().toIso8601String();
    final endUtc = endExclusive.toUtc().toIso8601String();

    final taskSummary = await db.rawQuery(
      '''
        SELECT COUNT(t.${WorkOrderTaskTable.id}) AS task_count,
               COALESCE(SUM(t.${WorkOrderTaskTable.laborMinutes}), 0) AS labor_minutes,
               COALESCE(SUM(t.${WorkOrderTaskTable.downtimeMinutes}), 0) AS downtime_minutes
        FROM ${WorkOrderTaskTable.tableName} t
        JOIN ${WorkOrderTable.tableName} w
          ON w.${WorkOrderTable.id} = t.${WorkOrderTaskTable.workOrderId}
        WHERE w.${WorkOrderTable.facilityId} = ?
          AND w.${WorkOrderTable.deletedAt} IS NULL
          AND t.${WorkOrderTaskTable.deletedAt} IS NULL
          AND t.${WorkOrderTaskTable.status} = 'COMPLETED'
          AND t.${WorkOrderTaskTable.completedAt} >= ?
          AND t.${WorkOrderTaskTable.completedAt} < ?
      ''',
      [facilityId, startUtc, endUtc],
    );
    final taskTrendRows = await db.rawQuery(
      '''
        SELECT date(t.${WorkOrderTaskTable.completedAt}, 'localtime') AS day,
               COUNT(*) AS task_count,
               COALESCE(SUM(t.${WorkOrderTaskTable.laborMinutes}), 0) AS labor_minutes,
               COALESCE(SUM(t.${WorkOrderTaskTable.downtimeMinutes}), 0) AS downtime_minutes
        FROM ${WorkOrderTaskTable.tableName} t
        JOIN ${WorkOrderTable.tableName} w
          ON w.${WorkOrderTable.id} = t.${WorkOrderTaskTable.workOrderId}
        WHERE w.${WorkOrderTable.facilityId} = ?
          AND w.${WorkOrderTable.deletedAt} IS NULL
          AND t.${WorkOrderTaskTable.deletedAt} IS NULL
          AND t.${WorkOrderTaskTable.status} = 'COMPLETED'
          AND t.${WorkOrderTaskTable.completedAt} >= ?
          AND t.${WorkOrderTaskTable.completedAt} < ?
        GROUP BY day
        ORDER BY day
      ''',
      [facilityId, startUtc, endUtc],
    );
    final completedTaskRows = await db.rawQuery(
      '''
        SELECT t.${WorkOrderTaskTable.title} AS task_title,
               a.${AssetTable.name} AS asset_name,
               w.${WorkOrderTable.workOrderNumber} AS work_order_number,
               t.${WorkOrderTaskTable.completedAt} AS completed_at,
               COALESCE(t.${WorkOrderTaskTable.laborMinutes}, 0) AS labor_minutes,
               COALESCE(t.${WorkOrderTaskTable.downtimeMinutes}, 0) AS downtime_minutes
        FROM ${WorkOrderTaskTable.tableName} t
        JOIN ${WorkOrderTable.tableName} w
          ON w.${WorkOrderTable.id} = t.${WorkOrderTaskTable.workOrderId}
        JOIN ${AssetTable.tableName} a
          ON a.${AssetTable.id} = t.${WorkOrderTaskTable.assetId}
        WHERE w.${WorkOrderTable.facilityId} = ?
          AND w.${WorkOrderTable.deletedAt} IS NULL
          AND t.${WorkOrderTaskTable.deletedAt} IS NULL
          AND a.${AssetTable.deletedAt} IS NULL
          AND t.${WorkOrderTaskTable.status} = 'COMPLETED'
          AND t.${WorkOrderTaskTable.completedAt} >= ?
          AND t.${WorkOrderTaskTable.completedAt} < ?
        ORDER BY t.${WorkOrderTaskTable.completedAt} DESC
        LIMIT 50
      ''',
      [facilityId, startUtc, endUtc],
    );
    final materialSummaryRows = await db.rawQuery(
      '''
        SELECT COUNT(st.${StockTransactionTable.id}) AS transaction_count,
               COUNT(DISTINCT wom.${WorkOrderMaterialTable.itemId}) AS item_count,
               COALESCE(SUM(
                 CASE WHEN st.${StockTransactionTable.unitCost} IS NULL THEN 1 ELSE 0 END
               ), 0) AS unpriced_count,
               COALESCE(SUM(
                 st.${StockTransactionTable.quantity} *
                 COALESCE(st.${StockTransactionTable.unitCost}, 0)
               ), 0) AS total_cost
        FROM ${StockTransactionTable.tableName} st
        JOIN ${WorkOrderMaterialTable.tableName} wom
          ON wom.${WorkOrderMaterialTable.id} = st.${StockTransactionTable.workOrderMaterialId}
        JOIN ${WorkOrderTaskTable.tableName} t
          ON t.${WorkOrderTaskTable.id} = wom.${WorkOrderMaterialTable.workOrderTaskId}
        JOIN ${WorkOrderTable.tableName} w
          ON w.${WorkOrderTable.id} = t.${WorkOrderTaskTable.workOrderId}
        WHERE w.${WorkOrderTable.facilityId} = ?
          AND w.${WorkOrderTable.deletedAt} IS NULL
          AND t.${WorkOrderTaskTable.deletedAt} IS NULL
          AND wom.${WorkOrderMaterialTable.deletedAt} IS NULL
          AND st.${StockTransactionTable.deletedAt} IS NULL
          AND st.${StockTransactionTable.transactionType} = 'MAINTENANCE_CONSUMPTION'
          AND st.${StockTransactionTable.transactionDate} >= ?
          AND st.${StockTransactionTable.transactionDate} < ?
      ''',
      [facilityId, startUtc, endUtc],
    );
    final materialRows = await db.rawQuery(
      '''
        SELECT i.${InventoryItemTable.name} AS item_name,
               i.${InventoryItemTable.unit} AS item_unit,
               COALESCE(SUM(st.${StockTransactionTable.quantity}), 0) AS quantity,
               COALESCE(SUM(
                 st.${StockTransactionTable.quantity} *
                 COALESCE(st.${StockTransactionTable.unitCost}, 0)
               ), 0) AS total_cost,
               COALESCE(SUM(
                 CASE WHEN st.${StockTransactionTable.unitCost} IS NULL THEN 1 ELSE 0 END
               ), 0) AS unpriced_count
        FROM ${StockTransactionTable.tableName} st
        JOIN ${WorkOrderMaterialTable.tableName} wom
          ON wom.${WorkOrderMaterialTable.id} = st.${StockTransactionTable.workOrderMaterialId}
        JOIN ${WorkOrderTaskTable.tableName} t
          ON t.${WorkOrderTaskTable.id} = wom.${WorkOrderMaterialTable.workOrderTaskId}
        JOIN ${WorkOrderTable.tableName} w
          ON w.${WorkOrderTable.id} = t.${WorkOrderTaskTable.workOrderId}
        JOIN ${InventoryItemTable.tableName} i
          ON i.${InventoryItemTable.id} = st.${StockTransactionTable.itemId}
        WHERE w.${WorkOrderTable.facilityId} = ?
          AND w.${WorkOrderTable.deletedAt} IS NULL
          AND t.${WorkOrderTaskTable.deletedAt} IS NULL
          AND wom.${WorkOrderMaterialTable.deletedAt} IS NULL
          AND i.${InventoryItemTable.deletedAt} IS NULL
          AND st.${StockTransactionTable.deletedAt} IS NULL
          AND st.${StockTransactionTable.transactionType} = 'MAINTENANCE_CONSUMPTION'
          AND st.${StockTransactionTable.transactionDate} >= ?
          AND st.${StockTransactionTable.transactionDate} < ?
        GROUP BY i.${InventoryItemTable.id}
        ORDER BY total_cost DESC, quantity DESC
        LIMIT 20
      ''',
      [facilityId, startUtc, endUtc],
    );
    final receiptSummaryRows = await db.rawQuery(
      '''
        SELECT COUNT(st.${StockTransactionTable.id}) AS transaction_count,
               COALESCE(SUM(
                 st.${StockTransactionTable.quantity} *
                 COALESCE(st.${StockTransactionTable.unitCost}, poi.${PurchaseOrderItemTable.unitPrice})
               ), 0) AS total_cost
        FROM ${StockTransactionTable.tableName} st
        JOIN ${PurchaseOrderItemTable.tableName} poi
          ON poi.${PurchaseOrderItemTable.id} = st.${StockTransactionTable.purchaseOrderItemId}
        JOIN ${PurchaseOrderTable.tableName} po
          ON po.${PurchaseOrderTable.id} = poi.${PurchaseOrderItemTable.purchaseOrderId}
        WHERE po.${PurchaseOrderTable.facilityId} = ?
          AND po.${PurchaseOrderTable.deletedAt} IS NULL
          AND poi.${PurchaseOrderItemTable.deletedAt} IS NULL
          AND st.${StockTransactionTable.deletedAt} IS NULL
          AND st.${StockTransactionTable.transactionType} = 'PURCHASE_RECEIPT'
          AND st.${StockTransactionTable.transactionDate} >= ?
          AND st.${StockTransactionTable.transactionDate} < ?
      ''',
      [facilityId, startUtc, endUtc],
    );
    final receiptTrendRows = await db.rawQuery(
      '''
        SELECT date(st.${StockTransactionTable.transactionDate}, 'localtime') AS day,
               COALESCE(SUM(
                 st.${StockTransactionTable.quantity} *
                 COALESCE(st.${StockTransactionTable.unitCost}, poi.${PurchaseOrderItemTable.unitPrice})
               ), 0) AS received_cost
        FROM ${StockTransactionTable.tableName} st
        JOIN ${PurchaseOrderItemTable.tableName} poi
          ON poi.${PurchaseOrderItemTable.id} = st.${StockTransactionTable.purchaseOrderItemId}
        JOIN ${PurchaseOrderTable.tableName} po
          ON po.${PurchaseOrderTable.id} = poi.${PurchaseOrderItemTable.purchaseOrderId}
        WHERE po.${PurchaseOrderTable.facilityId} = ?
          AND po.${PurchaseOrderTable.deletedAt} IS NULL
          AND poi.${PurchaseOrderItemTable.deletedAt} IS NULL
          AND st.${StockTransactionTable.deletedAt} IS NULL
          AND st.${StockTransactionTable.transactionType} = 'PURCHASE_RECEIPT'
          AND st.${StockTransactionTable.transactionDate} >= ?
          AND st.${StockTransactionTable.transactionDate} < ?
        GROUP BY day
        ORDER BY day
      ''',
      [facilityId, startUtc, endUtc],
    );
    final receiptRows = await db.rawQuery(
      '''
        SELECT po.${PurchaseOrderTable.purchaseOrderNumber} AS order_number,
               po.${PurchaseOrderTable.supplierName} AS supplier_name,
               i.${InventoryItemTable.name} AS item_name,
               i.${InventoryItemTable.unit} AS item_unit,
               st.${StockTransactionTable.quantity} AS quantity,
               COALESCE(st.${StockTransactionTable.unitCost}, poi.${PurchaseOrderItemTable.unitPrice}) AS unit_cost,
               st.${StockTransactionTable.transactionDate} AS transaction_date
        FROM ${StockTransactionTable.tableName} st
        JOIN ${PurchaseOrderItemTable.tableName} poi
          ON poi.${PurchaseOrderItemTable.id} = st.${StockTransactionTable.purchaseOrderItemId}
        JOIN ${PurchaseOrderTable.tableName} po
          ON po.${PurchaseOrderTable.id} = poi.${PurchaseOrderItemTable.purchaseOrderId}
        JOIN ${InventoryItemTable.tableName} i
          ON i.${InventoryItemTable.id} = st.${StockTransactionTable.itemId}
        WHERE po.${PurchaseOrderTable.facilityId} = ?
          AND po.${PurchaseOrderTable.deletedAt} IS NULL
          AND poi.${PurchaseOrderItemTable.deletedAt} IS NULL
          AND i.${InventoryItemTable.deletedAt} IS NULL
          AND st.${StockTransactionTable.deletedAt} IS NULL
          AND st.${StockTransactionTable.transactionType} = 'PURCHASE_RECEIPT'
          AND st.${StockTransactionTable.transactionDate} >= ?
          AND st.${StockTransactionTable.transactionDate} < ?
        ORDER BY st.${StockTransactionTable.transactionDate} DESC
        LIMIT 100
      ''',
      [facilityId, startUtc, endUtc],
    );

    final summary = taskSummary.single;
    return OperationalReport(
      completedTasks: (summary['task_count'] as num).toInt(),
      laborMinutes: (summary['labor_minutes'] as num).toInt(),
      downtimeMinutes: (summary['downtime_minutes'] as num).toInt(),
      taskTrend: taskTrendRows
          .map(
            (row) => ReportTrendPoint(
              date: row['day'] as String,
              taskCount: (row['task_count'] as num).toInt(),
              laborHours: (row['labor_minutes'] as num).toDouble() / 60,
              downtimeHours: (row['downtime_minutes'] as num).toDouble() / 60,
            ),
          )
          .toList(),
      completedTaskRows: completedTaskRows
          .map(
            (row) => ReportCompletedTask(
              title: row['task_title'] as String,
              assetName: row['asset_name'] as String,
              workOrderNumber: row['work_order_number'] as String,
              completedAt: row['completed_at'] as String,
              laborMinutes: (row['labor_minutes'] as num).toInt(),
              downtimeMinutes: (row['downtime_minutes'] as num).toInt(),
            ),
          )
          .toList(),
      consumedTransactionCount:
          (materialSummaryRows.single['transaction_count'] as num).toInt(),
      consumedItemCount: (materialSummaryRows.single['item_count'] as num)
          .toInt(),
      unpricedConsumptionCount:
          (materialSummaryRows.single['unpriced_count'] as num).toInt(),
      totalConsumedCost: (materialSummaryRows.single['total_cost'] as num)
          .toDouble(),
      materialUsage: materialRows
          .map(
            (row) => ReportMaterialUsage(
              name: row['item_name'] as String,
              unit: row['item_unit'] as String,
              quantity: (row['quantity'] as num).toDouble(),
              totalCost: (row['total_cost'] as num).toDouble(),
              hasUnpricedCost: (row['unpriced_count'] as num).toInt() > 0,
            ),
          )
          .toList(),
      receivedTransactionCount:
          (receiptSummaryRows.single['transaction_count'] as num).toInt(),
      totalReceivedCost: (receiptSummaryRows.single['total_cost'] as num)
          .toDouble(),
      receiptTrend: receiptTrendRows
          .map(
            (row) => ReportTrendPoint(
              date: row['day'] as String,
              receivedCost: (row['received_cost'] as num).toDouble(),
            ),
          )
          .toList(),
      receipts: receiptRows
          .map(
            (row) => ReportReceipt(
              purchaseOrderNumber: row['order_number'] as String,
              supplierName: row['supplier_name'] as String?,
              itemName: row['item_name'] as String,
              unit: row['item_unit'] as String,
              quantity: (row['quantity'] as num).toDouble(),
              unitCost: (row['unit_cost'] as num?)?.toDouble() ?? 0,
              transactionDate: row['transaction_date'] as String,
            ),
          )
          .toList(),
    );
  }
}
