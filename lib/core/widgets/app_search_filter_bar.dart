import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';

enum SortOrder {
  nameAsc,
  nameDesc,
  dateNewest,
  dateOldest,
}

extension SortOrderExtension on SortOrder {
  String get displayName {
    switch (this) {
      case SortOrder.nameAsc:
        return 'الفبا (الف تا ی)';
      case SortOrder.nameDesc:
        return 'الفبا (ی تا الف)';
      case SortOrder.dateNewest:
        return 'جدیدترین';
      case SortOrder.dateOldest:
        return 'قدیمی‌ترین';
    }
  }
}

class AppSearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String hintText;
  final VoidCallback onChanged;
  final SortOrder currentSortOrder;
  final ValueChanged<SortOrder> onSortOrderChanged;
  final Widget? filterChips;

  const AppSearchFilterBar({
    super.key,
    required this.searchController,
    required this.hintText,
    required this.onChanged,
    required this.currentSortOrder,
    required this.onSortOrderChanged,
    this.filterChips,
  });

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مرتب‌سازی و فیلترها',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              ...SortOrder.values.map((sort) => ListTile(
                    title: Text(sort.displayName),
                    leading: Radio<SortOrder>(
                      value: sort,
                      groupValue: currentSortOrder,
                      onChanged: (selected) {
                        if (selected != null) {
                          onSortOrderChanged(selected);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    onTap: () {
                      onSortOrderChanged(sort);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Filter / Sort Button on Left (as in attached image)
              IconButton.filledTonal(
                icon: const Icon(EneftyIcons.setting_4_outline, size: 20),
                tooltip: 'مرتب‌سازی و فیلتر',
                onPressed: () => _showSortBottomSheet(context),
              ),
              const SizedBox(width: 8),
              // Search Input Field
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    suffixIcon: const Icon(EneftyIcons.search_normal_outline, size: 20),
                    prefixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              searchController.clear();
                              onChanged();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (filterChips != null) ...[
            const SizedBox(height: 8),
            filterChips!,
          ],
        ],
      ),
    );
  }
}
