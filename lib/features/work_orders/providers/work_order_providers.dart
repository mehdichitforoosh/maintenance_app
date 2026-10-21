import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/subscription/domain/access_mode.dart';
import '../../../core/subscription/domain/app_feature.dart';
import '../../../core/subscription/providers/subscription_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../facilities/providers/facility_providers.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../models/work_order.dart';
import '../models/work_order_material.dart';
import '../models/work_order_task.dart';
import '../repositories/work_order_repository.dart';

final workOrderRepositoryProvider = Provider<WorkOrderRepository>((ref) {
  return WorkOrderRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final workOrderActionsProvider = Provider<WorkOrderActions>((ref) {
  return WorkOrderActions(ref);
});

final workOrdersProvider = FutureProvider.family<List<WorkOrder>, String>((
  ref,
  facilityId,
) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getWorkOrders(facilityId);
});

final workOrderDetailProvider = FutureProvider.family<WorkOrder?, String>((
  ref,
  workOrderId,
) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getWorkOrderById(workOrderId);
});

final workOrderTasksProvider =
    FutureProvider.family<List<WorkOrderTask>, String>((
      ref,
      workOrderId,
    ) async {
      final repo = ref.watch(workOrderRepositoryProvider);
      return repo.getTasksForWorkOrder(workOrderId);
    });

final assetWorkOrderTasksProvider =
    FutureProvider.family<List<WorkOrderTask>, String>((ref, assetId) async {
      final repo = ref.watch(workOrderRepositoryProvider);
      return repo.getTasksForAsset(assetId);
    });

final workOrderMaterialsProvider =
    FutureProvider.family<List<WorkOrderMaterial>, String>((ref, taskId) async {
      final repo = ref.watch(workOrderRepositoryProvider);
      return repo.getMaterialsForTask(taskId);
    });

final workOrderTaskEventsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      taskId,
    ) async {
      final repo = ref.watch(workOrderRepositoryProvider);
      return repo.getTaskEvents(taskId);
    });

class WorkOrderActions {
  final Ref _ref;

  WorkOrderActions(this._ref);

  WorkOrderRepository get _repository => _ref.read(workOrderRepositoryProvider);

  Future<void> _requireWriteAccess() {
    return _ref
        .read(featureAccessServiceProvider)
        .requireAccess(
          feature: AppFeature.workOrders,
          operation: AccessOperation.write,
        );
  }

  Future<WorkOrder> createWorkOrder({
    required String facilityId,
    required String title,
    String? description,
    required WorkOrderType workOrderType,
    Priority priority = Priority.medium,
    String? scheduledAt,
    String? notes,
  }) async {
    await _requireWriteAccess();
    final order = await _repository.createWorkOrder(
      facilityId: facilityId,
      title: title,
      description: description,
      workOrderType: workOrderType,
      priority: priority,
      scheduledAt: scheduledAt,
      notes: notes,
    );
    _invalidateDashboard(facilityId);
    _invalidateOrderLists(facilityId);
    return order;
  }

  Future<WorkOrder> updateWorkOrder(WorkOrder order) async {
    await _requireWriteAccess();
    final updated = await _repository.updateWorkOrder(order);
    _invalidateOrder(order.id, order.facilityId);
    _invalidateDashboard(order.facilityId);
    return updated;
  }

  Future<void> updateStatus({
    required String workOrderId,
    required String facilityId,
    required WorkOrderStatus status,
  }) async {
    await _requireWriteAccess();
    if (status == WorkOrderStatus.completed) {
      await _repository.closeWorkOrder(workOrderId);
    } else {
      await _repository.updateWorkOrderStatus(workOrderId, status);
    }
    _invalidateOrder(workOrderId, facilityId);
    _invalidateDashboard(facilityId);
  }

  Future<void> addTask({
    required String workOrderId,
    required String assetId,
    String? maintenancePlanId,
    required String title,
    String? description,
    ActivityType activityType = ActivityType.inspection,
    String? plannedDueAt,
  }) async {
    final order = await _repository.getWorkOrderById(workOrderId);
    await _requireWriteAccess();
    await _repository.addTaskToWorkOrder(
      workOrderId: workOrderId,
      assetId: assetId,
      maintenancePlanId: maintenancePlanId,
      title: title,
      description: description,
      activityType: activityType,
      plannedDueAt: plannedDueAt,
    );
    _invalidateOrder(workOrderId, order?.facilityId);
    if (order != null) _invalidateDashboard(order.facilityId);
  }

