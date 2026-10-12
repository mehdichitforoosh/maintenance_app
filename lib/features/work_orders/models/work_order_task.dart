import '../../../core/enums/app_enums.dart';

class WorkOrderTask {
  final String id;
  final String workOrderId;
  final String assetId;
  final String? maintenancePlanId;
  final String title;
  final String? description;
  final ActivityType activityType;
  final TaskStatus status;
  final TaskResult? result;
  final String? scheduledAt;
  final String? plannedDueAt;
  final double? plannedMeterValue;
  final double? completionMeterValue;
  final String? completionMeterName;
  final String? completionMeterUnit;
  final String? triggeringReadingId;
  final String? sourceOccurrenceKey;
  final String? startedAt;
  final String? completedAt;
  final String? findings;
  final String? failureDescription;
  final bool followUpRequired;
  final int? laborMinutes;
  final int? downtimeMinutes;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const WorkOrderTask({
    required this.id,
    required this.workOrderId,
    required this.assetId,
    this.maintenancePlanId,
    required this.title,
    this.description,
    this.activityType = ActivityType.inspection,
    this.status = TaskStatus.pending,
    this.result,
    this.scheduledAt,
    this.plannedDueAt,
    this.plannedMeterValue,
    this.completionMeterValue,
    this.completionMeterName,
    this.completionMeterUnit,
    this.triggeringReadingId,
    this.sourceOccurrenceKey,
    this.startedAt,
    this.completedAt,
    this.findings,
    this.failureDescription,
    this.followUpRequired = false,
    this.laborMinutes,
    this.downtimeMinutes,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'work_order_id': workOrderId,
      'asset_id': assetId,
      'maintenance_plan_id': maintenancePlanId,
      'title': title,
      'description': description,
      'activity_type': activityType.toDbString(),
      'status': status.toDbString(),
      'result': result?.toDbString(),
      'scheduled_at': scheduledAt,
      'planned_due_at': plannedDueAt,
      'planned_meter_value': plannedMeterValue,
      'completion_meter_value': completionMeterValue,
      'completion_meter_name': completionMeterName,
      'completion_meter_unit': completionMeterUnit,
      'triggering_reading_id': triggeringReadingId,
      'source_occurrence_key': sourceOccurrenceKey,
      'started_at': startedAt,
      'completed_at': completedAt,
      'findings': findings,
      'failure_description': failureDescription,
      'follow_up_required': followUpRequired ? 1 : 0,
      'labor_minutes': laborMinutes,
      'downtime_minutes': downtimeMinutes,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory WorkOrderTask.fromMap(Map<String, dynamic> map) {
    return WorkOrderTask(
      id: map['id'] as String,
      workOrderId: map['work_order_id'] as String,
      assetId: map['asset_id'] as String,
      maintenancePlanId: map['maintenance_plan_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      activityType: ActivityType.fromDbString(map['activity_type'] as String?),
      status: TaskStatus.fromDbString(map['status'] as String?),
      result: TaskResult.fromDbString(map['result'] as String?),
      scheduledAt: map['scheduled_at'] as String?,
      plannedDueAt: map['planned_due_at'] as String?,
      plannedMeterValue: (map['planned_meter_value'] as num?)?.toDouble(),
      completionMeterValue: (map['completion_meter_value'] as num?)?.toDouble(),
      completionMeterName: map['completion_meter_name'] as String?,
      completionMeterUnit: map['completion_meter_unit'] as String?,
      triggeringReadingId: map['triggering_reading_id'] as String?,
      sourceOccurrenceKey: map['source_occurrence_key'] as String?,
      startedAt: map['started_at'] as String?,
      completedAt: map['completed_at'] as String?,
      findings: map['findings'] as String?,
      failureDescription: map['failure_description'] as String?,
      followUpRequired: (map['follow_up_required'] as int? ?? 0) == 1,
      laborMinutes: map['labor_minutes'] as int?,
      downtimeMinutes: map['downtime_minutes'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
