class StockTransactionTable {
  static const String tableName = 'stock_transactions';

  static const String id = 'id';
  static const String itemId = 'item_id';
  static const String transactionType = 'transaction_type';
  static const String quantity = 'quantity';
  static const String unitCost = 'unit_cost';
  static const String transactionDate = 'transaction_date';
  static const String purchaseOrderItemId = 'purchase_order_item_id';
  static const String workOrderMaterialId = 'work_order_material_id';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $itemId TEXT NOT NULL,
      $transactionType TEXT NOT NULL
        CHECK ($transactionType IN ('PURCHASE_RECEIPT','MAINTENANCE_CONSUMPTION','ADJUSTMENT_IN','ADJUSTMENT_OUT','RETURN')),
      $quantity REAL NOT NULL CHECK ($quantity > 0),
      $unitCost REAL CHECK ($unitCost IS NULL OR $unitCost >= 0),
      $transactionDate TEXT NOT NULL,
      $purchaseOrderItemId TEXT,
      $workOrderMaterialId TEXT,
      $notes TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($itemId) REFERENCES inventory_items(id),
      FOREIGN KEY ($purchaseOrderItemId) REFERENCES purchase_order_items(id),
      FOREIGN KEY ($workOrderMaterialId) REFERENCES work_order_materials(id),
      CHECK (
        ($transactionType = 'PURCHASE_RECEIPT' AND $purchaseOrderItemId IS NOT NULL AND $workOrderMaterialId IS NULL)
        OR
        ($transactionType IN ('MAINTENANCE_CONSUMPTION','RETURN') AND $workOrderMaterialId IS NOT NULL AND $purchaseOrderItemId IS NULL)
        OR
        ($transactionType IN ('ADJUSTMENT_IN','ADJUSTMENT_OUT') AND $purchaseOrderItemId IS NULL AND $workOrderMaterialId IS NULL)
      )
    )
  ''';

  static const String createItemDateIndex = 'CREATE INDEX idx_stock_transactions_item_date ON $tableName($itemId, $transactionDate)';
  static const String createPurchaseItemIndex = 'CREATE INDEX idx_stock_transactions_purchase_item ON $tableName($purchaseOrderItemId)';
  static const String createWorkOrderMaterialIndex = 'CREATE INDEX idx_stock_transactions_work_order_material ON $tableName($workOrderMaterialId)';
}
