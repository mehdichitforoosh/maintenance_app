class MaintenancePlanMaterialTable {
  static const String tableName = 'maintenance_plan_materials';

  static const String id = 'id';
  static const String maintenancePlanId = 'maintenance_plan_id';
  static const String itemId = 'item_id';
  static const String plannedQuantity = 'planned_quantity';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $maintenancePlanId TEXT NOT NULL,
      $itemId TEXT NOT NULL,
      $plannedQuantity REAL NOT NULL CHECK ($plannedQuantity > 0),
      $notes TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($maintenancePlanId) REFERENCES maintenance_plans(id),
      FOREIGN KEY ($itemId) REFERENCES inventory_items(id),
      UNIQUE ($maintenancePlanId, $itemId)
    )
  ''';

  static const String createPlanIndex = 'CREATE INDEX idx_plan_materials_plan ON $tableName($maintenancePlanId)';
  static const String createItemIndex = 'CREATE INDEX idx_plan_materials_item ON $tableName($itemId)';
}
