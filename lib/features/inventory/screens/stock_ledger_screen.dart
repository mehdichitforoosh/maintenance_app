import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_responsive_container.dart';
import '../models/inventory_item.dart';
import '../models/inventory_ledger_entry.dart';
import '../providers/inventory_providers.dart';

class StockLedgerScreen extends ConsumerStatefulWidget {
  const StockLedgerScreen({super.key});

  @override
  ConsumerState<StockLedgerScreen> createState() => _StockLedgerScreenState();
}

class _StockLedgerScreenState extends ConsumerState<StockLedgerScreen> {
  final _searchController = TextEditingController();
  TransactionType? _selectedType;
  String? _selectedItemId;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final current = isStartDate ? _fromDate : _toDate;
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: current == null
          ? Jalali.now()
          : Jalali.fromDateTime(current),
      firstDate: Jalali(1370, 1),
      lastDate: Jalali(1450, 12),
    );
    if (picked == null || !mounted) return;
    final date = picked.toDateTime();
    setState(() {
      if (isStartDate) {
        _fromDate = date;
        if (_toDate != null && date.isAfter(_toDate!)) _toDate = date;
      } else {
        _toDate = date;
        if (_fromDate != null && date.isBefore(_fromDate!)) _fromDate = date;
      }
    });
  }

  List<InventoryLedgerEntry> _filterEntries(
    List<InventoryLedgerEntry> entries,
    Map<String, InventoryItem> itemsById,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    return entries.where((entry) {
      if (_selectedType != null && entry.transactionType != _selectedType) {
        return false;
      }
      if (_selectedItemId != null && entry.itemId != _selectedItemId) {
        return false;
      }
      if (query.isNotEmpty &&
          !entry.itemName.toLowerCase().contains(query) &&
          !entry.itemCode.toLowerCase().contains(query) &&
          !(entry.notes?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
      final date = AppDateUtils.parseIso(entry.transactionDate)?.toLocal();
      if (date == null) return false;
      if (_fromDate != null &&
          date.isBefore(
            DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day),
          )) {
        return false;
      }
      if (_toDate != null &&
          !date.isBefore(
            DateTime(
              _toDate!.year,
              _toDate!.month,
              _toDate!.day,
            ).add(const Duration(days: 1)),
          )) {
        return false;
      }
      return itemsById.containsKey(entry.itemId);
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedItemId = null;
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(inventoryLedgerProvider);
    final itemsAsync = ref.watch(allInventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('گردش انبار'),
        actions: [
          IconButton(
            tooltip: 'تعدیل موجودی',
            onPressed: () => context.push('/inventory/adjustment'),
            icon: const Icon(EneftyIcons.setting_4_outline),
          ),
          IconButton(
            tooltip: 'تازه‌سازی',
            onPressed: () => ref.invalidate(inventoryLedgerProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AppResponsiveContainer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'جستجوی کالا، کد یا یادداشت',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TransactionType?>(
                          key: ValueKey(_selectedType),
                          initialValue: _selectedType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'نوع گردش',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<TransactionType?>(
                              value: null,
                              child: Text('همه انواع'),
                            ),
                            ...TransactionType.values.map(
                              (type) => DropdownMenuItem<TransactionType?>(
                                value: type,
                                child: Text(type.displayName),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedType = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: itemsAsync.when(
                          data: (items) => DropdownButtonFormField<String?>(
                            key: ValueKey(_selectedItemId),
                            initialValue: _selectedItemId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'کالا',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('همه کالاها'),
                              ),
                              ...items.map(
                                (item) => DropdownMenuItem<String?>(
                                  value: item.id,
                                  child: Text(
                                    item.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedItemId = value),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (error, _) =>
                              Text('خطا در دریافت کالاها: $error'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(isStartDate: true),
                          icon: const Icon(EneftyIcons.calendar_2_outline, size: 18),
                          label: Text(
                            _fromDate == null
                                ? 'از تاریخ'
                                : AppDateUtils.formatDateOnlyAsJalali(
                                    AppDateUtils.formatDateOnly(_fromDate!),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(isStartDate: false),
                          icon: const Icon(EneftyIcons.calendar_2_outline, size: 18),
                          label: Text(
                            _toDate == null
                                ? 'تا تاریخ'
                                : AppDateUtils.formatDateOnlyAsJalali(
                                    AppDateUtils.formatDateOnly(_toDate!),
                                  ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'پاک‌کردن فیلترها',
                        onPressed: _clearFilters,
                        icon: const Icon(EneftyIcons.setting_4_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ledgerAsync.when(
                data: (entries) => itemsAsync.when(
                  data: (items) {
                    final itemsById = {for (final item in items) item.id: item};
                    final filtered = _filterEntries(entries, itemsById);
                    if (filtered.isEmpty) {
                      return AppEmptyState(
                        title: entries.isEmpty
                            ? 'گردشی ثبت نشده است'
                            : 'گردشی با این فیلترها پیدا نشد',
                        message: entries.isEmpty
                            ? 'رسیدها، مصرف‌ها و تعدیلات موجودی اینجا نمایش داده می‌شوند.'
                            : 'فیلترها را تغییر دهید یا پاک کنید.',
                        icon: EneftyIcons.document_text_outline,
                        actionLabel: entries.isEmpty
                            ? null
                            : 'پاک‌کردن فیلترها',
                        onActionPressed: entries.isEmpty ? null : _clearFilters,
                      );
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            0,
                            16,
                            8,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              '${AppNumberFormat.decimal(filtered.length)} گردش',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final entry = filtered[index];
                              return Card(
                                child: ListTile(
                                  onTap: () {
                                    if (entry.transactionType ==
                                        TransactionType.purchaseReceipt) {
                                      context.push(
                                        '/inventory/receipts/${entry.id}',
                                      );
                                    } else {
                                      context.push(
                                        '/inventory/${entry.itemId}',
                                      );
                                    }
                                  },
                                  leading: CircleAvatar(
                                    child: Icon(
                                      entry.transactionType ==
                                                  TransactionType
                                                      .adjustmentIn ||
                                              entry.transactionType ==
                                                  TransactionType
                                                      .purchaseReceipt ||
                                              entry.transactionType ==
                                                  TransactionType.returnItem
                                          ? Icons.south_west
                                          : Icons.north_east,
                                    ),
                                  ),
                                  title: Text(
                                    entry.itemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${entry.transactionType.displayName} · ${entry.itemCode}\n${AppDateUtils.formatDisplay(entry.transactionDate)}${entry.notes?.trim().isNotEmpty == true ? '\n${entry.notes}' : ''}',
                                  ),
                                  isThreeLine:
                                      entry.notes?.trim().isNotEmpty == true,
                                  trailing: Text(
                                    '${entry.transactionType == TransactionType.adjustmentOut || entry.transactionType == TransactionType.maintenanceConsumption ? '−' : '+'}${AppNumberFormat.decimal(entry.quantity)}\n${entry.unit}',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          entry.transactionType ==
                                                  TransactionType
                                                      .adjustmentOut ||
                                              entry.transactionType ==
                                                  TransactionType
                                                      .maintenanceConsumption
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const AppLoading(),
                  error: (error, _) => AppErrorState(
                    message: 'بارگذاری کالاها ناموفق بود: $error',
                  ),
                ),
                loading: () => const AppLoading(),
                error: (error, _) => AppErrorState(message: error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
