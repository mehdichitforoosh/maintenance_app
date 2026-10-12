class MaintenancePlanTable {
  static const String tableName = 'maintenance_plans';

  static const String id = 'id';
  static const String assetId = 'asset_id';
  static const String title = 'title';
  static const String description = 'description';
  static const String activityType = 'activity_type';
  static const String priority = 'priority';
  static const String scheduleType = 'schedule_type';
  static const String calendarIntervalValue = 'calendar_interval_value';
  static const String calendarIntervalUnit = 'calendar_interval_unit';
  static const String meterName = 'meter_name';
  static const String meterInterval = 'meter_interval';
  static const String meterUnit = 'meter_unit';
  static const String lastCompletedMeterValue = 'last_completed_meter_value';
  static const String nextDueMeterValue = 'next_due_meter_value';
  static const String conditionConfigJson = 'condition_config_json';
  static const String oneTimeDueAt = 'one_time_due_at';
  static const String startDate = 'start_date';
  static const String nextDueAt = 'next_due_at';
  static const String lastCompletedAt = 'last_completed_at';
  static const String scheduleAnchor = 'schedule_anchor';
  static const String isActive = 'is_active';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $assetId TEXT NOT NULL,
      $title TEXT NOT NULL,
      $description TEXT,
      $activityType TEXT NOT NULL DEFAULT 'INSPECTION'
        CHECK ($activityType IN ('INSPECTION','LUBRICATION','REPLACEMENT','CLEANING','CALIBRATION','TESTING','REPAIR','OTHER')),
      $priority TEXT NOT NULL DEFAULT 'MEDIUM'
        CHECK ($priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
      $scheduleType TEXT NOT NULL
        CHECK ($scheduleType IN ('CALENDAR','METER','CONDITION','ONE_TIME','MANUAL')),
      $calendarIntervalValue INTEGER,
      $calendarIntervalUnit TEXT
        CHECK ($calendarIntervalUnit IS NULL OR $calendarIntervalUnit IN ('DAY','WEEK','MONTH','YEAR')),
      $meterName TEXT,
      $meterInterval REAL,
      $meterUnit TEXT,
      $lastCompletedMeterValue REAL,
      $nextDueMeterValue REAL,
      $conditionConfigJson TEXT,
      $oneTimeDueAt TEXT,
      $startDate TEXT,
      $nextDueAt TEXT,
      $lastCompletedAt TEXT,
      $scheduleAnchor TEXT NOT NULL DEFAULT 'COMPLETION_DATE'
        CHECK ($scheduleAnchor IN ('COMPLETION_DATE','PREVIOUS_DUE_DATE')),
      $isActive INTEGER NOT NULL DEFAULT 1 CHECK ($isActive IN (0,1)),
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($assetId) REFERENCES assets(id),
      CHECK ($scheduleType != 'CALENDAR' OR ($calendarIntervalValue IS NOT NULL AND $calendarIntervalValue > 0 AND $calendarIntervalUnit IS NOT NULL)),
      CHECK ($scheduleType != 'METER' OR ($meterName IS NOT NULL AND $meterInterval IS NOT NULL AND $meterInterval > 0 AND $meterUnit IS NOT NULL)),
      CHECK ($scheduleType != 'CONDITION' OR $conditionConfigJson IS NOT NULL),
      CHECK ($scheduleType != 'ONE_TIME' OR $oneTimeDueAt IS NOT NULL)
    )
  ''';

  static const String createAssetIndex = 'CREATE INDEX idx_maintenance_plans_asset ON $tableName($assetId)';
  static const String createDueIndex = 'CREATE INDEX idx_maintenance_plans_due ON $tableName($nextDueAt) WHERE $isActive = 1 AND $deletedAt IS NULL';
  static const String createTypeIndex = 'CREATE INDEX idx_maintenance_plans_type ON $tableName($scheduleType)';
}
