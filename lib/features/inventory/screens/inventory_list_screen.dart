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
import 'widgets/inventory_filter_chips.dart';
import 'widgets/inventory_item_card.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final _searchController = TextEditingController();
  ItemType? _selectedType;
  bool? _selectedActive;
  SortOrder _sortOrder = SortOrder.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryItem> _filterAndSortItems(List<InventoryItem> items) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = items.where((i) {
      final matchesQuery =
          query.isEmpty ||
          i.name.toLowerCase().contains(query) ||
          i.code.toLowerCase().contains(query);
      final matchesType = _selectedType == null || i.itemType == _selectedType;
      final matchesActive =
          _selectedActive == null || i.isActive == _selectedActive;
      return matchesQuery && matchesType && matchesActive;
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
    final itemsAsync = ref.watch(allInventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'انبار و قطعات یدکی',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
            onSortOrderChanged: (newSort) =>
                setState(() => _sortOrder = newSort),
            filterChips: InventoryFilterChips(
              selectedType: _selectedType,
              selectedActive: _selectedActive,
              onTypeChanged: (type) => setState(() => _selectedType = type),
              onActiveChanged: (active) =>
                  setState(() => _selectedActive = active),
            ),
          ),

          // Inventory List
          Expanded(
            child: itemsAsync.when(
              data: (allItems) {
                final filtered = _filterAndSortItems(allItems);

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    title: allItems.isEmpty
                        ? 'قلمی در انبار ثبت نشده است'
                        : 'نتیجه‌ای یافت نشد',
                    message: allItems.isEmpty
                        ? 'قطعات یدکی یا مواد مصرفی را اضافه کنید.'
                        : 'فیلترها را تغییر دهید.',
                    actionLabel: allItems.isEmpty ? 'افزودن قلم انبار' : null,
                    onActionPressed: allItems.isEmpty
                        ? () => context.push('/inventory/new')
                        : null,
                    icon: EneftyIcons.box_outline,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return InventoryItemCard(
                      item: item,
                      onTap: () => context.push('/inventory/${item.id}'),
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
