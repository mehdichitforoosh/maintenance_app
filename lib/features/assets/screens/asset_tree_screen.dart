import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../facilities/providers/facility_providers.dart';
import '../providers/asset_providers.dart';

class AssetTreeScreen extends ConsumerWidget {
  const AssetTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        final assetsAsync = ref.watch(assetsProvider(facility.id));

        return Scaffold(
          appBar: AppBar(title: const Text('ساختار درختی تجهیزات')),
          body: assetsAsync.when(
            data: (assets) {
              if (assets.isEmpty) return const Center(child: Text('تجهیزی ثبت نشده است.'));
              final rootAssets = assets.where((a) => a.parentAssetId == null).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rootAssets.length,
                itemBuilder: (context, index) {
                  final asset = rootAssets[index];
                  return ExpansionTile(
                    leading: const Icon(Icons.settings, color: Colors.blue),
                    title: Text(asset.name),
                    subtitle: Text('کد: ${asset.code}'),
                    children: assets
                        .where((child) => child.parentAssetId == asset.id)
                        .map((child) => ListTile(
                              leading: const Icon(Icons.subdirectory_arrow_left, size: 20),
                              title: Text(child.name),
                              subtitle: Text('کد: ${child.code}'),
                            ))
                        .toList(),
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
