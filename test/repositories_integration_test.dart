import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/enums/app_enums.dart';
import 'package:maintenance_app/core/storage/database/database_helper.dart';
import 'package:maintenance_app/core/utils/date_utils.dart';
import 'package:maintenance_app/features/assets/repositories/asset_repository.dart';
import 'package:maintenance_app/features/facilities/repositories/facility_repository.dart';
import 'package:maintenance_app/features/inventory/repositories/inventory_repository.dart';
import 'package:maintenance_app/features/maintenance/repositories/maintenance_plan_repository.dart';
import 'package:maintenance_app/features/maintenance/services/maintenance_scheduler.dart';
import 'package:maintenance_app/features/purchases/repositories/purchase_repository.dart';
import 'package:maintenance_app/features/work_orders/repositories/work_order_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    await dbHelper.initialize(inMemory: true);
  });

  group('Purchase receiving and inventory ledger', () {
    test('partial and full receipts update stock and order status', () async {
      final facility = await FacilityRepository(
        dbHelper: dbHelper,
      ).createFacility(name: 'کارگاه خرید');
      final inventory = InventoryRepository(dbHelper: dbHelper);
      final item = await inventory.createItem(
        name: 'بلبرینگ',
        code: 'BRG-01',
        unit: 'عدد',
        minimumStock: 2,
      );
      final purchases = PurchaseRepository(dbHelper: dbHelper);
      final order = await purchases.createPurchaseOrder(
        facilityId: facility.id,
        supplierName: 'تأمین‌کننده',
        orderDate: '2026-10-15',
        items: [
          {'item_id': item.id, 'ordered_quantity': 10, 'unit_price': 25},
        ],
      );
      final orderItem = (await purchases.getOrderItems(order.id)).single;

      await purchases.receiveItems(
        purchaseOrderId: order.id,
        receivedLines: [
          {'purchase_order_item_id': orderItem.id, 'received_quantity': 4},
        ],
      );
      expect(
        (await purchases.getPurchaseOrderById(order.id))!.status,
        PurchaseOrderStatus.partiallyReceived,
      );
      expect(await inventory.getCurrentStock(item.id), 4);

      await purchases.receiveItems(
        purchaseOrderId: order.id,
        receivedLines: [
          {'purchase_order_item_id': orderItem.id, 'received_quantity': 6},
        ],
      );
      expect(
        (await purchases.getPurchaseOrderById(order.id))!.status,
        PurchaseOrderStatus.received,
      );
      expect(await inventory.getCurrentStock(item.id), 10);

      await expectLater(
        purchases.receiveItems(
          purchaseOrderId: order.id,
          receivedLines: [
            {'purchase_order_item_id': orderItem.id, 'received_quantity': 1},
          ],
        ),
        throwsA(isA<StateError>()),
      );
      expect(await inventory.getCurrentStock(item.id), 10);
      expect(
        (await inventory.getStockTransactions(item.id))
            .where(
              (transaction) =>
                  transaction.transactionType ==
                  TransactionType.purchaseReceipt,
            )
            .length,
        2,
      );
    });

    test('a failed multi-line receipt rolls back all receipt rows', () async {
      final facility = await FacilityRepository(
        dbHelper: dbHelper,
      ).createFacility(name: 'کارگاه دریافت');
      final inventory = InventoryRepository(dbHelper: dbHelper);
      final firstItem = await inventory.createItem(
        name: 'کالای اول',
        code: 'ITEM-1',
        unit: 'عدد',
      );
      final secondItem = await inventory.createItem(
        name: 'کالای دوم',
        code: 'ITEM-2',
        unit: 'عدد',
      );
      final purchases = PurchaseRepository(dbHelper: dbHelper);
      final order = await purchases.createPurchaseOrder(
        facilityId: facility.id,
        supplierName: 'تأمین‌کننده',
        orderDate: '2026-10-15',
        items: [
          {'item_id': firstItem.id, 'ordered_quantity': 5, 'unit_price': 10},
          {'item_id': secondItem.id, 'ordered_quantity': 3, 'unit_price': 20},
        ],
      );
      final lines = await purchases.getOrderItems(order.id);

      await expectLater(
        purchases.receiveItems(
          purchaseOrderId: order.id,
          receivedLines: [
            {'purchase_order_item_id': lines[0].id, 'received_quantity': 2},
            {'purchase_order_item_id': lines[1].id, 'received_quantity': 4},
          ],
        ),
        throwsA(isA<StateError>()),
      );

      expect(await inventory.getCurrentStock(firstItem.id), 0);
      expect(await inventory.getCurrentStock(secondItem.id), 0);
      expect(
        (await purchases.getPurchaseOrderById(order.id))!.status,
        PurchaseOrderStatus.ordered,
      );
    });
  });

  group('Work-order and stock transactions', () {
    test(
      'failed material completion rolls back stock, materials, and task state',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه تعمیر');
        final asset = await AssetRepository(
          dbHelper: dbHelper,
        ).createAsset(facilityId: facility.id, name: 'پمپ', code: 'P-01');
        final workOrders = WorkOrderRepository(dbHelper: dbHelper);
        final workOrder = await workOrders.createWorkOrder(
          facilityId: facility.id,
          title: 'تعمیر پمپ',
          workOrderType: WorkOrderType.corrective,
        );
        await workOrders.addTaskToWorkOrder(
          workOrderId: workOrder.id,
          assetId: asset.id,
          title: 'تعویض قطعات',
        );
        final task = (await workOrders.getTasksForWorkOrder(
          workOrder.id,
        )).single;
        final inventory = InventoryRepository(dbHelper: dbHelper);
        final firstItem = await inventory.createItem(
          name: 'قطعه اول',
          code: 'PART-1',
          unit: 'عدد',
        );
        final secondItem = await inventory.createItem(
          name: 'قطعه دوم',
          code: 'PART-2',
          unit: 'عدد',
        );
        await inventory.adjustStock(
          itemId: firstItem.id,
          type: TransactionType.adjustmentIn,
          quantity: 5,
        );
        await inventory.adjustStock(
          itemId: secondItem.id,
          type: TransactionType.adjustmentIn,
          quantity: 1,
        );

        await expectLater(
          workOrders.completeTask(
            taskId: task.id,
            result: TaskResult.success,
            findings: null,
            laborMinutes: 20,
            downtimeMinutes: 10,
            consumedMaterials: [
              {'item_id': firstItem.id, 'quantity': 2},
              {'item_id': secondItem.id, 'quantity': 3},
            ],
          ),
          throwsA(isA<StateError>()),
        );

        expect(await inventory.getCurrentStock(firstItem.id), 5);
        expect(await inventory.getCurrentStock(secondItem.id), 1);
        expect(
          (await workOrders.getTasksForWorkOrder(workOrder.id)).single.status,
          TaskStatus.pending,
        );
        expect(await workOrders.getMaterialsForTask(task.id), isEmpty);
        expect((await inventory.getStockTransactions(firstItem.id)).length, 1);
        expect((await inventory.getStockTransactions(secondItem.id)).length, 1);
      },
    );

    test('cannot close a work order while a task is still open', () async {
      final facility = await FacilityRepository(
        dbHelper: dbHelper,
      ).createFacility(name: 'کارگاه بستن دستورکار');
      final asset = await AssetRepository(
        dbHelper: dbHelper,
      ).createAsset(facilityId: facility.id, name: 'موتور', code: 'M-01');
      final repository = WorkOrderRepository(dbHelper: dbHelper);
      final order = await repository.createWorkOrder(
        facilityId: facility.id,
        title: 'بازرسی موتور',
        workOrderType: WorkOrderType.preventive,
      );
      await repository.addTaskToWorkOrder(
        workOrderId: order.id,
        assetId: asset.id,
        title: 'بررسی یاتاقان',
      );

      await expectLater(
        repository.closeWorkOrder(order.id),
        throwsA(isA<StateError>()),
      );
      expect(
        (await repository.getWorkOrderById(order.id))!.status,
        WorkOrderStatus.open,
      );
    });
  });

  group('Maintenance scheduler', () {
    test(
      'generates due plan tasks and alerts once and skips future/inactive plans',
      () async {
        final db = await dbHelper.db;
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه زمان‌بندی');
        final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
          facilityId: facility.id,
          name: 'کمپرسور',
          code: 'COMP-01',
        );
        final plans = MaintenancePlanRepository(dbHelper: dbHelper);
        final dueDate = DateTime.now().subtract(const Duration(days: 1));
        final duePlan = await plans.createPlan(
          assetId: asset.id,
          title: 'سرویس هفتگی',
          scheduleType: ScheduleType.calendar,
          calendarIntervalValue: 1,
          calendarIntervalUnit: CalendarUnit.week,
          nextDueAt: AppDateUtils.toUtcIso(dueDate),
        );
        final futurePlan = await plans.createPlan(
          assetId: asset.id,
          title: 'سرویس آینده',
          scheduleType: ScheduleType.oneTime,
          oneTimeDueAt: AppDateUtils.toUtcIso(
            DateTime.now().add(const Duration(days: 30)),
          ),
        );
        final inactivePlan = await plans.createPlan(
          assetId: asset.id,
          title: 'برنامه غیرفعال',
          scheduleType: ScheduleType.calendar,
          calendarIntervalValue: 1,
          calendarIntervalUnit: CalendarUnit.day,
          nextDueAt: AppDateUtils.toUtcIso(dueDate),
        );
        await plans.updatePlan(inactivePlan.copyWith(isActive: false));

        await MaintenanceScheduler.runScheduler(db, facility.id);
        await MaintenanceScheduler.runScheduler(db, facility.id);

        final dueTasks = await db.query(
          'work_order_tasks',
          where: 'maintenance_plan_id = ? AND deleted_at IS NULL',
          whereArgs: [duePlan.id],
        );
        expect(dueTasks, hasLength(1));
        expect(
          dueTasks.single['source_occurrence_key'],
          'calendar:${AppDateUtils.formatDateOnly(dueDate)}',
        );
        final dueAlerts = await db.query(
          'alert_events',
          where: 'maintenance_plan_id = ? AND deleted_at IS NULL',
          whereArgs: [duePlan.id],
        );
        expect(dueAlerts, hasLength(1));

        expect(
          await db.query(
            'work_order_tasks',
            where: 'maintenance_plan_id = ? AND deleted_at IS NULL',
            whereArgs: [futurePlan.id],
          ),
          isEmpty,
        );
        expect(
          await db.query(
            'work_order_tasks',
            where: 'maintenance_plan_id = ? AND deleted_at IS NULL',
            whereArgs: [inactivePlan.id],
          ),
          isEmpty,
        );
      },
    );
  });
}
