class WorkOrderTaskTable {
  static const String tableName = 'work_order_tasks';

  static const String id = 'id';
  static const String workOrderId = 'work_order_id';
  static const String assetId = 'asset_id';
  static const String maintenancePlanId = 'maintenance_plan_id';
  static const String title = 'title';
  static const String description = 'description';
  static const String activityType = 'activity_type';
  static const String status = 'status';
  static const String result = 'result';
  static const String scheduledAt = 'scheduled_at';
  static const String plannedDueAt = 'planned_due_at';
  static const String plannedMeterValue = 'planned_meter_value';
  static const String completionMeterValue = 'completion_meter_value';
  static const String completionMeterName = 'completion_meter_name';
  static const String completionMeterUnit = 'completion_meter_unit';
  static const String triggeringReadingId = 'triggering_reading_id';
  static const String sourceOccurrenceKey = 'source_occurrence_key';
  static const String startedAt = 'started_at';
  static const String completedAt = 'completed_at';
  static const String findings = 'findings';
  static const String failureDescription = 'failure_description';
  static const String followUpRequired = 'follow_up_required';
  static const String laborMinutes = 'labor_minutes';
  static const String downtimeMinutes = 'downtime_minutes';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $workOrderId TEXT NOT NULL,
      $assetId TEXT NOT NULL,
      $maintenancePlanId TEXT,
      $title TEXT NOT NULL,
      $description TEXT,
      $activityType TEXT NOT NULL DEFAULT 'INSPECTION'
        CHECK ($activityType IN ('INSPECTION','LUBRICATION','REPLACEMENT','CLEANING','CALIBRATION','TESTING','REPAIR','OTHER')),
      $status TEXT NOT NULL DEFAULT 'PENDING'
        CHECK ($status IN ('PENDING','IN_PROGRESS','COMPLETED','SKIPPED','CANCELLED')),
      $result TEXT CHECK ($result IS NULL OR $result IN ('SUCCESS','ISSUE_FOUND','FAILED','FOLLOW_UP_REQUIRED')),
      $scheduledAt TEXT,
      $plannedDueAt TEXT,
      $plannedMeterValue REAL,
      $completionMeterValue REAL,
      $completionMeterName TEXT,
      $completionMeterUnit TEXT,
      $triggeringReadingId TEXT,
      $sourceOccurrenceKey TEXT,
      $startedAt TEXT,
      $completedAt TEXT,
      $findings TEXT,
      $failureDescription TEXT,
      $followUpRequired INTEGER NOT NULL DEFAULT 0 CHECK ($followUpRequired IN (0,1)),
      $laborMinutes INTEGER CHECK ($laborMinutes IS NULL OR $laborMinutes >= 0),
      $downtimeMinutes INTEGER CHECK ($downtimeMinutes IS NULL OR $downtimeMinutes >= 0),
      $notes TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($workOrderId) REFERENCES work_orders(id),
      FOREIGN KEY ($assetId) REFERENCES assets(id),
      FOREIGN KEY ($maintenancePlanId) REFERENCES maintenance_plans(id),
      FOREIGN KEY ($triggeringReadingId) REFERENCES asset_readings(id)
    )
  ''';

  static const String createOrderIndex = 'CREATE INDEX idx_work_order_tasks_order ON $tableName($workOrderId)';
  static const String createAssetIndex = 'CREATE INDEX idx_work_order_tasks_asset ON $tableName($assetId)';
  static const String createPlanIndex = 'CREATE INDEX idx_work_order_tasks_plan ON $tableName($maintenancePlanId)';
  static const String createStatusIndex = 'CREATE INDEX idx_work_order_tasks_status ON $tableName($status)';
  static const String createDueIndex = 'CREATE INDEX idx_work_order_tasks_due ON $tableName($plannedDueAt)';
  static const String createUniqueOccurrenceIndex = '''
    CREATE UNIQUE INDEX uq_work_order_task_occurrence 
    ON $tableName($maintenancePlanId, $sourceOccurrenceKey) 
    WHERE $maintenancePlanId IS NOT NULL AND $sourceOccurrenceKey IS NOT NULL AND $deletedAt IS NULL
  ''';
}
