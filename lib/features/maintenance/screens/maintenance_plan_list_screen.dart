import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
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

  List<MaintenancePlan> _filterPlans(List<MaintenancePlan> plans) {
    final query = _searchController.text.trim().toLowerCase();
    return plans.where((p) {
      final matchesQuery = query.isEmpty || p.title.toLowerCase().contains(query);
      final matchesType = _selectedScheduleType == null || p.scheduleType == _selectedScheduleType;
      return matchesQuery && matchesType;
    }).toList();
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
              // Search & Filter Header
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'جستجوی برنامه PM با عنوان...',
                        prefixIcon: const Icon(EneftyIcons.search_normal_outline),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
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
                  ],
                ),
              ),

              // PM Plans List
              Expanded(
                child: plansAsync.when(
                  data: (allPlans) {
                    final filtered = _filterPlans(allPlans);

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
                                    radius: 24,
                                    backgroundColor: const Color(0xFFDBEAFE),
                                    child: const Icon(EneftyIcons.calendar_2_bold, color: Color(0xFF2563EB)),
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
                                  IconButton(
                                    icon: const Icon(EneftyIcons.edit_2_outline, color: Color(0xFF2563EB)),
                                    tooltip: 'ویرایش برنامه PM',
                                    onPressed: () => context.push('/maintenance-plans/${plan.id}/edit?assetId=${plan.assetId}'),
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
