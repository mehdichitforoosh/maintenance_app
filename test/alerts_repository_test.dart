import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/enums/app_enums.dart';
import 'package:maintenance_app/core/storage/database/database_helper.dart';
import 'package:maintenance_app/core/utils/date_utils.dart';
import 'package:maintenance_app/features/alerts/repositories/alert_repository.dart';
import 'package:maintenance_app/features/assets/repositories/asset_reading_repository.dart';
import 'package:maintenance_app/features/assets/repositories/asset_repository.dart';
import 'package:maintenance_app/features/facilities/repositories/facility_repository.dart';
import 'package:maintenance_app/features/inventory/repositories/inventory_repository.dart';
import 'package:maintenance_app/features/maintenance/repositories/maintenance_plan_repository.dart';
import 'package:maintenance_app/features/work_orders/repositories/work_order_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late FacilityRepository facilityRepo;
  late InventoryRepository inventoryRepo;
  late AssetRepository assetRepo;
  late MaintenancePlanRepository planRepo;
  late WorkOrderRepository woRepo;
  late AssetReadingRepository readingRepo;
  late AlertRepository alertRepo;

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    await dbHelper.initialize(inMemory: true);

    facilityRepo = FacilityRepository(dbHelper: dbHelper);
    inventoryRepo = InventoryRepository(dbHelper: dbHelper);
    assetRepo = AssetRepository(dbHelper: dbHelper);
    planRepo = MaintenancePlanRepository(dbHelper: dbHelper);
    woRepo = WorkOrderRepository(dbHelper: dbHelper);
    readingRepo = AssetReadingRepository(dbHelper: dbHelper);
    alertRepo = AlertRepository(dbHelper: dbHelper);
  });

  group('AlertRepository Edge Cases and Reconciliation Tests', () {
    test('Low Stock Alerts: WARNING when 0 < stock <= minStock, CRITICAL when stock <= 0, and auto-resolves when replenished', () async {
      final facility = await facilityRepo.createFacility(name: 'کارگاه تست انبار');

      // 1. Create item with minimumStock = 10 and 0 initial stock -> CRITICAL
      final item = await inventoryRepo.createItem(
        name: 'روغن موتور 20W50',
        code: 'OIL-20W50',
        unit: 'لیتر',
        minimumStock: 10,
      );

      var alerts = await alertRepo.reconcileAndGetAlerts(facility.id);
      expect(alerts, hasLength(1));
      expect(alerts.first.alertType, AlertType.lowStock);
      expect(alerts.first.severity, AlertSeverity.critical);
      expect(alerts.first.status, AlertStatus.active);

      // 2. Adjust stock to 5 (0 < stock <= minStock) -> WARNING
      await inventoryRepo.adjustStock(
        itemId: item.id,
        type: TransactionType.adjustmentIn,
        quantity: 5,
      );

      alerts = await alertRepo.reconcileAndGetAlerts(facility.id);
      final activeAlerts = alerts.where((a) => a.status == AlertStatus.active).toList();
      expect(activeAlerts, hasLength(1));
      expect(activeAlerts.first.severity, AlertSeverity.warning);

      // 3. Replenish stock to 20 (stock > minStock) -> Automatically resolves alert
      await inventoryRepo.adjustStock(
        itemId: item.id,
        type: TransactionType.adjustmentIn,
        quantity: 15,
      );

      alerts = await alertRepo.reconcileAndGetAlerts(facility.id);
      final resolvedAlerts = alerts.where((a) => a.inventoryItemId == item.id && a.status == AlertStatus.resolved).toList();
      expect(resolvedAlerts, hasLength(1));
      expect(resolvedAlerts.first.resolvedAt, isNotNull);
      expect(alerts.where((a) => a.status == AlertStatus.active), isEmpty);
    });

    test('Calendar Maintenance Due Alerts: Idempotency and automatic resolution on task completion', () async {
      final facility = await facilityRepo.createFacility(name: 'کارگاه نت');
      final asset = await assetRepo.createAsset(
        facilityId: facility.id,
        name: 'پمپ اصلی شماره ۱',
        code: 'PUMP-01',
      );

      final dueDate = DateTime.now().subtract(const Duration(hours: 1));
      final plan = await planRepo.createPlan(
        assetId: asset.id,
        title: 'سرویس دوره ای پمپ',
        scheduleType: ScheduleType.calendar,
        calendarIntervalValue: 1,
        calendarIntervalUnit: CalendarUnit.month,
        nextDueAt: AppDateUtils.toUtcIso(dueDate),
      );

      // 1. Reconcile alerts -> generates 1 MAINTENANCE_DUE alert
      var alerts = await alertRepo.reconcileAndGetAlerts(facility.id);
      expect(alerts.where((a) => a.maintenancePlanId == plan.id && a.status == AlertStatus.active), hasLength(1));

      // 2. Re-running reconcile multiple times MUST NOT duplicate alerts (Idempotency)
      await alertRepo.reconcileAlerts(facility.id);
      await alertRepo.reconcileAlerts(facility.id);
      alerts = await alertRepo.getAlerts(facility.id);
      expect(alerts.where((a) => a.maintenancePlanId == plan.id && a.status == AlertStatus.active), hasLength(1));

      // 3. Complete the generated task -> Alert automatically updates to RESOLVED
      final activeAlert = alerts.firstWhere((a) => a.maintenancePlanId == plan.id);
      final taskId = activeAlert.workOrderTaskId!;

      await woRepo.completeTask(
        taskId: taskId,
        facilityId: facility.id,
        result: TaskResult.success,
      );

      alerts = await alertRepo.getAlerts(facility.id);
      final completedAlert = alerts.firstWhere((a) => a.id == activeAlert.id);
      expect(completedAlert.status, AlertStatus.resolved);
      expect(completedAlert.resolvedAt, isNotNull);
    });

    test('Work Order Overdue Alerts: Triggers for past due tasks and skips future tasks', () async {
      final facility = await facilityRepo.createFacility(name: 'کارگاه تولید');
      final asset = await assetRepo.createAsset(
        facilityId: facility.id,
        name: 'کمپرسور باد',
        code: 'COMP-01',
      );

      final pastDueDate = DateTime.now().subtract(const Duration(days: 2));
      final futureDueDate = DateTime.now().add(const Duration(days: 2));

      final wo = await woRepo.createWorkOrder(
        facilityId: facility.id,
        title: 'دستورکار تعمیرات',
        workOrderType: WorkOrderType.corrective,
        tasks: [
          (
            assetId: asset.id,
            maintenancePlanId: null,
            title: 'وظیفه عقب افتاده',
            description: null,
            activityType: ActivityType.repair,
            scheduledAt: null,
            plannedDueAt: AppDateUtils.toUtcIso(pastDueDate),
            plannedMeterValue: null,
            sourceOccurrenceKey: null,
          ),
          (
            assetId: asset.id,
            maintenancePlanId: null,
            title: 'وظیفه آینده',
            description: null,
            activityType: ActivityType.inspection,
            scheduledAt: null,
            plannedDueAt: AppDateUtils.toUtcIso(futureDueDate),
            plannedMeterValue: null,
            sourceOccurrenceKey: null,
          ),
        ],
      );

      // Reconcile -> Only the past due task generates WORK_ORDER_OVERDUE alert
      final alerts = await alertRepo.reconcileAndGetAlerts(facility.id);
      final overdueAlerts = alerts.where((a) => a.alertType == AlertType.workOrderOverdue).toList();

      expect(overdueAlerts, hasLength(1));
      expect(overdueAlerts.first.title, contains('وظیفه عقب افتاده'));
      expect(overdueAlerts.first.severity, AlertSeverity.critical);
    });

    test('Manual Alert Status Transitions: Acknowledge, Resolve, Dismiss, and Status Filtering', () async {
      final facility = await facilityRepo.createFacility(name: 'کارگاه تست دستی');

      final item = await inventoryRepo.createItem(
        name: 'گریس نسوز',
        code: 'GREASE-01',
        unit: 'کیلوگرم',
        minimumStock: 5,
      );

      var alerts = await alertRepo.reconcileAndGetAlerts(facility.id);
      final alertId = alerts.first.id;

      // 1. Acknowledge alert
      await alertRepo.updateAlertStatus(alertId, AlertStatus.acknowledged);
      alerts = await alertRepo.getAlerts(facility.id, status: AlertStatus.acknowledged);
      expect(alerts, hasLength(1));
      expect(alerts.first.status, AlertStatus.acknowledged);
      expect(alerts.first.acknowledgedAt, isNotNull);

      // 2. Dismiss alert
      await alertRepo.updateAlertStatus(alertId, AlertStatus.dismissed);
      alerts = await alertRepo.getAlerts(facility.id, status: AlertStatus.dismissed);
      expect(alerts, hasLength(1));
      expect(alerts.first.status, AlertStatus.dismissed);
    });
  });
}
