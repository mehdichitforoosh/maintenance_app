import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_search_filter_bar.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_providers.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final _searchController = TextEditingController();
  ItemType? _selectedType;
  SortOrder _sortOrder = SortOrder.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryItem> _filterAndSortItems(List<InventoryItem> items) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = items.where((i) {
      final matchesQuery = query.isEmpty ||
          i.name.toLowerCase().contains(query) ||
          i.code.toLowerCase().contains(query);
      final matchesType = _selectedType == null || i.itemType == _selectedType;
      return matchesQuery && matchesType;
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
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('انبار و قطعات یدکی', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(EneftyIcons.setting_4_outline),
            tooltip: 'تعدیل موجودی',
            onPressed: () => context.push('/inventory/adjustment'),
          ),
        ],
      ),
      body: Column(
        children: [
          AppSearchFilterBar(
            searchController: _searchController,
            hintText: 'جستجوی قلم انبار با نام یا کد...',
            onChanged: () => setState(() {}),
            currentSortOrder: _sortOrder,
            onSortOrderChanged: (newSort) => setState(() => _sortOrder = newSort),
            filterChips: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('همه انواع'),
                    selected: _selectedType == null,
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                  const SizedBox(width: 8),
                  ...ItemType.values.map((t) => Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: FilterChip(
                          label: Text(t.displayName),
                          selected: _selectedType == t,
                          onSelected: (selected) => setState(() => _selectedType = selected ? t : null),
                        ),
                      )),
                ],
              ),
            ),
          ),

          // Inventory List
          Expanded(
            child: itemsAsync.when(
              data: (allItems) {
                final filtered = _filterAndSortItems(allItems);

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    title: allItems.isEmpty ? 'قلمی در انبار ثبت نشده است' : 'نتیجه‌ای یافت نشد',
                    message: allItems.isEmpty ? 'قطعات یدکی یا مواد مصرفی را اضافه کنید.' : 'فیلترها را تغییر دهید.',
                    actionLabel: allItems.isEmpty ? 'افزودن قلم انبار' : null,
                    onActionPressed: allItems.isEmpty ? () => context.push('/inventory/new') : null,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];

                    return Card(
                      child: InkWell(
                        onTap: () => context.push('/inventory/${item.id}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFDBEAFE),
                                child: const Icon(EneftyIcons.box_bold, color: Color(0xFF2563EB), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text('کد: ${item.code} | واحد: ${item.unit}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Chip(
                                          label: Text(item.itemType.displayName, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11)),
                                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                          side: BorderSide.none,
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Chip(
                                          label: Text('نقطه سفارش: ${item.minimumStock} ${item.unit}', style: const TextStyle(fontSize: 11)),
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
        onPressed: () => context.push('/inventory/new'),
        child: const Icon(EneftyIcons.add_bold),
      ),
    );
  }
}
