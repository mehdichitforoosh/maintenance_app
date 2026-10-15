import 'package:sqflite/sqflite.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/maintenance_plan.dart';

class MaintenanceScheduler {
  /// Runs scheduling logic across all active plans in a database transaction or connection.
  static Future<void> runScheduler(Database db, String facilityId) async {
    final nowIso = AppDateUtils.nowUtcIso();
    final nowDate = DateTime.now();

    // Fetch active maintenance plans
    final planMaps = await db.query(
      'maintenance_plans',
      where: 'is_active = 1 AND deleted_at IS NULL',
    );

    for (final planMap in planMaps) {
      final plan = MaintenancePlan.fromMap(planMap);

      if (plan.scheduleType == ScheduleType.calendar) {
        await _processCalendarPlan(db, facilityId, plan, nowDate, nowIso);
      } else if (plan.scheduleType == ScheduleType.oneTime) {
        await _processOneTimePlan(db, facilityId, plan, nowDate, nowIso);
      }
    }
  }

  static Future<void> _processCalendarPlan(
    Database db,
    String facilityId,
    MaintenancePlan plan,
    DateTime nowDate,
    String nowIso,
  ) async {
    if (plan.nextDueAt == null) return;
    final dueDate = DateTime.tryParse(plan.nextDueAt!);
    if (dueDate == null) return;

    // If due today or in the past
    if (dueDate.isBefore(nowDate) || _isSameDay(dueDate, nowDate)) {
      final occurrenceKey = 'calendar:${AppDateUtils.formatDateOnly(dueDate)}';
      await _createTaskIdempotently(
        db: db,
        facilityId: facilityId,
        plan: plan,
        title: '${plan.title} (سررسید تقویمی)',
        occurrenceKey: occurrenceKey,
        plannedDueAt: plan.nextDueAt,
        nowIso: nowIso,
      );
    }
  }

  static Future<void> _processOneTimePlan(
    Database db,
    String facilityId,
    MaintenancePlan plan,
    DateTime nowDate,
    String nowIso,
  ) async {
    if (plan.oneTimeDueAt == null) return;
    final dueDate = DateTime.tryParse(plan.oneTimeDueAt!);
    if (dueDate == null) return;
    if (dueDate.isAfter(nowDate) && !_isSameDay(dueDate, nowDate)) return;

    final occurrenceKey = 'one-time:${plan.oneTimeDueAt}';
    await _createTaskIdempotently(
      db: db,
      facilityId: facilityId,
      plan: plan,
      title: '${plan.title} (یک‌باره)',
      occurrenceKey: occurrenceKey,
      plannedDueAt: plan.oneTimeDueAt,
      nowIso: nowIso,
    );
  }

  static Future<void> _createTaskIdempotently({
    required Database db,
    required String facilityId,
    required MaintenancePlan plan,
    required String title,
    required String occurrenceKey,
    String? plannedDueAt,
    double? plannedMeterValue,
    required String nowIso,
  }) async {
    // Check if task with same (maintenance_plan_id, source_occurrence_key) already exists
    final existing = await db.query(
      'work_order_tasks',
      where:
          'maintenance_plan_id = ? AND source_occurrence_key = ? AND deleted_at IS NULL',
      whereArgs: [plan.id, occurrenceKey],
    );

    if (existing.isNotEmpty) return; // Already generated

    // Ensure a Work Order exists for this plan or create an open Work Order
    // For simplicity, find or create an open PM work order for the facility
    String workOrderId;
    final openWos = await db.query(
      'work_orders',
      where:
          'facility_id = ? AND status = ? AND work_order_type = ? AND deleted_at IS NULL',
      whereArgs: [facilityId, 'OPEN', 'PREVENTIVE'],
      limit: 1,
    );

    if (openWos.isNotEmpty) {
      workOrderId = openWos.first['id'] as String;
    } else {
      workOrderId = IdGenerator.generate();
      final woNumber =
          'WO-PM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      await db.insert('work_orders', {
        'id': workOrderId,
        'facility_id': facilityId,
        'work_order_number': woNumber,
        'title': 'دستورکار پیشگیرانه خودکار',
        'work_order_type': 'PREVENTIVE',
        'priority': plan.priority.toDbString(),
        'status': 'OPEN',
        'created_at': nowIso,
        'updated_at': nowIso,
        'sync_status': 'pending',
      });
    }

    // Insert task
    final taskId = IdGenerator.generate();
    await db.insert('work_order_tasks', {
      'id': taskId,
      'work_order_id': workOrderId,
      'asset_id': plan.assetId,
      'maintenance_plan_id': plan.id,
      'title': title,
      'description': plan.description,
      'activity_type': plan.activityType.toDbString(),
      'status': 'PENDING',
      'planned_due_at': plannedDueAt,
      'planned_meter_value': plannedMeterValue,
      'source_occurrence_key': occurrenceKey,
      'created_at': nowIso,
      'updated_at': nowIso,
      'sync_status': 'pending',
    });

    // Also create an alert event if needed
    final alertId = IdGenerator.generate();
    final dedupKey = 'alert:plan:${plan.id}:$occurrenceKey';
    await db.insert('alert_events', {
      'id': alertId,
      'facility_id': facilityId,
      'alert_type': 'MAINTENANCE_DUE',
      'severity': plan.priority == Priority.critical ? 'CRITICAL' : 'WARNING',
      'status': 'ACTIVE',
      'title': 'سررسید نگهداری: ${plan.title}',
      'message': 'برنامه نگهداری سررسید شده است.',
      'asset_id': plan.assetId,
      'maintenance_plan_id': plan.id,
      'deduplication_key': dedupKey,
      'triggered_at': nowIso,
      'created_at': nowIso,
      'updated_at': nowIso,
      'sync_status': 'pending',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
