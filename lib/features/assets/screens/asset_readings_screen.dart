import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../models/asset_reading.dart';
import '../providers/asset_providers.dart';
import '../repositories/asset_reading_repository.dart';
import 'widgets/asset_reading_form.dart';
import 'widgets/asset_reading_tile.dart';
import 'widgets/asset_reading_trend_chart.dart';

class AssetReadingsScreen extends ConsumerStatefulWidget {
  final String assetId;

  const AssetReadingsScreen({super.key, required this.assetId});

  @override
  ConsumerState<AssetReadingsScreen> createState() =>
      _AssetReadingsScreenState();
}

class _AssetReadingsScreenState extends ConsumerState<AssetReadingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _metricController = TextEditingController(text: 'operating_hours');
  final _metricFocusNode = FocusNode();
  final _valueController = TextEditingController();
  final _unitController = TextEditingController(text: 'ساعت');
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime _recordedAt = DateTime.now();
  String? _editingReadingId;
  bool _isSaving = false;

  @override
  void dispose() {
    _metricController.dispose();
    _metricFocusNode.dispose();
    _valueController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectRecordedAt() async {
    final selectedDate = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromDateTime(_recordedAt),
      firstDate: Jalali(1370, 1),
      lastDate: Jalali(1450, 12),
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (selectedTime == null || !mounted) return;

    final date = selectedDate.toDateTime();
    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repository = ref.read(assetReadingRepositoryProvider);
      final readingId = _editingReadingId;
      final message = readingId == null
          ? await _createReading(repository)
          : await _correctReading(repository, readingId);

      ref.invalidate(assetReadingsProvider(widget.assetId));
      if (mounted) {
        _resetForm();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String> _createReading(AssetReadingRepository repository) async {
    await repository.recordReading(
      assetId: widget.assetId,
      metricName: _metricController.text.trim(),
      value: double.parse(_valueController.text.trim()),
      unit: _unitController.text.trim(),
      recordedAt: _recordedAt.toUtc().toIso8601String(),
      notes: _optionalNotes,
    );
    return 'خوانش با موفقیت ثبت شد.';
  }

  Future<String> _correctReading(
    AssetReadingRepository repository,
    String readingId,
  ) async {
    final result = await repository.correctReading(
      readingId: readingId,
      value: double.parse(_valueController.text.trim()),
      unit: _unitController.text.trim(),
      recordedAt: _recordedAt.toUtc().toIso8601String(),
      reason: _reasonController.text.trim(),
      notes: _optionalNotes,
    );
    if (result.generatedConditionTaskCount > 0) {
      return 'خوانش اصلاح شد و وظیفه نگهداری شرطی ایجاد شد.';
    }
    if (result.openConditionTaskCount > 0) {
      return 'خوانش اصلاح شد؛ وظیفه شرطی باز حفظ شد و وظیفه تکراری ساخته نشد.';
    }
    if (result.previouslyTriggeredTaskCount > 0) {
      return 'خوانش اصلاح شد؛ وظیفه‌ای که براساس خوانش قبلی ایجاد شده بود بدون تغییر باقی ماند.';
    }
    return 'خوانش اصلاح شد.';
  }

  String? get _optionalNotes {
    final notes = _notesController.text.trim();
    return notes.isEmpty ? null : notes;
  }

  void _startCorrection(AssetReading reading) {
    setState(() {
      _editingReadingId = reading.id;
      _metricController.text = reading.metricName;
      _valueController.text = _formatValue(reading.value);
      _unitController.text = reading.unit;
      _notesController.text = reading.notes ?? '';
      _reasonController.clear();
      _recordedAt =
          DateTime.tryParse(reading.recordedAt)?.toLocal() ?? DateTime.now();
    });
  }

  void _resetForm() {
    setState(() {
      _editingReadingId = null;
      _metricController.text = 'operating_hours';
      _valueController.clear();
      _unitController.text = 'ساعت';
      _notesController.clear();
      _reasonController.clear();
      _recordedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(assetReadingsProvider(widget.assetId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'خوانش‌های تجهیز',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AssetReadingForm(
              formKey: _formKey,
              metricController: _metricController,
              metricFocusNode: _metricFocusNode,
              metricSuggestions:
                  readingsAsync.asData?.value
                      .map((reading) => reading.metricName)
                      .toSet()
                      .toList() ??
                  const [],
              valueController: _valueController,
              unitController: _unitController,
              notesController: _notesController,
              correctionReasonController: _reasonController,
              recordedAt: _recordedAt,
              isEditing: _editingReadingId != null,
              isSaving: _isSaving,
              onUnitChanged: (unit) =>
                  setState(() => _unitController.text = unit),
              onSelectDate: _selectRecordedAt,
              onSubmit: _submit,
              onCancel: _resetForm,
            ),
            const SizedBox(height: 28),
            Text(
              'تاریخچه خوانش‌ها',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            readingsAsync.when(
              data: (readings) {
                if (readings.isEmpty) {
                  return const AppEmptyState(
                    title: 'خوانشی ثبت نشده است',
                    message:
                        'پس از ثبت اولین خوانش، تاریخچه آن در این بخش نمایش داده می‌شود.',
                    icon: Icons.speed_outlined,
                  );
                }
                return Column(
                  children: [
                    AssetReadingTrendChart(readings: readings),
                    ...readings.map(
                      (reading) => AssetReadingTile(
                        reading: reading,
                        onEdit: _isSaving
                            ? null
                            : () => _startCorrection(reading),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(message: error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
