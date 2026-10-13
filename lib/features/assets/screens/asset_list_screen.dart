import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_search_filter_bar.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/asset.dart';
import '../providers/asset_providers.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  const AssetListScreen({super.key});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  final _searchController = TextEditingController();
  AssetStatus? _selectedStatus;
  SortOrder _sortOrder = SortOrder.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.active:
        return Colors.green;
      case AssetStatus.underMaintenance:
        return Colors.orange;
      case AssetStatus.inactive:
        return Colors.grey;
      case AssetStatus.retired:
        return Colors.red;
    }
  }

  List<Asset> _filterAndSortAssets(List<Asset> assets) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = assets.where((a) {
      final matchesQuery = query.isEmpty ||
          a.name.toLowerCase().contains(query) ||
          a.code.toLowerCase().contains(query);
      final matchesStatus = _selectedStatus == null || a.status == _selectedStatus;
      return matchesQuery && matchesStatus;
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
          body: Column(
            children: [
              AppSearchFilterBar(
                searchController: _searchController,
                hintText: 'جستجوی تجهیز با نام یا کد...',
                onChanged: () => setState(() {}),
                currentSortOrder: _sortOrder,
                onSortOrderChanged: (newSort) => setState(() => _sortOrder = newSort),
                filterChips: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('همه وضعیت‌ها'),
                        selected: _selectedStatus == null,
                        onSelected: (_) => setState(() => _selectedStatus = null),
                      ),
                      const SizedBox(width: 8),
                      ...AssetStatus.values.map((s) => Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FilterChip(
                              label: Text(s.displayName),
                              selected: _selectedStatus == s,
                              onSelected: (selected) => setState(() => _selectedStatus = selected ? s : null),
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              // Asset List
              Expanded(
                child: assetsAsync.when(
                  data: (allAssets) {
                    final filtered = _filterAndSortAssets(allAssets);

                    if (filtered.isEmpty) {
                      return AppEmptyState(
                        title: allAssets.isEmpty ? 'هیچ تجهیزی ثبت نشده است' : 'نتیجه‌ای یافت نشد',
                        message: allAssets.isEmpty ? 'اولین تجهیز کارگاه را اضافه کنید.' : 'فیلترها را تغییر دهید.',
                        actionLabel: allAssets.isEmpty ? 'افزودن تجهیز' : null,
                        onActionPressed: allAssets.isEmpty ? () => context.push('/assets/new') : null,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final asset = filtered[index];
                        final statusColor = _getStatusColor(asset.status);

                        return Card(
                          child: InkWell(
                            onTap: () => context.push('/assets/${asset.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFFDBEAFE),
                                    child: const Icon(EneftyIcons.cpu_bold, color: Color(0xFF2563EB), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text('کد: ${asset.code}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Chip(
                                              label: Text(asset.status.displayName, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                              backgroundColor: statusColor.withValues(alpha: 0.1),
                                              side: BorderSide.none,
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            Chip(
                                              label: Text(asset.assetType.displayName, style: const TextStyle(fontSize: 11)),
                                              backgroundColor: Colors.grey.shade100,
                                              side: BorderSide.none,
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ],
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
