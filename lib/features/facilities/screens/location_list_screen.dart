import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_search_filter_bar.dart';
import '../models/location.dart';
import '../providers/facility_providers.dart';

class LocationListScreen extends ConsumerStatefulWidget {
  const LocationListScreen({super.key});

  @override
  ConsumerState<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends ConsumerState<LocationListScreen> {
  final _searchController = TextEditingController();
  SortOrder _sortOrder = SortOrder.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Location> _filterAndSortLocations(List<Location> locations) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = locations.where((loc) {
      return query.isEmpty ||
          loc.name.toLowerCase().contains(query) ||
          (loc.code != null && loc.code!.toLowerCase().contains(query));
    }).toList();

    switch (_sortOrder) {
      case SortOrder.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOrder.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOrder.dateNewest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOrder.dateOldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
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
              'موقعیت‌ها و سالن‌ها',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(EneftyIcons.hierarchy_outline),
                tooltip: 'نمایش درختی موقعیت‌ها',
                onPressed: () => context.push('/locations/tree'),
              ),
            ],
          ),
          body: Column(
            children: [
              AppSearchFilterBar(
                searchController: _searchController,
                hintText: 'جستجوی موقعیت با نام یا کد...',
                onChanged: () => setState(() {}),
                currentSortOrder: _sortOrder,
                onSortOrderChanged: (newSort) =>
                    setState(() => _sortOrder = newSort),
              ),

              // Location List
              Expanded(
                child: locationsAsync.when(
                  data: (allLocations) {
                    final filtered = _filterAndSortLocations(allLocations);

                    if (filtered.isEmpty) {
                      return AppEmptyState(
                        title: allLocations.isEmpty
                            ? 'موقعیتی ثبت نشده است'
                            : 'نتیجه‌ای یافت نشد',
                        message: allLocations.isEmpty
                            ? 'برای دسته‌بندی تجهیزات، موقعیت جدید اضافه کنید.'
                            : 'عبارت دیگری را جستجو کنید.',
                        actionLabel: allLocations.isEmpty
                            ? 'افزودن موقعیت'
                            : null,
                        onActionPressed: allLocations.isEmpty
                            ? () => context.push('/locations/new')
                            : null,
                        icon: EneftyIcons.location_outline,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final loc = filtered[index];
                        final isActive = loc.isActive;
                        final colorScheme = Theme.of(context).colorScheme;

                        return Card(
                          child: InkWell(
                            onTap: () =>
                                context.push('/locations/${loc.id}/edit'),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        colorScheme.secondaryContainer,
                                    foregroundColor:
                                        colorScheme.onSecondaryContainer,
                                    child: const Icon(
                                      EneftyIcons.location_bold,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          loc.code != null
                                              ? 'کد موقعیت: ${loc.code}'
                                              : 'بدون کد',
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Chip(
                                          label: Text(
                                            isActive ? 'فعال' : 'غیرفعال',
                                            style: TextStyle(
                                              color: isActive
                                                  ? Colors.green
                                                  : colorScheme
                                                        .onSurfaceVariant,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          backgroundColor: isActive
                                              ? Colors.green.withValues(
                                                  alpha:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? 0.22
                                                      : 0.1,
                                                )
                                              : colorScheme
                                                    .surfaceContainerHighest,
                                          side: BorderSide.none,
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const AppLoading(),
                  error: (e, _) => AppErrorState(message: e.toString()),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/locations/new'),
            child: const Icon(EneftyIcons.add_outline),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
