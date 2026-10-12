import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/database/database_helper.dart';
import '../models/facility.dart';
import '../models/location.dart';
import '../repositories/facility_repository.dart';
import '../repositories/location_repository.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final facilityRepositoryProvider = Provider<FacilityRepository>((ref) {
  return FacilityRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final primaryFacilityProvider = FutureProvider<Facility?>((ref) async {
  final repo = ref.watch(facilityRepositoryProvider);
  return repo.getPrimaryFacility();
});

final locationsProvider = FutureProvider.family<List<Location>, String>((ref, facilityId) async {
  final repo = ref.watch(locationRepositoryProvider);
  return repo.getLocations(facilityId);
});
