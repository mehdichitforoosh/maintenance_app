import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/subscription/domain/access_mode.dart';
import '../../../core/subscription/domain/app_feature.dart';
import '../../../core/subscription/providers/subscription_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/alert_event.dart';
import '../repositories/alert_repository.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final alertsProvider = FutureProvider.family<List<AlertEvent>, String>((
  ref,
  facilityId,
) async {
  final repo = ref.watch(alertRepositoryProvider);
  return repo.getAlerts(facilityId);
});

final alertActionsProvider = Provider<AlertActions>((ref) {
  return AlertActions(ref);
});

class AlertActions {
  final Ref _ref;

  AlertActions(this._ref);

  Future<void> updateStatus({
    required String alertId,
    required String facilityId,
    required AlertStatus status,
  }) async {
    await _ref
        .read(featureAccessServiceProvider)
        .requireAccess(
          feature: AppFeature.alerts,
          operation: AccessOperation.write,
        );
    await _ref.read(alertRepositoryProvider).updateAlertStatus(alertId, status);

    _ref.invalidate(alertsProvider(facilityId));
    _ref.invalidate(dashboardSummaryProvider(facilityId));
    _ref.invalidate(dashboardTodayTasksProvider(facilityId));
    _ref.invalidate(dashboardWorkOrderStatusProvider(facilityId));
    _ref.invalidate(dashboardCompletedTaskTrendProvider(facilityId));
    _ref.invalidate(dashboardMaterialConsumptionTrendProvider(facilityId));
    _ref.invalidate(dashboardTopConsumedMaterialsProvider(facilityId));
  }
}
