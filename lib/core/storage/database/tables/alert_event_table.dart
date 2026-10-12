class AlertEventTable {
  static const String tableName = 'alert_events';

  static const String id = 'id';
  static const String facilityId = 'facility_id';
  static const String alertType = 'alert_type';
  static const String severity = 'severity';
  static const String status = 'status';
  static const String title = 'title';
  static const String message = 'message';
  static const String assetId = 'asset_id';
  static const String maintenancePlanId = 'maintenance_plan_id';
  static const String workOrderTaskId = 'work_order_task_id';
  static const String inventoryItemId = 'inventory_item_id';
  static const String deduplicationKey = 'deduplication_key';
  static const String triggeredAt = 'triggered_at';
  static const String acknowledgedAt = 'acknowledged_at';
  static const String resolvedAt = 'resolved_at';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $facilityId TEXT NOT NULL,
      $alertType TEXT NOT NULL
        CHECK ($alertType IN ('MAINTENANCE_DUE','MAINTENANCE_OVERDUE','CONDITION_TRIGGERED','LOW_STOCK','WORK_ORDER_OVERDUE')),
      $severity TEXT NOT NULL DEFAULT 'WARNING'
        CHECK ($severity IN ('INFO','WARNING','CRITICAL')),
      $status TEXT NOT NULL DEFAULT 'ACTIVE'
        CHECK ($status IN ('ACTIVE','ACKNOWLEDGED','RESOLVED','DISMISSED')),
      $title TEXT NOT NULL,
      $message TEXT,
      $assetId TEXT,
      $maintenancePlanId TEXT,
      $workOrderTaskId TEXT,
      $inventoryItemId TEXT,
      $deduplicationKey TEXT NOT NULL,
      $triggeredAt TEXT NOT NULL,
      $acknowledgedAt TEXT,
      $resolvedAt TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($facilityId) REFERENCES facilities(id),
      FOREIGN KEY ($assetId) REFERENCES assets(id),
      FOREIGN KEY ($maintenancePlanId) REFERENCES maintenance_plans(id),
      FOREIGN KEY ($workOrderTaskId) REFERENCES work_order_tasks(id),
      FOREIGN KEY ($inventoryItemId) REFERENCES inventory_items(id)
    )
  ''';

  static const String createStatusTimeIndex = 'CREATE INDEX idx_alert_events_status_time ON $tableName($status, $triggeredAt)';
  static const String createFacilityIndex = 'CREATE INDEX idx_alert_events_facility ON $tableName($facilityId, $status)';
  static const String createAssetIndex = 'CREATE INDEX idx_alert_events_asset ON $tableName($assetId)';
  static const String createItemIndex = 'CREATE INDEX idx_alert_events_item ON $tableName($inventoryItemId)';
  static const String createUniqueDeduplicationIndex = '''
    CREATE UNIQUE INDEX uq_alert_active_deduplication 
    ON $tableName($deduplicationKey) 
    WHERE $status IN ('ACTIVE','ACKNOWLEDGED') AND $deletedAt IS NULL
  ''';
}
