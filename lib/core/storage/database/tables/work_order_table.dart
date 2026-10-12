class WorkOrderTable {
  static const String tableName = 'work_orders';

  static const String id = 'id';
  static const String facilityId = 'facility_id';
  static const String workOrderNumber = 'work_order_number';
  static const String title = 'title';
  static const String description = 'description';
  static const String workOrderType = 'work_order_type';
  static const String priority = 'priority';
  static const String status = 'status';
  static const String scheduledAt = 'scheduled_at';
  static const String startedAt = 'started_at';
  static const String completedAt = 'completed_at';
  static const String closedAt = 'closed_at';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $facilityId TEXT NOT NULL,
      $workOrderNumber TEXT NOT NULL,
      $title TEXT NOT NULL,
      $description TEXT,
      $workOrderType TEXT NOT NULL
        CHECK ($workOrderType IN ('PREVENTIVE','CORRECTIVE','EMERGENCY')),
      $priority TEXT NOT NULL DEFAULT 'MEDIUM'
        CHECK ($priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
      $status TEXT NOT NULL DEFAULT 'OPEN'
        CHECK ($status IN ('DRAFT','OPEN','IN_PROGRESS','ON_HOLD','COMPLETED','CANCELLED')),
      $scheduledAt TEXT,
      $startedAt TEXT,
      $completedAt TEXT,
      $closedAt TEXT,
      $notes TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($facilityId) REFERENCES facilities(id),
      UNIQUE ($facilityId, $workOrderNumber)
    )
  ''';

  static const String createFacilityStatusIndex = 'CREATE INDEX idx_work_orders_facility_status ON $tableName($facilityId, $status)';
  static const String createScheduledIndex = 'CREATE INDEX idx_work_orders_scheduled ON $tableName($scheduledAt)';
  static const String createUpdatedIndex = 'CREATE INDEX idx_work_orders_updated ON $tableName($updatedAt)';
}
