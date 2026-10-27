import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/enums/app_enums.dart';
import 'package:maintenance_app/core/storage/database/database_helper.dart';
import 'package:maintenance_app/core/utils/date_utils.dart';
import 'package:maintenance_app/features/alerts/repositories/alert_repository.dart';
import 'package:maintenance_app/features/assets/repositories/asset_reading_repository.dart';
import 'package:maintenance_app/features/assets/repositories/asset_repository.dart';
import 'package:maintenance_app/features/dashboard/repositories/dashboard_repository.dart';
import 'package:maintenance_app/features/facilities/repositories/facility_repository.dart';
import 'package:maintenance_app/features/inventory/repositories/inventory_repository.dart';
import 'package:maintenance_app/features/maintenance/repositories/maintenance_plan_repository.dart';
import 'package:maintenance_app/features/maintenance/services/maintenance_scheduler.dart';
import 'package:maintenance_app/features/purchases/repositories/purchase_repository.dart';
import 'package:maintenance_app/features/reports/repositories/report_repository.dart';
import 'package:maintenance_app/features/work_orders/repositories/work_order_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    await dbHelper.initialize(inMemory: true);
  });

  group('Purchase receiving and inventory ledger', () {
    test(
      'supplier suggestions and receipt details use stored order data',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه رسید');
        final inventory = InventoryRepository(dbHelper: dbHelper);
        final item = await inventory.createItem(
          name: 'فیلتر روغن',
          code: 'FLT-01',
          unit: 'عدد',
        );
        final purchases = PurchaseRepository(dbHelper: dbHelper);
        final order = await purchases.createPurchaseOrder(
          facilityId: facility.id,
          supplierName: 'تأمین‌کننده الف',
          orderDate: '2026-10-28',
          items: [
            {'item_id': item.id, 'ordered_quantity': 5, 'unit_price': 125},
          ],
        );
        final orderItem = (await purchases.getOrderItems(order.id)).single;

        await purchases.receiveItems(
          purchaseOrderId: order.id,
          receivedLines: [
            {'purchase_order_item_id': orderItem.id, 'received_quantity': 2},
          ],
        );

        final receipt = (await inventory.getStockTransactions(item.id)).single;
        final receiptDetail = await inventory.getPurchaseReceiptDetail(
          receipt.id,
        );
        expect(await purchases.getSupplierNames(facility.id), [
          'تأمین‌کننده الف',
        ]);
        expect(await purchases.getReceivedQuantities(order.id), {
          orderItem.id: 2,
        });
        expect(receiptDetail?.purchaseOrderId, order.id);
        expect(receiptDetail?.purchaseOrderNumber, order.purchaseOrderNumber);
        expect(receiptDetail?.itemName, item.name);
        expect(receiptDetail?.quantity, 2);
        expect(receiptDetail?.unitCost, 125);
        final ledger = await inventory.getStockLedger(
          transactionType: TransactionType.purchaseReceipt,
          itemId: item.id,
          fromDate: DateTime.now().subtract(const Duration(days: 1)),
          toDate: DateTime.now().add(const Duration(days: 1)),
        );
        expect(ledger, hasLength(1));
        expect(ledger.single.itemCode, item.code);
        expect(ledger.single.transaction.id, receipt.id);
        expect(
          await inventory.getStockLedger(
            transactionType: TransactionType.adjustmentIn,
            itemId: item.id,
          ),
          isEmpty,
        );
      },
    );

    test(
      'purchase lines preserve received history and allow safe changes',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه ویرایش سفارش');
        final inventory = InventoryRepository(dbHelper: dbHelper);
        final firstItem = await inventory.createItem(
          name: 'بلبرینگ',
          code: 'BRG-EDIT-1',
          unit: 'عدد',
        );
        final secondItem = await inventory.createItem(
          name: 'فیلتر',
          code: 'FLT-EDIT-1',
          unit: 'عدد',
        );
        final purchases = PurchaseRepository(dbHelper: dbHelper);
        final order = await purchases.createPurchaseOrder(
          facilityId: facility.id,
          supplierName: 'تأمین‌کننده',
          orderDate: '2026-10-28',
          items: [
            {'item_id': firstItem.id, 'ordered_quantity': 4, 'unit_price': 20},
          ],
        );

        await purchases.updatePurchaseOrder(
          order: order,
          items: [
            {'item_id': firstItem.id, 'ordered_quantity': 6, 'unit_price': 25},
            {'item_id': secondItem.id, 'ordered_quantity': 3, 'unit_price': 10},
          ],
        );
        var lines = await purchases.getOrderItems(order.id);
        expect(lines, hasLength(2));
        expect(
          lines
              .firstWhere((line) => line.itemId == firstItem.id)
              .orderedQuantity,
          6,
        );

        await purchases.receiveItems(
          purchaseOrderId: order.id,
          receivedLines: [
            {
              'purchase_order_item_id': lines
                  .firstWhere((line) => line.itemId == firstItem.id)
                  .id,
              'received_quantity': 1,
            },
          ],
        );

        final updatedOrder = await purchases.updatePurchaseOrder(
          order: order,
          items: [
            {'item_id': firstItem.id, 'ordered_quantity': 8, 'unit_price': 30},
            {'item_id': secondItem.id, 'ordered_quantity': 3, 'unit_price': 10},
          ],
        );
        lines = await purchases.getOrderItems(order.id);
        expect(lines, hasLength(2));
        expect(
          lines
              .firstWhere((line) => line.itemId == firstItem.id)
              .orderedQuantity,
          8,
        );
        expect(updatedOrder.status, PurchaseOrderStatus.partiallyReceived);
        final receipts = (await inventory.getStockTransactions(firstItem.id))
            .where(
              (transaction) =>
                  transaction.transactionType ==
                  TransactionType.purchaseReceipt,
            );
        expect(receipts.single.unitCost, 25);

        await expectLater(
          purchases.updatePurchaseOrder(
            order: updatedOrder,
            items: [
              {
                'item_id': firstItem.id,
                'ordered_quantity': 0.5,
                'unit_price': 30,
              },
              {
                'item_id': secondItem.id,
                'ordered_quantity': 3,
                'unit_price': 10,
              },
            ],
          ),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          purchases.updatePurchaseOrder(
            order: updatedOrder,
            items: [
              {
                'item_id': secondItem.id,
                'ordered_quantity': 3,
                'unit_price': 10,
              },
            ],
          ),
          throwsA(isA<StateError>()),
        );
        expect(await purchases.getOrderItems(order.id), hasLength(2));

        final completedByAdjustment = await purchases.updatePurchaseOrder(
          order: updatedOrder,
          items: [
            {'item_id': firstItem.id, 'ordered_quantity': 1, 'unit_price': 30},
          ],
        );
        expect(completedByAdjustment.status, PurchaseOrderStatus.received);
        await expectLater(
          purchases.updatePurchaseOrder(
            order: completedByAdjustment,
            items: [
              {
                'item_id': firstItem.id,
                'ordered_quantity': 2,
                'unit_price': 30,
              },
              {
                'item_id': secondItem.id,
                'ordered_quantity': 3,
                'unit_price': 10,
              },
            ],
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'fully received and cancelled orders reject changes and receipts',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه سفارش بسته');
        final inventory = InventoryRepository(dbHelper: dbHelper);
        final item = await inventory.createItem(
          name: 'مهره',
          code: 'NUT-CLOSED',
          unit: 'عدد',
        );
        final purchases = PurchaseRepository(dbHelper: dbHelper);
        final order = await purchases.createPurchaseOrder(
          facilityId: facility.id,
          supplierName: 'تأمین‌کننده',
          orderDate: '2026-10-28',
          items: [
            {'item_id': item.id, 'ordered_quantity': 2, 'unit_price': 5},
          ],
        );
        final orderItem = (await purchases.getOrderItems(order.id)).single;
        await purchases.receiveItems(
          purchaseOrderId: order.id,
          receivedLines: [
            {'purchase_order_item_id': orderItem.id, 'received_quantity': 2},
          ],
        );
        final receivedOrder = (await purchases.getPurchaseOrderById(order.id))!;
        expect(receivedOrder.status, PurchaseOrderStatus.received);
        await expectLater(
          purchases.updatePurchaseOrder(
            order: receivedOrder,
            items: [
              {'item_id': item.id, 'ordered_quantity': 3, 'unit_price': 5},
            ],
          ),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          purchases.receiveItems(
            purchaseOrderId: order.id,
            receivedLines: [
              {'purchase_order_item_id': orderItem.id, 'received_quantity': 1},
            ],
          ),
          throwsA(isA<StateError>()),
        );

        final cancelledOrder = await purchases.createPurchaseOrder(
          facilityId: facility.id,
          supplierName: 'تأمین‌کننده',
          orderDate: '2026-10-28',
          items: [
            {'item_id': item.id, 'ordered_quantity': 2, 'unit_price': 5},
          ],
        );
        final cancelledOrderItem = (await purchases.getOrderItems(
          cancelledOrder.id,
        )).single;
        await (await dbHelper.db).update(
          'purchase_orders',
          {'status': 'CANCELLED'},
          where: 'id = ?',
          whereArgs: [cancelledOrder.id],
        );
        await expectLater(
          purchases.receiveItems(
            purchaseOrderId: cancelledOrder.id,
            receivedLines: [
              {
                'purchase_order_item_id': cancelledOrderItem.id,
                'received_quantity': 1,
              },
            ],
          ),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          purchases.updatePurchaseOrder(
            order: (await purchases.getPurchaseOrderById(cancelledOrder.id))!,
            items: [
              {'item_id': item.id, 'ordered_quantity': 3, 'unit_price': 5},
            ],
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

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
      'operational report summarizes real tasks, consumption, and receipts',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه گزارش');
        final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
          facilityId: facility.id,
          name: 'پمپ گزارش',
          code: 'P-REPORT',
        );
        final inventory = InventoryRepository(dbHelper: dbHelper);
        final item = await inventory.createItem(
          name: 'فیلتر',
          code: 'FILTER-REPORT',
          unit: 'عدد',
          defaultUnitCost: 12,
        );
        await inventory.adjustStock(
          itemId: item.id,
          type: TransactionType.adjustmentIn,
          quantity: 5,
          unitCost: 12,
        );

        final workOrders = WorkOrderRepository(dbHelper: dbHelper);
        final order = await workOrders.createWorkOrder(
          facilityId: facility.id,
          title: 'سرویس پمپ',
          workOrderType: WorkOrderType.corrective,
        );
        await workOrders.addTaskToWorkOrder(
          workOrderId: order.id,
          assetId: asset.id,
          title: 'تعویض فیلتر',
        );
        final task = (await workOrders.getTasksForWorkOrder(order.id)).single;
        await workOrders.completeTask(
          taskId: task.id,
          result: TaskResult.success,
          findings: null,
          laborMinutes: 45,
          downtimeMinutes: 20,
          consumedMaterials: [
            {'item_id': item.id, 'quantity': 2},
          ],
        );

        final purchases = PurchaseRepository(dbHelper: dbHelper);
        final purchaseOrder = await purchases.createPurchaseOrder(
          facilityId: facility.id,
          supplierName: 'تأمین‌کننده گزارش',
          orderDate: DateTime.now().toIso8601String(),
          items: [
            {'item_id': item.id, 'ordered_quantity': 3, 'unit_price': 15},
          ],
        );
        final orderItem = (await purchases.getOrderItems(
          purchaseOrder.id,
        )).single;
        await purchases.receiveItems(
          purchaseOrderId: purchaseOrder.id,
          receivedLines: [
            {'purchase_order_item_id': orderItem.id, 'received_quantity': 3},
          ],
        );

        final today = DateTime.now();
        final start = DateTime(today.year, today.month, today.day);
        final report = await ReportRepository(dbHelper: dbHelper)
            .getOperationalReport(
              facilityId: facility.id,
              start: start,
              endExclusive: start.add(const Duration(days: 1)),
            );

        expect(report.completedTasks, 1);
        expect(report.laborMinutes, 45);
        expect(report.downtimeMinutes, 20);
        expect(report.consumedTransactionCount, 1);
        expect(report.consumedCost, 24);
        expect(report.materialUsage.single.quantity, 2);
        expect(report.receiptCount, 1);
        expect(report.receivedCost, 45);
        expect(report.receiptTrend.single.receiptCount, 1);
        expect(report.receipts.single.itemName, 'فیلتر');
      },
    );

    test(
      'dashboard trends are range-aware and scoped to their facility',
      () async {
        final facilities = FacilityRepository(dbHelper: dbHelper);
        final firstFacility = await facilities.createFacility(
          name: 'کارگاه نمودار اول',
        );
        final secondFacility = await facilities.createFacility(
          name: 'کارگاه نمودار دوم',
        );
        final assets = AssetRepository(dbHelper: dbHelper);
        final firstAsset = await assets.createAsset(
          facilityId: firstFacility.id,
          name: 'پمپ اول',
          code: 'P-DASH-1',
        );
        final secondAsset = await assets.createAsset(
          facilityId: secondFacility.id,
          name: 'پمپ دوم',
          code: 'P-DASH-2',
        );
        final inventory = InventoryRepository(dbHelper: dbHelper);
        final item = await inventory.createItem(
          name: 'روغن نمودار',
          code: 'OIL-DASH',
          unit: 'لیتر',
        );
        await inventory.adjustStock(
          itemId: item.id,
          type: TransactionType.adjustmentIn,
          quantity: 5,
        );

        final workOrders = WorkOrderRepository(dbHelper: dbHelper);
        final firstOrder = await workOrders.createWorkOrder(
          facilityId: firstFacility.id,
          title: 'کار اول',
          workOrderType: WorkOrderType.corrective,
        );
        await workOrders.addTaskToWorkOrder(
          workOrderId: firstOrder.id,
          assetId: firstAsset.id,
          title: 'تعمیر اول',
        );
        final firstTask = (await workOrders.getTasksForWorkOrder(
          firstOrder.id,
        )).single;
        await workOrders.completeTask(
          taskId: firstTask.id,
          result: TaskResult.success,
          findings: null,
          laborMinutes: null,
          downtimeMinutes: null,
          consumedMaterials: [
            {'item_id': item.id, 'quantity': 2},
          ],
        );

        final secondOrder = await workOrders.createWorkOrder(
          facilityId: secondFacility.id,
          title: 'کار دوم',
          workOrderType: WorkOrderType.corrective,
        );
        await workOrders.addTaskToWorkOrder(
          workOrderId: secondOrder.id,
          assetId: secondAsset.id,
          title: 'تعمیر دوم',
        );
        final secondTask = (await workOrders.getTasksForWorkOrder(
          secondOrder.id,
        )).single;
        await workOrders.completeTask(
          taskId: secondTask.id,
          result: TaskResult.success,
          findings: null,
          laborMinutes: null,
          downtimeMinutes: null,
        );

        final dashboard = DashboardRepository(dbHelper: dbHelper);
        final firstTaskTrend = await dashboard.getCompletedTaskTrend(
          firstFacility.id,
          days: 30,
        );
        final firstMaterialTrend = await dashboard.getMaterialConsumptionTrend(
          firstFacility.id,
          days: 30,
        );
        final secondMaterialTrend = await dashboard.getMaterialConsumptionTrend(
          secondFacility.id,
          days: 7,
        );

        expect(firstTaskTrend, hasLength(30));
        expect(
          firstTaskTrend.fold<int>(
            0,
            (sum, point) => sum + (point['count'] as int),
          ),
          1,
        );
        expect(
          firstMaterialTrend.fold<double>(
            0,
            (sum, point) => sum + (point['quantity'] as double),
          ),
          2,
        );
        expect(
          secondMaterialTrend.fold<double>(
            0,
            (sum, point) => sum + (point['quantity'] as double),
          ),
          0,
        );
      },
    );

    test(
      'asset task history is scoped to the asset and active work orders',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه گزارش تجهیز');
        final assets = AssetRepository(dbHelper: dbHelper);
        final firstAsset = await assets.createAsset(
          facilityId: facility.id,
          name: 'پمپ اول',
          code: 'P-CHART-1',
        );
        final secondAsset = await assets.createAsset(
          facilityId: facility.id,
          name: 'پمپ دوم',
          code: 'P-CHART-2',
        );
        final workOrders = WorkOrderRepository(dbHelper: dbHelper);
        final order = await workOrders.createWorkOrder(
          facilityId: facility.id,
          title: 'بررسی پمپ‌ها',
          workOrderType: WorkOrderType.preventive,
        );
        await workOrders.addTaskToWorkOrder(
          workOrderId: order.id,
          assetId: firstAsset.id,
          title: 'بازرسی اول',
        );
        await workOrders.addTaskToWorkOrder(
          workOrderId: order.id,
          assetId: secondAsset.id,
          title: 'بازرسی دوم',
        );
        final deletedOrder = await workOrders.createWorkOrder(
          facilityId: facility.id,
          title: 'دستورکار حذف‌شده',
          workOrderType: WorkOrderType.preventive,
        );
        await workOrders.addTaskToWorkOrder(
          workOrderId: deletedOrder.id,
          assetId: firstAsset.id,
          title: 'وظیفه حذف‌شده',
        );
        final db = await dbHelper.db;
        await db.update(
          'work_orders',
          {'deleted_at': AppDateUtils.nowUtcIso()},
          where: 'id = ?',
          whereArgs: [deletedOrder.id],
        );

        expect(
          (await workOrders.getTasksForAsset(
            firstAsset.id,
          )).map((task) => task.title),
          ['بازرسی اول'],
        );
        expect(await workOrders.getTasksForAsset('missing-asset'), isEmpty);
      },
    );

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

  group('Asset reading corrections', () {
    test(
      'correction preserves history and leaves generated condition task',
      () async {
        final db = await dbHelper.db;
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه اصلاح خوانش');
        final asset = await AssetRepository(
          dbHelper: dbHelper,
        ).createAsset(facilityId: facility.id, name: 'پمپ', code: 'P-READING');
        await MaintenancePlanRepository(dbHelper: dbHelper).createPlan(
          assetId: asset.id,
          title: 'کنترل دمای بالا',
          scheduleType: ScheduleType.condition,
          conditionConfigJson:
              '{"metric":"temperature","operator":"gte","threshold":80,"unit":"°C"}',
        );
        final readings = AssetReadingRepository(dbHelper: dbHelper);
        final original = await readings.recordReading(
          assetId: asset.id,
          metricName: 'temperature',
          value: 90,
          unit: '°C',
          recordedAt: '2026-10-15T10:00:00.000Z',
        );
        final correction = await readings.correctReading(
          readingId: original.id,
          value: 70,
          unit: '°C',
          recordedAt: '2026-10-15T10:00:00.000Z',
          reason: 'اصلاح مقدار اشتباه',
        );

        expect(correction.generatedConditionTaskCount, 0);
        expect(correction.previouslyTriggeredTaskCount, 1);
        final history = await readings.getReadings(asset.id);
        final correctedOriginal = history.singleWhere(
          (reading) => reading.id == original.id,
        );
        expect(correctedOriginal.supersededByReadingId, correction.reading.id);
        expect(correctedOriginal.correctionReason, 'اصلاح مقدار اشتباه');
        expect(
          (await readings.getLatestReading(asset.id, 'temperature'))?.id,
          correction.reading.id,
        );
        await readings.recordReading(
          assetId: asset.id,
          metricName: 'temperature',
          value: 91,
          unit: '°C',
        );
        final tasks = await db.query(
          'work_order_tasks',
          where: 'maintenance_plan_id = ?',
          whereArgs: [
            (await MaintenancePlanRepository(
              dbHelper: dbHelper,
            ).getPlans(asset.id)).single.id,
          ],
        );
        expect(tasks, hasLength(1));
      },
    );

    test('corrected reading that meets condition generates one task', () async {
      final db = await dbHelper.db;
      final facility = await FacilityRepository(
        dbHelper: dbHelper,
      ).createFacility(name: 'کارگاه شرط اصلاحی');
      final asset = await AssetRepository(
        dbHelper: dbHelper,
      ).createAsset(facilityId: facility.id, name: 'موتور', code: 'M-READING');
      await MaintenancePlanRepository(dbHelper: dbHelper).createPlan(
        assetId: asset.id,
        title: 'کنترل دمای بالا',
        scheduleType: ScheduleType.condition,
        conditionConfigJson:
            '{"metric":"temperature","operator":"gte","threshold":80,"unit":"°C"}',
      );
      final readings = AssetReadingRepository(dbHelper: dbHelper);
      final original = await readings.recordReading(
        assetId: asset.id,
        metricName: 'temperature',
        value: 70,
        unit: '°C',
      );

      final correction = await readings.correctReading(
        readingId: original.id,
        value: 90,
        unit: '°C',
        recordedAt: original.recordedAt,
        reason: 'اصلاح مقدار ثبت‌شده',
      );

      expect(correction.generatedConditionTaskCount, 1);
      expect(correction.previouslyTriggeredTaskCount, 0);
      final tasks = await db.query(
        'work_order_tasks',
        where: 'triggering_reading_id = ?',
        whereArgs: [correction.reading.id],
      );
      expect(tasks, hasLength(1));
    });

    test(
      'condition plans ignore readings recorded in incompatible units',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه واحد خوانش');
        final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
          facilityId: facility.id,
          name: 'پمپ واحد',
          code: 'P-UNIT',
        );
        final plan = await MaintenancePlanRepository(dbHelper: dbHelper).createPlan(
          assetId: asset.id,
          title: 'حد دمایی',
          scheduleType: ScheduleType.condition,
          conditionConfigJson:
              '{"metric":"temperature","operator":"gte","threshold":80,"unit":"°C"}',
        );
        final readings = AssetReadingRepository(dbHelper: dbHelper);

        await readings.recordReading(
          assetId: asset.id,
          metricName: 'temperature',
          value: 100,
          unit: '°F',
        );
        final db = await dbHelper.db;
        expect(
          await db.query(
            'work_order_tasks',
            where: 'maintenance_plan_id = ?',
            whereArgs: [plan.id],
          ),
          isEmpty,
        );

        await readings.recordReading(
          assetId: asset.id,
          metricName: 'temperature',
          value: 85,
          unit: '°C',
        );
        expect(
          await db.query(
            'work_order_tasks',
            where: 'maintenance_plan_id = ?',
            whereArgs: [plan.id],
          ),
          hasLength(1),
        );
      },
    );

    test(
      'meter plan creates one due task and advances from completion reading',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه کارکرد');
        final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
          facilityId: facility.id,
          name: 'کمپرسور',
          code: 'COMP-METER',
        );
        final plans = MaintenancePlanRepository(dbHelper: dbHelper);
        await expectLater(
          plans.createPlan(
            assetId: asset.id,
            title: 'برنامه کارکرد ناقص',
            scheduleType: ScheduleType.meter,
            meterName: 'operating_hours',
            meterInterval: 100,
            meterUnit: 'h',
          ),
          throwsA(isA<ArgumentError>()),
        );
        final item = await InventoryRepository(dbHelper: dbHelper).createItem(
          name: 'فیلتر کمپرسور',
          code: 'COMP-METER-FILTER',
          unit: 'عدد',
        );
        final plan = await plans.createPlan(
          assetId: asset.id,
          title: 'سرویس بر اساس ساعت کارکرد',
          scheduleType: ScheduleType.meter,
          meterName: 'operating_hours',
          meterInterval: 100,
          meterUnit: 'h',
          nextDueMeterValue: 500,
          materials: [
            {'item_id': item.id, 'planned_quantity': 1},
          ],
        );
        final readings = AssetReadingRepository(dbHelper: dbHelper);

        await readings.recordReading(
          assetId: asset.id,
          metricName: 'operating_hours',
          value: 499,
          unit: 'h',
        );
        await readings.recordReading(
          assetId: asset.id,
          metricName: 'operating_hours',
          value: 900,
          unit: 'minutes',
        );
        expect(
          await WorkOrderRepository(
            dbHelper: dbHelper,
          ).getTasksForMaintenancePlan(plan.id),
          isEmpty,
        );
        final db = await dbHelper.db;

        await readings.recordReading(
          assetId: asset.id,
          metricName: 'operating_hours',
          value: 520,
          unit: 'h',
        );
        await readings.recordReading(
          assetId: asset.id,
          metricName: 'operating_hours',
          value: 530,
          unit: 'h',
        );
        final tasks = await WorkOrderRepository(
          dbHelper: dbHelper,
        ).getTasksForMaintenancePlan(plan.id);
        expect(tasks, hasLength(1));
        expect(tasks.single.plannedMeterValue, 500);
        final seededMaterials = await db.query(
          'work_order_materials',
          where: 'work_order_task_id = ?',
          whereArgs: [tasks.single.id],
        );
        expect(seededMaterials, hasLength(1));
        expect(seededMaterials.single['item_id'], item.id);
        expect(seededMaterials.single['planned_quantity'], 1);

        await expectLater(
          WorkOrderRepository(dbHelper: dbHelper).completeTask(
            taskId: tasks.single.id,
            result: TaskResult.success,
            findings: null,
            laborMinutes: 20,
            downtimeMinutes: 0,
            completionMeterValue: 499,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          (await WorkOrderRepository(
            dbHelper: dbHelper,
          ).getTasksForMaintenancePlan(plan.id)).single.status,
          TaskStatus.pending,
        );
        expect((await plans.getPlanById(plan.id))?.nextDueMeterValue, 500);

        await WorkOrderRepository(dbHelper: dbHelper).completeTask(
          taskId: tasks.single.id,
          result: TaskResult.success,
          findings: null,
          laborMinutes: 20,
          downtimeMinutes: 0,
          completionMeterValue: 530,
        );
        final updatedPlan = await plans.getPlanById(plan.id);
        expect(updatedPlan?.lastCompletedMeterValue, 530);
        expect(updatedPlan?.nextDueMeterValue, 630);
        final completedTasks = await WorkOrderRepository(
          dbHelper: dbHelper,
        ).getTasksForMaintenancePlan(plan.id);
        expect(completedTasks.single.completionMeterValue, 530);
        expect(completedTasks.single.completionMeterName, 'operating_hours');
        expect(completedTasks.single.completionMeterUnit, 'h');
        expect(
          (await readings.getLatestReading(asset.id, 'operating_hours'))?.value,
          530,
        );
        final alerts = await db.query(
          'alert_events',
          where: 'work_order_task_id = ?',
          whereArgs: [tasks.single.id],
        );
        expect(alerts, hasLength(1));
        expect(alerts.single['status'], 'RESOLVED');
        await expectLater(
          readings.recordReading(
            assetId: asset.id,
            metricName: 'operating_hours',
            value: 529,
            unit: 'h',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'meter readings reject incompatible units and decreasing counters',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه کنترل کنتور');
        final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
          facilityId: facility.id,
          name: 'موتور کنتور',
          code: 'METER-VALIDATION',
        );
        final plans = MaintenancePlanRepository(dbHelper: dbHelper);
        await plans.createPlan(
          assetId: asset.id,
          title: 'کنترل ساعت کار',
          scheduleType: ScheduleType.meter,
          meterName: 'operating_hours',
          meterInterval: 100,
          meterUnit: 'h',
          nextDueMeterValue: 500,
        );
        final readings = AssetReadingRepository(dbHelper: dbHelper);
        await readings.recordReading(
          assetId: asset.id,
          metricName: 'operating_hours',
          value: 510,
          unit: 'h',
        );
        await readings.recordReading(
          assetId: asset.id,
          metricName: 'operating_hours',
          value: 20,
          unit: 'minutes',
        );
        await expectLater(
          readings.recordReading(
            assetId: asset.id,
            metricName: 'operating_hours',
            value: 509,
            unit: 'h',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'plan materials save, update, and soft-delete with plan changes',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه مواد برنامه');
        final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
          facilityId: facility.id,
          name: 'پمپ مواد',
          code: 'P-MATERIALS',
        );
        final inventory = InventoryRepository(dbHelper: dbHelper);
        final firstItem = await inventory.createItem(
          name: 'فیلتر برنامه‌ای',
          code: 'PLAN-FILTER',
          unit: 'عدد',
        );
        final secondItem = await inventory.createItem(
          name: 'روغن برنامه‌ای',
          code: 'PLAN-OIL',
          unit: 'لیتر',
        );
        final plans = MaintenancePlanRepository(dbHelper: dbHelper);
        final plan = await plans.createPlan(
          assetId: asset.id,
          title: 'سرویس دارای اقلام',
          scheduleType: ScheduleType.manual,
          materials: [
            {
              'item_id': firstItem.id,
              'planned_quantity': 2,
              'notes': 'در هر سرویس',
            },
          ],
        );
        final firstMaterial = (await plans.getPlanMaterials(plan.id)).single;
        expect(firstMaterial.plannedQuantity, 2);

        await plans.updatePlan(
          plan.copyWith(title: 'سرویس به‌روزشده'),
          materials: [
            {
              'item_id': firstItem.id,
              'planned_quantity': 3,
              'notes': 'مقدار اصلاح‌شده',
            },
            {'item_id': secondItem.id, 'planned_quantity': 1.5},
          ],
        );
        var materials = await plans.getPlanMaterials(plan.id);
        expect(materials, hasLength(2));
        expect(
          materials
              .singleWhere((material) => material.itemId == firstItem.id)
              .plannedQuantity,
          3,
        );

        await plans.updatePlan(
          plan.copyWith(title: 'سرویس با قلم دوم'),
          materials: [
            {'item_id': secondItem.id, 'planned_quantity': 4},
          ],
        );
        materials = await plans.getPlanMaterials(plan.id);
        expect(materials, hasLength(1));
        expect(materials.single.itemId, secondItem.id);
        expect(materials.single.plannedQuantity, 4);
        final db = await dbHelper.db;
        final historicalFirst = await db.query(
          'maintenance_plan_materials',
          where: 'maintenance_plan_id = ? AND item_id = ?',
          whereArgs: [plan.id, firstItem.id],
        );
        expect(historicalFirst.single['deleted_at'], isNotNull);

        final formerFirstId = historicalFirst.single['id'];
        await plans.updatePlan(
          plan.copyWith(title: 'سرویس با فیلتر دوباره'),
          materials: [
            {'item_id': firstItem.id, 'planned_quantity': 5},
          ],
        );
        materials = await plans.getPlanMaterials(plan.id);
        expect(materials, hasLength(1));
        expect(materials.single.itemId, firstItem.id);
        expect(materials.single.id, formerFirstId);
        expect(materials.single.plannedQuantity, 5);
      },
    );

    test(
      'failed plan material save rolls back plan create and plan updates',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه بازگشت مواد');
        final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
          facilityId: facility.id,
          name: 'پمپ بازگشت',
          code: 'P-MATERIAL-ROLLBACK',
        );
        final plans = MaintenancePlanRepository(dbHelper: dbHelper);
        await expectLater(
          plans.createPlan(
            assetId: asset.id,
            title: 'برنامه نامعتبر مواد',
            scheduleType: ScheduleType.manual,
            materials: [
              {'item_id': 'missing-item', 'planned_quantity': 1},
            ],
          ),
          throwsA(isA<ArgumentError>()),
        );

        final plan = await plans.createPlan(
          assetId: asset.id,
          title: 'برنامه محفوظ',
          scheduleType: ScheduleType.manual,
        );
        await expectLater(
          plans.updatePlan(
            plan.copyWith(title: 'نباید ذخیره شود'),
            materials: [
              {'item_id': 'missing-item', 'planned_quantity': 1},
            ],
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect((await plans.getPlanById(plan.id))?.title, 'برنامه محفوظ');
        expect(await plans.getPlanMaterials(plan.id), isEmpty);
      },
    );
  });

  group('Maintenance scheduler', () {
    test('new plans preserve their active setting', () async {
      final facility = await FacilityRepository(
        dbHelper: dbHelper,
      ).createFacility(name: 'کارگاه برنامه غیرفعال');
      final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
        facilityId: facility.id,
        name: 'پمپ غیرفعال',
        code: 'P-INACTIVE',
      );
      final repository = MaintenancePlanRepository(dbHelper: dbHelper);

      final plan = await repository.createPlan(
        assetId: asset.id,
        title: 'برنامه در انتظار فعال‌سازی',
        scheduleType: ScheduleType.manual,
        isActive: false,
      );

      expect(plan.isActive, isFalse);
      expect((await repository.getPlanById(plan.id))?.isActive, isFalse);
      expect(await repository.getAllActivePlans(facility.id), isEmpty);
    });

    test(
      'rejects invalid schedules and clears stale fields when changing type',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه اعتبارسنجی');
        final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
          facilityId: facility.id,
          name: 'پمپ اعتبارسنجی',
          code: 'P-VALIDATION',
        );
        final plans = MaintenancePlanRepository(dbHelper: dbHelper);

        await expectLater(
          plans.createPlan(
            assetId: asset.id,
            title: 'برنامه نامعتبر',
            scheduleType: ScheduleType.calendar,
          ),
          throwsArgumentError,
        );
        await expectLater(
          plans.createPlan(
            assetId: asset.id,
            title: 'شرط نامعتبر',
            scheduleType: ScheduleType.condition,
            conditionConfigJson: '{invalid',
          ),
          throwsArgumentError,
        );

        final calendarPlan = await plans.createPlan(
          assetId: asset.id,
          title: 'تبدیل زمان‌بندی',
          scheduleType: ScheduleType.calendar,
          calendarIntervalValue: 7,
          calendarIntervalUnit: CalendarUnit.day,
        );
        final updated = await plans.updatePlan(
          calendarPlan.copyWith(
            scheduleType: ScheduleType.manual,
            clearScheduleFields: true,
          ),
        );

        expect(updated.nextDueAt, isNull);
        expect(updated.calendarIntervalValue, isNull);
        expect(updated.calendarIntervalUnit, isNull);
        expect(updated.oneTimeDueAt, isNull);
        expect(updated.conditionConfigJson, isNull);
      },
    );

    test(
      'plan execution history excludes soft-deleted work orders and tasks',
      () async {
        final facility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه سابقه برنامه');
        final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
          facilityId: facility.id,
          name: 'موتور سابقه',
          code: 'M-PLAN-HISTORY',
        );
        final plan = await MaintenancePlanRepository(dbHelper: dbHelper)
            .createPlan(
              assetId: asset.id,
              title: 'بازرسی برنامه',
              scheduleType: ScheduleType.manual,
            );
        final workOrders = WorkOrderRepository(dbHelper: dbHelper);
        final order = await workOrders.createWorkOrder(
          facilityId: facility.id,
          title: 'دستورکار مرتبط',
          workOrderType: WorkOrderType.preventive,
        );
        await workOrders.addTaskToWorkOrder(
          workOrderId: order.id,
          assetId: asset.id,
          maintenancePlanId: plan.id,
          title: 'وظیفه مرتبط',
        );
        final task = (await workOrders.getTasksForWorkOrder(order.id)).single;

        expect(
          (await workOrders.getTasksForMaintenancePlan(plan.id)).single.id,
          task.id,
        );
        final db = await dbHelper.db;
        await db.update(
          'work_order_tasks',
          {'deleted_at': AppDateUtils.nowUtcIso()},
          where: 'id = ?',
          whereArgs: [task.id],
        );
        expect(await workOrders.getTasksForMaintenancePlan(plan.id), isEmpty);
      },
    );

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
        final otherFacility = await FacilityRepository(
          dbHelper: dbHelper,
        ).createFacility(name: 'کارگاه دیگر');
        final otherAsset = await AssetRepository(dbHelper: dbHelper)
            .createAsset(
              facilityId: otherFacility.id,
              name: 'کمپرسور دیگر',
              code: 'COMP-OTHER',
            );
        final otherFacilityPlan = await plans.createPlan(
          assetId: otherAsset.id,
          title: 'برنامه کارگاه دیگر',
          scheduleType: ScheduleType.calendar,
          calendarIntervalValue: 1,
          calendarIntervalUnit: CalendarUnit.day,
          nextDueAt: AppDateUtils.toUtcIso(dueDate),
        );

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
        expect(
          await db.query(
            'work_order_tasks',
            where: 'maintenance_plan_id = ? AND deleted_at IS NULL',
            whereArgs: [otherFacilityPlan.id],
          ),
          isEmpty,
        );
      },
    );

    test(
      'AlertRepository reconcileAndGetAlerts generates low stock and overdue task alerts',
      () async {
        final facilityRepo = FacilityRepository(dbHelper: dbHelper);
        final inventoryRepo = InventoryRepository(dbHelper: dbHelper);
        final alertRepo = AlertRepository(dbHelper: dbHelper);

        final facility = await facilityRepo.createFacility(
          name: 'کارگاه هشدارها',
        );

        // Create an inventory item with 0 stock and min stock = 10
        final item = await inventoryRepo.createItem(
          name: 'روغن هیدرولیک V46',
          code: 'OIL-46',
          unit: 'لیتر',
          minimumStock: 10,
        );

        // Reconcile alerts
        var alerts = await alertRepo.reconcileAndGetAlerts(facility.id);
        expect(
          alerts.any(
            (a) =>
                a.inventoryItemId == item.id &&
                a.alertType == AlertType.lowStock,
          ),
          isTrue,
        );

        // Replenish stock via adjustment
        await inventoryRepo.adjustStock(
          itemId: item.id,
          type: TransactionType.adjustmentIn,
          quantity: 50,
        );

        // Reconcile alerts again
        alerts = await alertRepo.reconcileAndGetAlerts(facility.id);
        expect(
          alerts.any(
            (a) =>
                a.inventoryItemId == item.id && a.status == AlertStatus.active,
          ),
          isFalse,
        );
      },
    );
  });
}
