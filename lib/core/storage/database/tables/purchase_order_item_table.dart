class PurchaseOrderItemTable {
  static const String tableName = 'purchase_order_items';

  static const String id = 'id';
  static const String purchaseOrderId = 'purchase_order_id';
  static const String itemId = 'item_id';
  static const String orderedQuantity = 'ordered_quantity';
  static const String unitPrice = 'unit_price';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $purchaseOrderId TEXT NOT NULL,
      $itemId TEXT NOT NULL,
      $orderedQuantity REAL NOT NULL CHECK ($orderedQuantity > 0),
      $unitPrice REAL NOT NULL CHECK ($unitPrice >= 0),
      $notes TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($purchaseOrderId) REFERENCES purchase_orders(id),
      FOREIGN KEY ($itemId) REFERENCES inventory_items(id),
      UNIQUE ($purchaseOrderId, $itemId)
    )
  ''';

  static const String createOrderIndex = 'CREATE INDEX idx_purchase_order_items_order ON $tableName($purchaseOrderId)';
  static const String createItemIndex = 'CREATE INDEX idx_purchase_order_items_item ON $tableName($itemId)';
}