  Future<void> addMaterial({
    required String workOrderId,
    required String taskId,
    required String itemId,
    double? plannedQuantity,
    double? actualQuantity,
    double? unitCostAtUse,
    String? notes,
  }) async {
    final order = await _repository.getWorkOrderById(workOrderId);
    await _requireWriteAccess();
    await _repository.addMaterialToTask(
      workOrderTaskId: taskId,
      itemId: itemId,
      plannedQuantity: plannedQuantity,
      actualQuantity: actualQuantity,
      unitCostAtUse: unitCostAtUse,
      notes: notes,
    );
    _invalidateOrder(workOrderId, order?.facilityId, taskId: taskId);
    _invalidateInventory();
    if (order != null) _invalidateDashboard(order.facilityId);
  }

  Future<void> completeTask({
    required String workOrderId,
    required String taskId,
    required String facilityId,
    required TaskResult result,
    required String? findings,
    required int? laborMinutes,
    required int? downtimeMinutes,
    List<Map<String, dynamic>>? consumedMaterials,
  }) async {
    await _requireWriteAccess();
    // The repository owns the transaction that atomically completes the task
    // and records its material stock movements.
    await _repository.completeTask(
      taskId: taskId,
      result: result,
      findings: findings,
      laborMinutes: laborMinutes,
      downtimeMinutes: downtimeMinutes,
      consumedMaterials: consumedMaterials,
    );
    _invalidateOrder(workOrderId, facilityId, taskId: taskId);
    _invalidateInventory();
    _invalidateDashboard(facilityId);
  }

  Future<void> correctCompletedTask({
    required String workOrderId,
    required String taskId,
    required String? facilityId,
    required String reason,
    required TaskResult result,
    required String? findings,
    required int laborMinutes,
    required int downtimeMinutes,
    required List<Map<String, dynamic>> actualMaterials,
  }) async {
    await _requireWriteAccess();
    // Keep stock reconciliation and task correction in the repository's
    // transaction so a failed correction cannot leave partial stock changes.
    await _repository.correctCompletedTask(
      taskId: taskId,
      reason: reason,
      result: result,
      findings: findings,
      laborMinutes: laborMinutes,
      downtimeMinutes: downtimeMinutes,
      actualMaterials: actualMaterials,
    );
    _invalidateOrder(workOrderId, facilityId, taskId: taskId);
    _invalidateInventory();
    if (facilityId != null) _invalidateDashboard(facilityId);
  }

  Future<void> reopenTask({
    required String workOrderId,
    required String taskId,
    required String facilityId,
    required String reason,
  }) async {
    await _requireWriteAccess();
    await _repository.reopenCompletedTask(taskId: taskId, reason: reason);
    _invalidateOrder(workOrderId, facilityId, taskId: taskId);
    _invalidateDashboard(facilityId);
  }

  void _invalidateOrder(
    String workOrderId,
    String? facilityId, {
    String? taskId,
  }) {
    _ref.invalidate(workOrderDetailProvider(workOrderId));
    _ref.invalidate(workOrderTasksProvider(workOrderId));
    _ref.invalidate(assetWorkOrderTasksProvider);
    if (taskId != null) {
      _ref.invalidate(workOrderMaterialsProvider(taskId));
      _ref.invalidate(workOrderTaskEventsProvider(taskId));
    }
    if (facilityId != null) _invalidateOrderLists(facilityId);
  }

  void _invalidateOrderLists(String facilityId) {
    _ref.invalidate(workOrdersProvider(facilityId));
  }

  void _invalidateInventory() {
    _ref.invalidate(inventoryItemsProvider);
    _ref.invalidate(lowStockItemsProvider);
    _ref.invalidate(inventoryCurrentStockProvider);
    _ref.invalidate(stockTransactionsProvider);
  }

  void _invalidateDashboard(String facilityId) {
    _ref.invalidate(dashboardSummaryProvider(facilityId));
    _ref.invalidate(dashboardTodayTasksProvider(facilityId));
    _ref.invalidate(dashboardWorkOrderStatusProvider(facilityId));
    _ref.invalidate(dashboardCompletedTaskTrendProvider(facilityId));
    _ref.invalidate(dashboardMaterialConsumptionTrendProvider(facilityId));
    _ref.invalidate(dashboardTopConsumedMaterialsProvider(facilityId));
  }
}
