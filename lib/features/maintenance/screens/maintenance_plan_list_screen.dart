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
import '../models/maintenance_plan.dart';
import '../providers/maintenance_providers.dart';

class MaintenancePlanListScreen extends ConsumerStatefulWidget {
  const MaintenancePlanListScreen({super.key});

  @override
  ConsumerState<MaintenancePlanListScreen> createState() => _MaintenancePlanListScreenState();
}

class _MaintenancePlanListScreenState extends ConsumerState<MaintenancePlanListScreen> {
  final _searchController = TextEditingController();
  ScheduleType? _selectedScheduleType;
  SortOrder _sortOrder = SortOrder.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return const Color(0xFFDC2626);
      case Priority.high:
        return const Color(0xFFD97706);
      case Priority.medium:
        return const Color(0xFF2563EB);
      case Priority.low:
        return const Color(0xFF6B7280);
    }
  }

  List<MaintenancePlan> _filterAndSortPlans(List<MaintenancePlan> plans) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = plans.where((p) {
      final matchesQuery = query.isEmpty || p.title.toLowerCase().contains(query);
      final matchesType = _selectedScheduleType == null || p.scheduleType == _selectedScheduleType;
      return matchesQuery && matchesType;
    }).toList();

    switch (_sortOrder) {
      case SortOrder.nameAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOrder.nameDesc:
        filtered.sort((a, b) => b.title.compareTo(a.title));
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
        final plansAsync = ref.watch(allFacilityPlansProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('برنامه‌های نگهداری پیشگیرانه (PM)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              AppSearchFilterBar(
                searchController: _searchController,
                hintText: 'جستجوی برنامه PM با عنوان...',
                onChanged: () => setState(() {}),
                currentSortOrder: _sortOrder,
                onSortOrderChanged: (newSort) => setState(() => _sortOrder = newSort),
                filterChips: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('همه زمان‌بندی‌ها'),
                        selected: _selectedScheduleType == null,
                        onSelected: (_) => setState(() => _selectedScheduleType = null),
                      ),
                      const SizedBox(width: 8),
                      ...ScheduleType.values.map((s) => Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FilterChip(
                              label: Text(s.displayName),
                              selected: _selectedScheduleType == s,
                              onSelected: (selected) => setState(() => _selectedScheduleType = selected ? s : null),
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              // PM Plans List
              Expanded(
                child: plansAsync.when(
                  data: (allPlans) {
                    final filtered = _filterAndSortPlans(allPlans);

                    if (filtered.isEmpty) {
                      return AppEmptyState(
                        title: allPlans.isEmpty ? 'برنامه PM ثبت نشده است' : 'نتیجه‌ای یافت نشد',
                        message: allPlans.isEmpty ? 'می‌توانید برنامه زمان‌بندی جدیدی برای نگهداری تجهیزات تعریف کنید.' : 'فیلترها را تغییر دهید.',
                        actionLabel: allPlans.isEmpty ? 'افزودن برنامه PM' : null,
                        onActionPressed: allPlans.isEmpty ? () => context.push('/maintenance-plans/new') : null,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final plan = filtered[index];
                        final priorityColor = _getPriorityColor(plan.priority);

                        return Card(
                          child: InkWell(
                            onTap: () => context.push('/maintenance-plans/${plan.id}/edit?assetId=${plan.assetId}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFFDBEAFE),
                                    child: const Icon(EneftyIcons.calendar_2_bold, color: Color(0xFF2563EB), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text('فعالیت: ${plan.activityType.displayName}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Chip(
                                              label: Text('زمان‌بندی: ${plan.scheduleType.displayName}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11)),
                                              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                              side: BorderSide.none,
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            Chip(
                                              label: Text('اولویت: ${plan.priority.displayName}', style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                              backgroundColor: priorityColor.withValues(alpha: 0.1),
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
            onPressed: () => context.push('/maintenance-plans/new'),
            child: const Icon(EneftyIcons.add_bold),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
