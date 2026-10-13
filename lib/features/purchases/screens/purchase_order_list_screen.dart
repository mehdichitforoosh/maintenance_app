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
import '../models/purchase_order.dart';
import '../providers/purchase_providers.dart';

class PurchaseOrderListScreen extends ConsumerStatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  ConsumerState<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends ConsumerState<PurchaseOrderListScreen> {
  final _searchController = TextEditingController();
  PurchaseOrderStatus? _selectedStatus;
  SortOrder _sortOrder = SortOrder.dateNewest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.partiallyReceived:
        return Colors.orange;
      case PurchaseOrderStatus.ordered:
        return const Color(0xFF2563EB);
      case PurchaseOrderStatus.cancelled:
        return Colors.red;
      case PurchaseOrderStatus.draft:
        return Colors.grey;
    }
  }

  List<PurchaseOrder> _filterAndSortOrders(List<PurchaseOrder> orders) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = orders.where((o) {
      final matchesQuery = query.isEmpty ||
          o.purchaseOrderNumber.toLowerCase().contains(query) ||
          (o.supplierName != null && o.supplierName!.toLowerCase().contains(query));
      final matchesStatus = _selectedStatus == null || o.status == _selectedStatus;
      return matchesQuery && matchesStatus;
    }).toList();

    switch (_sortOrder) {
      case SortOrder.nameAsc:
        filtered.sort((a, b) => (a.supplierName ?? '').compareTo(b.supplierName ?? ''));
        break;
      case SortOrder.nameDesc:
        filtered.sort((a, b) => (b.supplierName ?? '').compareTo(a.supplierName ?? ''));
        break;
      case SortOrder.dateNewest:
        filtered.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        break;
      case SortOrder.dateOldest:
        filtered.sort((a, b) => a.orderDate.compareTo(b.orderDate));
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
        final poAsync = ref.watch(purchaseOrdersProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('سفارشات خرید (PO)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              AppSearchFilterBar(
                searchController: _searchController,
                hintText: 'جستجو با شماره PO یا تأمین‌کننده...',
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
                      ...PurchaseOrderStatus.values.map((s) => Padding(
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

              // PO List
              Expanded(
                child: poAsync.when(
                  data: (allOrders) {
                    final filtered = _filterAndSortOrders(allOrders);

                    if (filtered.isEmpty) {
                      return AppEmptyState(
                        title: allOrders.isEmpty ? 'سفارش خریدی ثبت نشده است' : 'نتیجه‌ای یافت نشد',
                        message: allOrders.isEmpty ? 'برای تامین قطعات و اقلام انبار، سفارش خرید جدید ثبت کنید.' : 'فیلترها را تغییر دهید.',
                        actionLabel: allOrders.isEmpty ? 'ثبت سفارش خرید' : null,
                        onActionPressed: allOrders.isEmpty ? () => context.push('/purchases/new') : null,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final po = filtered[index];
                        final statusColor = _getStatusColor(po.status);

                        return Card(
                          child: InkWell(
                            onTap: () => context.push('/purchases/${po.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFFDBEAFE),
                                    child: const Icon(EneftyIcons.shopping_cart_bold, color: Color(0xFF2563EB), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${po.purchaseOrderNumber}${po.supplierName != null ? ' - ${po.supplierName}' : ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text('تاریخ سفارش: ${po.orderDate}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                        const SizedBox(height: 8),
                                        Chip(
                                          label: Text(po.status.displayName, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                          backgroundColor: statusColor.withValues(alpha: 0.1),
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
            onPressed: () => context.push('/purchases/new'),
            child: const Icon(EneftyIcons.add_bold),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
