import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../facilities/providers/facility_providers.dart';
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

final assetsProvider = FutureProvider.family<List<Asset>, String>((ref, facilityId) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAssets(facilityId);
});

final assetDetailProvider = FutureProvider.family<Asset?, String>((ref, assetId) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAssetById(assetId);
});

final assetReadingsProvider = FutureProvider.family<List<AssetReading>, String>((ref, assetId) async {
  final repo = ref.watch(assetReadingRepositoryProvider);
  return repo.getReadings(assetId);
});
