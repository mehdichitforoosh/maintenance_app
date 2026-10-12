class InventoryItemTable {
  static const String tableName = 'inventory_items';

  static const String id = 'id';
  static const String name = 'name';
  static const String code = 'code';
  static const String itemType = 'item_type';
  static const String unit = 'unit';
  static const String description = 'description';
  static const String minimumStock = 'minimum_stock';
  static const String defaultUnitCost = 'default_unit_cost';
  static const String isActive = 'is_active';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $name TEXT NOT NULL,
      $code TEXT NOT NULL UNIQUE,
      $itemType TEXT NOT NULL DEFAULT 'CONSUMABLE'
        CHECK ($itemType IN ('CONSUMABLE','SPARE_PART')),
      $unit TEXT NOT NULL,
      $description TEXT,
      $minimumStock REAL NOT NULL DEFAULT 0 CHECK ($minimumStock >= 0),
      $defaultUnitCost REAL CHECK ($defaultUnitCost IS NULL OR $defaultUnitCost >= 0),
      $isActive INTEGER NOT NULL DEFAULT 1 CHECK ($isActive IN (0,1)),
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict'))
    )
  ''';

  static const String createNameIndex = 'CREATE INDEX idx_inventory_items_name ON $tableName($name)';
  static const String createActiveIndex = 'CREATE INDEX idx_inventory_items_active ON $tableName($isActive)';
}
