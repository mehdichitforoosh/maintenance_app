class PurchaseOrderTable {
  static const String tableName = 'purchase_orders';

  static const String id = 'id';
  static const String facilityId = 'facility_id';
  static const String purchaseOrderNumber = 'purchase_order_number';
  static const String supplierName = 'supplier_name';
  static const String orderDate = 'order_date';
  static const String expectedDate = 'expected_date';
  static const String status = 'status';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $facilityId TEXT NOT NULL,
      $purchaseOrderNumber TEXT NOT NULL,
      $supplierName TEXT,
      $orderDate TEXT NOT NULL,
      $expectedDate TEXT,
      $status TEXT NOT NULL DEFAULT 'DRAFT'
        CHECK ($status IN ('DRAFT','ORDERED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED')),
      $notes TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($facilityId) REFERENCES facilities(id),
      UNIQUE ($facilityId, $purchaseOrderNumber)
    )
  ''';

  static const String createFacilityStatusIndex = 'CREATE INDEX idx_purchase_orders_facility_status ON $tableName($facilityId, $status)';
  static const String createOrderDateIndex = 'CREATE INDEX idx_purchase_orders_order_date ON $tableName($orderDate)';
}
