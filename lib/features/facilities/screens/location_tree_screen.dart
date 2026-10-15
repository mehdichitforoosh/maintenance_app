import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../providers/facility_providers.dart';
import 'widgets/location_tree_node.dart';

class LocationTreeScreen extends ConsumerWidget {
  const LocationTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) {
          return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        }
        final locationsAsync = ref.watch(locationsProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'درخت سلسله‌مراتبی موقعیت‌ها',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: locationsAsync.when(
            data: (allLocations) {
              if (allLocations.isEmpty) {
                return const Center(child: Text('موقعیتی ثبت نشده است.'));
              }
              final rootLocations = allLocations
                  .where((loc) => loc.parentLocationId == null)
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                itemCount: rootLocations.length,
                itemBuilder: (context, index) {
                  final rootLoc = rootLocations[index];
                  return LocationTreeNode(
                    location: rootLoc,
                    allLocations: allLocations,
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
