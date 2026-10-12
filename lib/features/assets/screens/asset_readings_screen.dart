import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../providers/asset_providers.dart';

class AssetReadingsScreen extends ConsumerStatefulWidget {
  final String assetId;

  const AssetReadingsScreen({super.key, required this.assetId});

  @override
  ConsumerState<AssetReadingsScreen> createState() => _AssetReadingsScreenState();
}

class _AssetReadingsScreenState extends ConsumerState<AssetReadingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _metricController = TextEditingController(text: 'operating_hours');
  final _valueController = TextEditingController();
  final _unitController = TextEditingController(text: 'hours');
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _metricController.dispose();
    _valueController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _record() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(assetReadingRepositoryProvider);
      await repo.recordReading(
        assetId: widget.assetId,
        metricName: _metricController.text.trim(),
        value: double.parse(_valueController.text.trim()),
        unit: _unitController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      ref.invalidate(assetReadingsProvider(widget.assetId));
      _valueController.clear();
      _notesController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خوانش با موفقیت ثبت شد.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(assetReadingsProvider(widget.assetId));

    return Scaffold(
      appBar: AppBar(title: const Text('ثبت و تاریخچه خوانش‌های تجهیز')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('ثبت خوانش جدید', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _metricController,
                        decoration: const InputDecoration(labelText: 'نام متریک (مثل operating_hours, temperature)', border: OutlineInputBorder()),
                        validator: (v) => AppValidators.required(v, fieldName: 'متریک'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _valueController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'مقدار *', border: OutlineInputBorder()),
                              validator: (v) => AppValidators.positiveNumber(v, fieldName: 'مقدار'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _unitController,
                              decoration: const InputDecoration(labelText: 'واحد *', border: OutlineInputBorder()),
                              validator: (v) => AppValidators.required(v, fieldName: 'واحد'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'یادداشت', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isLoading ? null : _record,
                        child: const Text('ثبت خوانش'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('تاریخچه خوانش‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: readingsAsync.when(
                data: (readings) {
                  if (readings.isEmpty) return const Center(child: Text('هیچ خوانشی ثبت نشده است.'));
                  return ListView.builder(
                    itemCount: readings.length,
                    itemBuilder: (context, index) {
                      final r = readings[index];
                      return Card(
                        child: ListTile(
                          title: Text('${r.metricName}: ${r.value} ${r.unit}'),
                          subtitle: Text('زمان: ${r.recordedAt}${r.notes != null ? ' | یادداشت: ${r.notes}' : ''}'),
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
      ),
    );
  }
}
