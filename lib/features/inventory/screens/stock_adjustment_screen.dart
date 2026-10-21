import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_loading.dart';
import '../providers/inventory_providers.dart';

class StockAdjustmentScreen extends ConsumerStatefulWidget {
  const StockAdjustmentScreen({super.key});

  @override
  ConsumerState<StockAdjustmentScreen> createState() =>
      _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedItemId;
  TransactionType _type = TransactionType.adjustmentIn;
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _adjust() async {
    if (!_formKey.currentState!.validate() || _selectedItemId == null) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(inventoryActionsProvider)
          .adjustStock(
            itemId: _selectedItemId!,
            type: _type,
            quantity: double.parse(_qtyController.text.trim()),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تعدیل موجودی انبار (Adjustment)')),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('ابتدا باید کالایی در انبار تعریف کنید.'),
            );
          }
          _selectedItemId ??= items.first.id;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedItemId,
                    decoration: const InputDecoration(
                      labelText: 'انتخاب کالا *',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map(
                          (i) => DropdownMenuItem(
                            value: i.id,
                            child: Text('${i.name} (${i.code})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedItemId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TransactionType>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'نوع تعدیل *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TransactionType.adjustmentIn,
                        child: Text('تعدیل افزایش (ورود به انبار)'),
                      ),
                      DropdownMenuItem(
                        value: TransactionType.adjustmentOut,
                        child: Text('تعدیل کاهش (خروج از انبار)'),
                      ),
                    ],
                    onChanged: (v) => setState(
                      () => _type = v ?? TransactionType.adjustmentIn,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'مقدار *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        AppValidators.positiveNumber(v, fieldName: 'مقدار'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'دلیل تعدیل / یادداشت',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _adjust,
                    child: const Text('ثبت تعدیل موجودی'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('خطا: $e')),
      ),
    );
  }
}
