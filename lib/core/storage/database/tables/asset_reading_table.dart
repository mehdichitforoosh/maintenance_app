class AssetReadingTable {
  static const String tableName = 'asset_readings';

  static const String id = 'id';
  static const String assetId = 'asset_id';
  static const String metricName = 'metric_name';
  static const String value = 'value';
  static const String unit = 'unit';
  static const String recordedAt = 'recorded_at';
  static const String notes = 'notes';
  static const String supersededByReadingId = 'superseded_by_reading_id';
  static const String correctionReason = 'correction_reason';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable =
      '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $assetId TEXT NOT NULL,
      $metricName TEXT NOT NULL,
      $value REAL NOT NULL,
      $unit TEXT NOT NULL,
      $recordedAt TEXT NOT NULL,
      $notes TEXT,
      $supersededByReadingId TEXT,
      $correctionReason TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($assetId) REFERENCES assets(id),
      FOREIGN KEY ($supersededByReadingId) REFERENCES $tableName($id)
    )
  ''';

  static const String createAssetMetricTimeIndex =
      'CREATE INDEX idx_asset_readings_asset_metric_time ON $tableName($assetId, $metricName, $recordedAt)';
  static const String createSyncIndex =
      'CREATE INDEX idx_asset_readings_sync ON $tableName($syncStatus) WHERE $deletedAt IS NULL';
}
