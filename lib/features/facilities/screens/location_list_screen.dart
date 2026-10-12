import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../providers/facility_providers.dart';

class LocationListScreen extends ConsumerWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        final locationsAsync = ref.watch(locationsProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('موقعیت‌ها و سالن‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: locationsAsync.when(
            data: (locations) {
              if (locations.isEmpty) {
                return AppEmptyState(
                  title: 'موقعیتی ثبت نشده است',
                  message: 'برای دسته‌بندی تجهیزات، موقعیت جدید اضافه کنید.',
                  actionLabel: 'افزودن موقعیت',
                  onActionPressed: () => context.push('/locations/new'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE0F2FE),
                        child: Icon(EneftyIcons.location_bold, color: Color(0xFF0284C7)),
                      ),
                      title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(loc.code != null ? 'کد: ${loc.code}' : 'بدون کد'),
                      trailing: IconButton(
                        icon: const Icon(EneftyIcons.edit_2_outline, color: Color(0xFF2563EB)),
                        tooltip: 'ویرایش موقعیت',
                        onPressed: () => context.push('/locations/${loc.id}/edit'),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoading(),
            error: (e, _) => AppErrorState(message: e.toString()),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/locations/new'),
            child: const Icon(EneftyIcons.add_bold),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
