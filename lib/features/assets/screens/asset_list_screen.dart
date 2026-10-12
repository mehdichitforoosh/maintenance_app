import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../facilities/providers/facility_providers.dart';
import '../providers/asset_providers.dart';

class AssetListScreen extends ConsumerWidget {
  const AssetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        final assetsAsync = ref.watch(assetsProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('تجهیزات و ماشین‌آلات', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(EneftyIcons.chart_2_outline),
                tooltip: 'نمایش درختی',
                onPressed: () => context.push('/assets/tree'),
              ),
            ],
          ),
          body: assetsAsync.when(
            data: (assets) {
              if (assets.isEmpty) {
                return AppEmptyState(
                  title: 'هیچ تجهیزی ثبت نشده است',
                  message: 'اولین تجهیز کارگاه را اضافه کنید.',
                  actionLabel: 'افزودن تجهیز',
                  onActionPressed: () => context.push('/assets/new'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFDBEAFE),
                        child: Icon(EneftyIcons.cpu_bold, color: Color(0xFF2563EB)),
                      ),
                      title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('کد: ${asset.code} | نوع: ${asset.assetType.displayName} | وضعیت: ${asset.status.displayName}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(EneftyIcons.edit_2_outline, color: Color(0xFF2563EB)),
                            tooltip: 'ویرایش تجهیز',
                            onPressed: () => context.push('/assets/${asset.id}/edit'),
                          ),
                          const Icon(EneftyIcons.arrow_left_3_outline, size: 18),
                        ],
                      ),
                      onTap: () => context.push('/assets/${asset.id}'),
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoading(),
            error: (e, _) => AppErrorState(message: e.toString()),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/assets/new'),
            child: const Icon(EneftyIcons.add_bold),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
