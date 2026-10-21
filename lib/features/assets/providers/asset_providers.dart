import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/subscription/domain/access_mode.dart';
import '../../../core/subscription/domain/app_feature.dart';
import '../../../core/subscription/providers/subscription_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../facilities/providers/facility_providers.dart';
import '../../work_orders/providers/work_order_providers.dart';
import '../models/asset.dart';
import '../models/asset_reading.dart';
import '../repositories/asset_reading_repository.dart';
import '../repositories/asset_repository.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final assetReadingRepositoryProvider = Provider<AssetReadingRepository>((ref) {
  return AssetReadingRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final assetsProvider = FutureProvider.family<List<Asset>, String>((
  ref,
  facilityId,
) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAssets(facilityId);
});

final assetDetailProvider = FutureProvider.family<Asset?, String>((
  ref,
  assetId,
) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAssetById(assetId);
});

final assetReadingsProvider = FutureProvider.family<List<AssetReading>, String>(
  (ref, assetId) async {
    final repo = ref.watch(assetReadingRepositoryProvider);
    return repo.getReadings(assetId);
  },
);

final assetActionsProvider = Provider<AssetActions>((ref) => AssetActions(ref));

class AssetActions {
  AssetActions(this._ref);
  final Ref _ref;

  Future<Asset> create({
    required String facilityId,
    String? locationId,
    String? parentAssetId,
    required String name,
    required String code,
    AssetType assetType = AssetType.other,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? installationDate,
    String? commissioningDate,
    AssetStatus status = AssetStatus.active,
    String? description,
  }) async {
    await _requireWrite();
    final asset = await _ref
        .read(assetRepositoryProvider)
        .createAsset(
          facilityId: facilityId,
          locationId: locationId,
          parentAssetId: parentAssetId,
          name: name,
          code: code,
          assetType: assetType,
          manufacturer: manufacturer,
          model: model,
          serialNumber: serialNumber,
          installationDate: installationDate,
          commissioningDate: commissioningDate,
          status: status,
          description: description,
        );
    _invalidateAssetReads(facilityId, asset.id);
    return asset;
  }

  Future<Asset> update(Asset asset) async {
    await _requireWrite();
    final updated = await _ref.read(assetRepositoryProvider).updateAsset(asset);
    _invalidateAssetReads(asset.facilityId, asset.id);
    return updated;
  }

  Future<void> deactivate(Asset asset) async {
    await _requireWrite();
    await _ref.read(assetRepositoryProvider).deleteAsset(asset.id);
    _invalidateAssetReads(asset.facilityId, asset.id);
  }

  void _invalidateAssetReads(String facilityId, String assetId) {
    _ref.invalidate(assetsProvider(facilityId));
    _ref.invalidate(assetDetailProvider(assetId));
  }

  Future<void> _requireWrite() => _ref
      .read(featureAccessServiceProvider)
      .requireAccess(
        feature: AppFeature.assets,
        operation: AccessOperation.write,
      );
}

final assetReadingActionsProvider = Provider<AssetReadingActions>(
  (ref) => AssetReadingActions(ref),
);

class AssetReadingActions {
  AssetReadingActions(this._ref);
  final Ref _ref;

  Future<AssetReading> record({
    required String assetId,
    required String metricName,
    required double value,
    required String unit,
    String? recordedAt,
    String? notes,
  }) async {
    await _requireWrite();
    final reading = await _ref
        .read(assetReadingRepositoryProvider)
        .recordReading(
          assetId: assetId,
          metricName: metricName,
          value: value,
          unit: unit,
          recordedAt: recordedAt,
          notes: notes,
        );
    await _invalidateReadingDependents(assetId);
    return reading;
  }

  Future<AssetReadingCorrectionResult> correct({
    required String readingId,
    required String assetId,
    required double value,
    required String unit,
    required String recordedAt,
    required String reason,
    String? notes,
  }) async {
    await _requireWrite();
    final result = await _ref
        .read(assetReadingRepositoryProvider)
        .correctReading(
          readingId: readingId,
          value: value,
          unit: unit,
          recordedAt: recordedAt,
          reason: reason,
          notes: notes,
        );
    await _invalidateReadingDependents(assetId);
    return result;
  }

  Future<void> _invalidateReadingDependents(String assetId) async {
    _ref.invalidate(assetReadingsProvider(assetId));
    final asset = await _ref
        .read(assetRepositoryProvider)
        .getAssetById(assetId);
    if (asset != null) {
      _ref.invalidate(workOrdersProvider(asset.facilityId));
      _ref.invalidate(dashboardSummaryProvider(asset.facilityId));
      _ref.invalidate(dashboardTodayTasksProvider(asset.facilityId));
      _ref.invalidate(assetWorkOrderTasksProvider(assetId));
    }
  }

  Future<void> _requireWrite() => _ref
      .read(featureAccessServiceProvider)
      .requireAccess(
        feature: AppFeature.assets,
        operation: AccessOperation.write,
      );
}
