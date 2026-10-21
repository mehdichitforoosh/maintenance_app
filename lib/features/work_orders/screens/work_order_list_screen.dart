import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_search_filter_bar.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/work_order.dart';
import '../providers/work_order_providers.dart';

class WorkOrderListScreen extends ConsumerStatefulWidget {
  const WorkOrderListScreen({super.key});

  @override
  ConsumerState<WorkOrderListScreen> createState() =>
      _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends ConsumerState<WorkOrderListScreen> {
  final _searchController = TextEditingController();
  WorkOrderStatus? _selectedStatus;
  SortOrder _sortOrder = SortOrder.dateNewest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.completed:
        return Colors.green;
      case WorkOrderStatus.inProgress:
        return Colors.orange;
      case WorkOrderStatus.open:
        return const Color(0xFF2563EB);
      case WorkOrderStatus.onHold:
        return Colors.purple;
      case WorkOrderStatus.cancelled:
        return Colors.red;
      case WorkOrderStatus.draft:
        return Colors.grey;
    }
  }

  List<WorkOrder> _filterAndSortWorkOrders(List<WorkOrder> orders) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = orders.where((o) {
      final matchesQuery =
          query.isEmpty ||
          o.title.toLowerCase().contains(query) ||
          o.workOrderNumber.toLowerCase().contains(query);
      final matchesStatus =
          _selectedStatus == null || o.status == _selectedStatus;
      return matchesQuery && matchesStatus;
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
        if (facility == null) {
          return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        }
        final woAsync = ref.watch(workOrdersProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'دستورکارهای تعمیراتی',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: Column(
            children: [
              AppSearchFilterBar(
                searchController: _searchController,
                hintText: 'جستجوی دستورکار با عنوان یا شماره...',
                onChanged: () => setState(() {}),
                currentSortOrder: _sortOrder,
                onSortOrderChanged: (newSort) =>
                    setState(() => _sortOrder = newSort),
                filterChips: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('همه وضعیت‌ها'),
                        selected: _selectedStatus == null,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = null),
                      ),
                      const SizedBox(width: 8),
                      ...WorkOrderStatus.values.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: FilterChip(
                            label: Text(s.displayName),
                            selected: _selectedStatus == s,
                            onSelected: (selected) => setState(
                              () => _selectedStatus = selected ? s : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Work Order List
              Expanded(
                child: woAsync.when(
                  data: (allOrders) {
                    final filtered = _filterAndSortWorkOrders(allOrders);

                    if (filtered.isEmpty) {
                      return AppEmptyState(
                        title: allOrders.isEmpty
                            ? 'دستورکاری ثبت نشده است'
                            : 'نتیجه‌ای یافت نشد',
                        message: allOrders.isEmpty
                            ? 'برای شروع، دستورکار جدیدی ایجاد کنید.'
                            : 'فیلترها را تغییر دهید.',
                        actionLabel: allOrders.isEmpty
                            ? 'ایجاد دستورکار'
                            : null,
                        onActionPressed: allOrders.isEmpty
                            ? () => context.push('/work-orders/new')
                            : null,
                        icon: EneftyIcons.document_text_outline,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final wo = filtered[index];
                        final statusColor = _getStatusColor(wo.status);
                        final priorityColor = AppColors.priorityColor(
                          wo.priority,
                        );

                        return Card(
                          child: InkWell(
                            onTap: () => context.push('/work-orders/${wo.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    child: const Icon(
                                      EneftyIcons.document_text_bold,
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
                                          '${wo.workOrderNumber}: ${wo.title}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'نوع: ${wo.workOrderType.displayName}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Chip(
                                              label: Text(
                                                wo.status.displayName,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              backgroundColor: statusColor
                                                  .withValues(alpha: 0.1),
                                              side: BorderSide.none,
                                              padding: EdgeInsets.zero,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            Chip(
                                              label: Text(
                                                'اولویت: ${wo.priority.displayName}',
                                                style: TextStyle(
                                                  color: priorityColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              backgroundColor: priorityColor
                                                  .withValues(alpha: 0.1),
                                              side: BorderSide.none,
                                              padding: EdgeInsets.zero,
                                              visualDensity:
                                                  VisualDensity.compact,
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
            onPressed: () => context.push('/work-orders/new'),
            child: const Icon(EneftyIcons.add_bold),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
