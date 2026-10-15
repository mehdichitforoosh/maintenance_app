class WorkOrderTaskEventTable {
  static const String tableName = 'work_order_task_events';

  static const String id = 'id';
  static const String workOrderTaskId = 'work_order_task_id';
  static const String eventType = 'event_type';
  static const String reason = 'reason';
  static const String beforeJson = 'before_json';
  static const String afterJson = 'after_json';
  static const String createdAt = 'created_at';

  static const String createTable =
      '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $workOrderTaskId TEXT NOT NULL,
      $eventType TEXT NOT NULL
        CHECK ($eventType IN ('COMPLETED','REOPENED','COMPLETION_CORRECTED')),
      $reason TEXT,
      $beforeJson TEXT,
      $afterJson TEXT,
      $createdAt TEXT NOT NULL,
      FOREIGN KEY ($workOrderTaskId) REFERENCES work_order_tasks(id)
    )
  ''';

  static const String createTaskIndex =
      'CREATE INDEX idx_work_order_task_events_task ON $tableName($workOrderTaskId, $createdAt)';
}
