class WorkOrderMaterialTable {
  static const String tableName = 'work_order_materials';

  static const String id = 'id';
  static const String workOrderTaskId = 'work_order_task_id';
  static const String itemId = 'item_id';
  static const String plannedQuantity = 'planned_quantity';
  static const String actualQuantity = 'actual_quantity';
  static const String unitCostAtUse = 'unit_cost_at_use';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $workOrderTaskId TEXT NOT NULL,
      $itemId TEXT NOT NULL,
      $plannedQuantity REAL CHECK ($plannedQuantity IS NULL OR $plannedQuantity >= 0),
      $actualQuantity REAL CHECK ($actualQuantity IS NULL OR $actualQuantity >= 0),
      $unitCostAtUse REAL CHECK ($unitCostAtUse IS NULL OR $unitCostAtUse >= 0),
      $notes TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($workOrderTaskId) REFERENCES work_order_tasks(id),
      FOREIGN KEY ($itemId) REFERENCES inventory_items(id),
      UNIQUE ($workOrderTaskId, $itemId)
    )
  ''';

  static const String createTaskIndex = 'CREATE INDEX idx_work_order_materials_task ON $tableName($workOrderTaskId)';
  static const String createItemIndex = 'CREATE INDEX idx_work_order_materials_item ON $tableName($itemId)';
}
