import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../facilities/providers/facility_providers.dart';
import '../repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final dashboardSummaryProvider =
    FutureProvider.family<Map<String, int>, String>((ref, facilityId) async {
      final repo = ref.watch(dashboardRepositoryProvider);
      return repo.getSummaryCounts(facilityId);
    });

final dashboardTodayTasksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      facilityId,
    ) async {
      final repo = ref.watch(dashboardRepositoryProvider);
      return repo.getTodayTasks(facilityId);
    });

final dashboardWorkOrderStatusProvider =
    FutureProvider.family<Map<String, int>, String>((ref, facilityId) async {
      final repo = ref.watch(dashboardRepositoryProvider);
      return repo.getWorkOrderStatusDistribution(facilityId);
    });

typedef DashboardTrendRequest = ({String facilityId, int days});

final dashboardCompletedTaskTrendProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DashboardTrendRequest>((
      ref,
      request,
    ) async {
      final repo = ref.watch(dashboardRepositoryProvider);
      return repo.getCompletedTaskTrend(request.facilityId, days: request.days);
    });

final dashboardMaterialConsumptionTrendProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DashboardTrendRequest>((
      ref,
      request,
    ) async {
      final repo = ref.watch(dashboardRepositoryProvider);
      return repo.getMaterialConsumptionTrend(
        request.facilityId,
        days: request.days,
      );
    });

final dashboardTopConsumedMaterialsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      facilityId,
    ) async {
      final repo = ref.watch(dashboardRepositoryProvider);
      return repo.getTopConsumedMaterials(facilityId, limit: 5);
    });
