import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../facilities/providers/facility_providers.dart';
import '../providers/asset_providers.dart';
import 'widgets/asset_tree_node.dart';

class AssetTreeScreen extends ConsumerWidget {
  const AssetTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) {
          return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        }
        final assetsAsync = ref.watch(assetsProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'درخت سلسله‌مراتبی تجهیزات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: assetsAsync.when(
            data: (allAssets) {
              if (allAssets.isEmpty) {
                return const Center(child: Text('تجهیزی ثبت نشده است.'));
              }
              final rootAssets = allAssets
                  .where((a) => a.parentAssetId == null)
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                itemCount: rootAssets.length,
                itemBuilder: (context, index) {
                  final rootAsset = rootAssets[index];
                  return AssetTreeNode(
                    asset: rootAsset,
                    allAssets: allAssets,
                    depth: 0,
                  );
                },
              );
            },
            loading: () => const AppLoading(),
            error: (e, _) => AppErrorState(message: e.toString()),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
