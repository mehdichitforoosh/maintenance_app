import '../../../core/enums/app_enums.dart';

class WorkOrder {
  final String id;
  final String facilityId;
  final String workOrderNumber;
  final String title;
  final String? description;
  final WorkOrderType workOrderType;
  final Priority priority;
  final WorkOrderStatus status;
  final String? scheduledAt;
  final String? startedAt;
  final String? completedAt;
  final String? closedAt;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const WorkOrder({
    required this.id,
    required this.facilityId,
    required this.workOrderNumber,
    required this.title,
    this.description,
    required this.workOrderType,
    this.priority = Priority.medium,
    this.status = WorkOrderStatus.open,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.closedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facility_id': facilityId,
      'work_order_number': workOrderNumber,
      'title': title,
      'description': description,
      'work_order_type': workOrderType.toDbString(),
      'priority': priority.toDbString(),
      'status': status.toDbString(),
      'scheduled_at': scheduledAt,
      'started_at': startedAt,
      'completed_at': completedAt,
      'closed_at': closedAt,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory WorkOrder.fromMap(Map<String, dynamic> map) {
    return WorkOrder(
      id: map['id'] as String,
      facilityId: map['facility_id'] as String,
      workOrderNumber: map['work_order_number'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      workOrderType: WorkOrderType.fromDbString(map['work_order_type'] as String?),
      priority: Priority.fromDbString(map['priority'] as String?),
      status: WorkOrderStatus.fromDbString(map['status'] as String?),
      scheduledAt: map['scheduled_at'] as String?,
      startedAt: map['started_at'] as String?,
      completedAt: map['completed_at'] as String?,
      closedAt: map['closed_at'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  WorkOrder copyWith({
    String? title,
    String? description,
    WorkOrderType? workOrderType,
    Priority? priority,
    WorkOrderStatus? status,
    String? scheduledAt,
    String? startedAt,
    String? completedAt,
    String? closedAt,
    String? notes,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return WorkOrder(
      id: id,
      facilityId: facilityId,
      workOrderNumber: workOrderNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      workOrderType: workOrderType ?? this.workOrderType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      closedAt: closedAt ?? this.closedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
