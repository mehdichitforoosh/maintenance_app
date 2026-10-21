import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/subscription/domain/access_mode.dart';
import '../../../core/subscription/domain/app_feature.dart';
import '../../../core/subscription/providers/subscription_providers.dart';
import '../../facilities/providers/facility_providers.dart';
import '../../assets/providers/asset_providers.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_plan_material.dart';
import '../repositories/maintenance_plan_repository.dart';

final maintenancePlanRepositoryProvider = Provider<MaintenancePlanRepository>((
  ref,
) {
  return MaintenancePlanRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final maintenancePlansProvider =
    FutureProvider.family<List<MaintenancePlan>, String>((ref, assetId) async {
      final repo = ref.watch(maintenancePlanRepositoryProvider);
      return repo.getPlans(assetId);
    });

final allFacilityPlansProvider =
    FutureProvider.family<List<MaintenancePlan>, String>((
      ref,
      facilityId,
    ) async {
      final repo = ref.watch(maintenancePlanRepositoryProvider);
      return repo.getAllActivePlans(facilityId);
    });

final planMaterialsProvider =
    FutureProvider.family<List<MaintenancePlanMaterial>, String>((
      ref,
      planId,
    ) async {
      final repo = ref.watch(maintenancePlanRepositoryProvider);
      return repo.getPlanMaterials(planId);
    });

final maintenancePlanActionsProvider = Provider<MaintenancePlanActions>(
  (ref) => MaintenancePlanActions(ref),
);

class MaintenancePlanActions {
  MaintenancePlanActions(this._ref);
  final Ref _ref;

  Future<MaintenancePlan> create({
    required String assetId,
    required String title,
    String? description,
    ActivityType activityType = ActivityType.inspection,
    Priority priority = Priority.medium,
    required ScheduleType scheduleType,
    int? calendarIntervalValue,
    CalendarUnit? calendarIntervalUnit,
    String? meterName,
    double? meterInterval,
    String? meterUnit,
    String? conditionConfigJson,
    String? oneTimeDueAt,
    String? startDate,
    String? nextDueAt,
    ScheduleAnchor scheduleAnchor = ScheduleAnchor.completionDate,
  }) async {
    await _requireWrite();
    final plan = await _ref
        .read(maintenancePlanRepositoryProvider)
        .createPlan(
          assetId: assetId,
          title: title,
          description: description,
          activityType: activityType,
          priority: priority,
          scheduleType: scheduleType,
          calendarIntervalValue: calendarIntervalValue,
          calendarIntervalUnit: calendarIntervalUnit,
          meterName: meterName,
          meterInterval: meterInterval,
          meterUnit: meterUnit,
          conditionConfigJson: conditionConfigJson,
          oneTimeDueAt: oneTimeDueAt,
          startDate: startDate,
          nextDueAt: nextDueAt,
          scheduleAnchor: scheduleAnchor,
        );
    _invalidatePlans(assetId);
    return plan;
  }

  Future<MaintenancePlan> update(
    MaintenancePlan plan, {
    String? previousAssetId,
  }) async {
    await _requireWrite();
    final updated = await _ref
        .read(maintenancePlanRepositoryProvider)
        .updatePlan(plan);
    _invalidatePlans(previousAssetId ?? plan.assetId);
    _invalidatePlans(updated.assetId);
    return updated;
  }

  Future<void> delete(MaintenancePlan plan) async {
    await _requireWrite();
    await _ref.read(maintenancePlanRepositoryProvider).deletePlan(plan.id);
    _ref.invalidate(planMaterialsProvider(plan.id));
    _invalidatePlans(plan.assetId);
  }

  Future<void> addMaterial({
    required String planId,
    required String assetId,
    required String itemId,
    required double plannedQuantity,
    String? notes,
  }) async {
    await _requireWrite();
    await _ref
        .read(maintenancePlanRepositoryProvider)
        .addPlanMaterial(
          planId: planId,
          itemId: itemId,
          plannedQuantity: plannedQuantity,
          notes: notes,
        );
    _ref.invalidate(planMaterialsProvider(planId));
    _invalidatePlans(assetId);
  }

  void _invalidatePlans(String assetId) {
    _ref.invalidate(maintenancePlansProvider(assetId));
    _ref.invalidate(assetDetailProvider(assetId));
    final facility = _ref.read(primaryFacilityProvider).asData?.value;
    if (facility != null) {
      _ref.invalidate(allFacilityPlansProvider(facility.id));
    }
  }

  Future<void> _requireWrite() => _ref
      .read(featureAccessServiceProvider)
      .requireAccess(
        feature: AppFeature.maintenancePlans,
        operation: AccessOperation.write,
      );
}
