import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/alert_event.dart';
import '../repositories/alert_repository.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final alertsProvider = FutureProvider.family<List<AlertEvent>, String>((ref, facilityId) async {
  final repo = ref.watch(alertRepositoryProvider);
  return repo.getAlerts(facilityId);
});
