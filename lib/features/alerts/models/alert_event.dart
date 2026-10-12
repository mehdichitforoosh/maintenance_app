import '../../../core/enums/app_enums.dart';

class AlertEvent {
  final String id;
  final String facilityId;
  final AlertType alertType;
  final AlertSeverity severity;
  final AlertStatus status;
  final String title;
  final String? message;
  final String? assetId;
  final String? maintenancePlanId;
  final String? workOrderTaskId;
  final String? inventoryItemId;
  final String deduplicationKey;
  final String triggeredAt;
  final String? acknowledgedAt;
  final String? resolvedAt;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const AlertEvent({
    required this.id,
    required this.facilityId,
    required this.alertType,
    this.severity = AlertSeverity.warning,
    this.status = AlertStatus.active,
    required this.title,
    this.message,
    this.assetId,
    this.maintenancePlanId,
    this.workOrderTaskId,
    this.inventoryItemId,
    required this.deduplicationKey,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facility_id': facilityId,
      'alert_type': alertType.toDbString(),
      'severity': severity.toDbString(),
      'status': status.toDbString(),
      'title': title,
      'message': message,
      'asset_id': assetId,
      'maintenance_plan_id': maintenancePlanId,
      'work_order_task_id': workOrderTaskId,
      'inventory_item_id': inventoryItemId,
      'deduplication_key': deduplicationKey,
      'triggered_at': triggeredAt,
      'acknowledged_at': acknowledgedAt,
      'resolved_at': resolvedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory AlertEvent.fromMap(Map<String, dynamic> map) {
    return AlertEvent(
      id: map['id'] as String,
      facilityId: map['facility_id'] as String,
      alertType: AlertType.fromDbString(map['alert_type'] as String?),
      severity: AlertSeverity.fromDbString(map['severity'] as String?),
      status: AlertStatus.fromDbString(map['status'] as String?),
      title: map['title'] as String,
      message: map['message'] as String?,
      assetId: map['asset_id'] as String?,
      maintenancePlanId: map['maintenance_plan_id'] as String?,
      workOrderTaskId: map['work_order_task_id'] as String?,
      inventoryItemId: map['inventory_item_id'] as String?,
      deduplicationKey: map['deduplication_key'] as String,
      triggeredAt: map['triggered_at'] as String,
      acknowledgedAt: map['acknowledged_at'] as String?,
      resolvedAt: map['resolved_at'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
