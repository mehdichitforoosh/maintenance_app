import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/subscription/domain/access_mode.dart';
import '../../../core/subscription/domain/app_feature.dart';
import '../../../core/subscription/providers/subscription_providers.dart';
import '../../../core/storage/database/database_helper.dart';
import '../models/facility.dart';
import '../models/location.dart';
import '../repositories/facility_repository.dart';
import '../repositories/location_repository.dart';

final databaseHelperProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

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

final locationsProvider = FutureProvider.family<List<Location>, String>((
  ref,
  facilityId,
) async {
  final repo = ref.watch(locationRepositoryProvider);
  return repo.getLocations(facilityId);
});

final facilityActionsProvider = Provider<FacilityActions>(
  (ref) => FacilityActions(ref),
);

class FacilityActions {
  FacilityActions(this._ref);
  final Ref _ref;

  Future<Facility> create({
    required String name,
    String? description,
    String? address,
  }) async {
    await _requireWrite(AppFeature.facility);
    final facility = await _ref
        .read(facilityRepositoryProvider)
        .createFacility(name: name, description: description, address: address);
    _ref.invalidate(primaryFacilityProvider);
    return facility;
  }

  Future<Facility> update(Facility facility) async {
    await _requireWrite(AppFeature.facility);
    final updated = await _ref
        .read(facilityRepositoryProvider)
        .updateFacility(facility);
    _ref.invalidate(primaryFacilityProvider);
    return updated;
  }

  Future<void> _requireWrite(AppFeature feature) => _ref
      .read(featureAccessServiceProvider)
      .requireAccess(feature: feature, operation: AccessOperation.write);
}

final locationActionsProvider = Provider<LocationActions>(
  (ref) => LocationActions(ref),
);

class LocationActions {
  LocationActions(this._ref);
  final Ref _ref;

  Future<Location> create({
    required String facilityId,
    String? parentLocationId,
    required String name,
    String? code,
    String? description,
    bool isActive = true,
  }) async {
    await _requireWrite();
    final location = await _ref
        .read(locationRepositoryProvider)
        .createLocation(
          facilityId: facilityId,
          parentLocationId: parentLocationId,
          name: name,
          code: code,
          description: description,
          isActive: isActive,
        );
    _ref.invalidate(locationsProvider(facilityId));
    return location;
  }

  Future<Location> update(Location location, {String? parentLocationId}) async {
    await _requireWrite();
    final updated = await _ref
        .read(locationRepositoryProvider)
        .updateLocation(location, parentLocationId: parentLocationId);
    _ref.invalidate(locationsProvider(location.facilityId));
    return updated;
  }

  Future<void> deactivate(Location location) async {
    await _requireWrite();
    await _ref.read(locationRepositoryProvider).deleteLocation(location.id);
    _ref.invalidate(locationsProvider(location.facilityId));
  }

  Future<void> _requireWrite() => _ref
      .read(featureAccessServiceProvider)
      .requireAccess(
        feature: AppFeature.locations,
        operation: AccessOperation.write,
      );
}
