import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_plan_material.dart';
import '../repositories/maintenance_plan_repository.dart';

final maintenancePlanRepositoryProvider = Provider<MaintenancePlanRepository>((ref) {
  return MaintenancePlanRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final maintenancePlansProvider = FutureProvider.family<List<MaintenancePlan>, String>((ref, assetId) async {
  final repo = ref.watch(maintenancePlanRepositoryProvider);
  return repo.getPlans(assetId);
});

final allFacilityPlansProvider = FutureProvider.family<List<MaintenancePlan>, String>((ref, facilityId) async {
  final repo = ref.watch(maintenancePlanRepositoryProvider);
  return repo.getAllActivePlans(facilityId);
});

final planMaterialsProvider = FutureProvider.family<List<MaintenancePlanMaterial>, String>((ref, planId) async {
  final repo = ref.watch(maintenancePlanRepositoryProvider);
  return repo.getPlanMaterials(planId);
});
