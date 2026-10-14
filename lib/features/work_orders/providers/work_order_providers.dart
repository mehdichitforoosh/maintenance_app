import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/work_order.dart';
import '../models/work_order_material.dart';
import '../models/work_order_task.dart';
import '../repositories/work_order_repository.dart';

final workOrderRepositoryProvider = Provider<WorkOrderRepository>((ref) {
  return WorkOrderRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final workOrdersProvider = FutureProvider.family<List<WorkOrder>, String>((ref, facilityId) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getWorkOrders(facilityId);
});

final workOrderDetailProvider = FutureProvider.family<WorkOrder?, String>((ref, workOrderId) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getWorkOrderById(workOrderId);
});

final workOrderTasksProvider = FutureProvider.family<List<WorkOrderTask>, String>((ref, workOrderId) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getTasksForWorkOrder(workOrderId);
});

final workOrderMaterialsProvider = FutureProvider.family<List<WorkOrderMaterial>, String>((ref, taskId) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getMaterialsForTask(taskId);
});
