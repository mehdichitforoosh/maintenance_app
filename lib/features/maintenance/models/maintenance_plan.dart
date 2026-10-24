import '../../../core/enums/app_enums.dart';

class MaintenancePlan {
  final String id;
  final String assetId;
  final String title;
  final String? description;
  final ActivityType activityType;
  final Priority priority;
  final ScheduleType scheduleType;
  final int? calendarIntervalValue;
  final CalendarUnit? calendarIntervalUnit;
  final String? meterName;
  final double? meterInterval;
  final String? meterUnit;
  final double? lastCompletedMeterValue;
  final double? nextDueMeterValue;
  final String? conditionConfigJson;
  final String? oneTimeDueAt;
  final String? startDate;
  final String? nextDueAt;
  final String? lastCompletedAt;
  final ScheduleAnchor scheduleAnchor;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const MaintenancePlan({
    required this.id,
    required this.assetId,
    required this.title,
    this.description,
    this.activityType = ActivityType.inspection,
    this.priority = Priority.medium,
    required this.scheduleType,
    this.calendarIntervalValue,
    this.calendarIntervalUnit,
    this.meterName,
    this.meterInterval,
    this.meterUnit,
    this.lastCompletedMeterValue,
    this.nextDueMeterValue,
    this.conditionConfigJson,
    this.oneTimeDueAt,
    this.startDate,
    this.nextDueAt,
    this.lastCompletedAt,
    this.scheduleAnchor = ScheduleAnchor.completionDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'title': title,
      'description': description,
      'activity_type': activityType.toDbString(),
      'priority': priority.toDbString(),
      'schedule_type': scheduleType.toDbString(),
      'calendar_interval_value': calendarIntervalValue,
      'calendar_interval_unit': calendarIntervalUnit?.toDbString(),
      'meter_name': meterName,
      'meter_interval': meterInterval,
      'meter_unit': meterUnit,
      'last_completed_meter_value': lastCompletedMeterValue,
      'next_due_meter_value': nextDueMeterValue,
      'condition_config_json': conditionConfigJson,
      'one_time_due_at': oneTimeDueAt,
      'start_date': startDate,
      'next_due_at': nextDueAt,
      'last_completed_at': lastCompletedAt,
      'schedule_anchor': scheduleAnchor.toDbString(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory MaintenancePlan.fromMap(Map<String, dynamic> map) {
    return MaintenancePlan(
      id: map['id'] as String,
      assetId: map['asset_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      activityType: ActivityType.fromDbString(map['activity_type'] as String?),
      priority: Priority.fromDbString(map['priority'] as String?),
      scheduleType: ScheduleType.fromDbString(map['schedule_type'] as String?),
      calendarIntervalValue: map['calendar_interval_value'] as int?,
      calendarIntervalUnit: CalendarUnit.fromDbString(
        map['calendar_interval_unit'] as String?,
      ),
      meterName: map['meter_name'] as String?,
      meterInterval: (map['meter_interval'] as num?)?.toDouble(),
      meterUnit: map['meter_unit'] as String?,
      lastCompletedMeterValue: (map['last_completed_meter_value'] as num?)
          ?.toDouble(),
      nextDueMeterValue: (map['next_due_meter_value'] as num?)?.toDouble(),
      conditionConfigJson: map['condition_config_json'] as String?,
      oneTimeDueAt: map['one_time_due_at'] as String?,
      startDate: map['start_date'] as String?,
      nextDueAt: map['next_due_at'] as String?,
      lastCompletedAt: map['last_completed_at'] as String?,
      scheduleAnchor: ScheduleAnchor.fromDbString(
        map['schedule_anchor'] as String?,
      ),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  MaintenancePlan copyWith({
    String? assetId,
    String? title,
    String? description,
    ActivityType? activityType,
    Priority? priority,
    ScheduleType? scheduleType,
    int? calendarIntervalValue,
    CalendarUnit? calendarIntervalUnit,
    String? meterName,
    double? meterInterval,
    String? meterUnit,
    double? lastCompletedMeterValue,
    double? nextDueMeterValue,
    String? conditionConfigJson,
    String? oneTimeDueAt,
    String? startDate,
    String? nextDueAt,
    String? lastCompletedAt,
    ScheduleAnchor? scheduleAnchor,
    bool? isActive,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
    bool clearDescription = false,
    bool clearScheduleFields = false,
    bool clearNextDueAt = false,
    bool clearLastCompletedMeterValue = false,
    bool clearNextDueMeterValue = false,
  }) {
    return MaintenancePlan(
      id: id,
      assetId: assetId ?? this.assetId,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      activityType: activityType ?? this.activityType,
      priority: priority ?? this.priority,
      scheduleType: scheduleType ?? this.scheduleType,
      calendarIntervalValue: clearScheduleFields
          ? calendarIntervalValue
          : calendarIntervalValue ?? this.calendarIntervalValue,
      calendarIntervalUnit: clearScheduleFields
          ? calendarIntervalUnit
          : calendarIntervalUnit ?? this.calendarIntervalUnit,
      meterName: clearScheduleFields ? meterName : meterName ?? this.meterName,
      meterInterval: clearScheduleFields
          ? meterInterval
          : meterInterval ?? this.meterInterval,
      meterUnit: clearScheduleFields ? meterUnit : meterUnit ?? this.meterUnit,
      lastCompletedMeterValue: clearScheduleFields
          ? lastCompletedMeterValue
          : clearLastCompletedMeterValue
          ? null
          : lastCompletedMeterValue ?? this.lastCompletedMeterValue,
      nextDueMeterValue: clearScheduleFields
          ? nextDueMeterValue
          : clearNextDueMeterValue
          ? null
          : nextDueMeterValue ?? this.nextDueMeterValue,
      conditionConfigJson: clearScheduleFields
          ? conditionConfigJson
          : conditionConfigJson ?? this.conditionConfigJson,
      oneTimeDueAt: clearScheduleFields
          ? oneTimeDueAt
          : oneTimeDueAt ?? this.oneTimeDueAt,
      startDate: clearScheduleFields ? startDate : startDate ?? this.startDate,
      nextDueAt: clearScheduleFields || clearNextDueAt
          ? nextDueAt
          : nextDueAt ?? this.nextDueAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      scheduleAnchor: scheduleAnchor ?? this.scheduleAnchor,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
