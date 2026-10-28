import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_form_submit_button.dart';

class AssetReadingForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController metricController;
  final TextEditingController valueController;
  final TextEditingController unitController;
  final TextEditingController notesController;
  final TextEditingController correctionReasonController;
  final FocusNode metricFocusNode;
  final List<String> metricSuggestions;
  final Map<String, String> metricUnits;
  final DateTime recordedAt;
  final bool isEditing;
  final bool isSubmitting;
  final ValueChanged<String> onUnitChanged;
  final VoidCallback onSelectDate;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const AssetReadingForm({
    super.key,
    required this.formKey,
    required this.metricController,
    required this.valueController,
    required this.unitController,
    required this.notesController,
    required this.correctionReasonController,
    required this.metricFocusNode,
    required this.metricSuggestions,
    required this.metricUnits,
    required this.recordedAt,
    required this.isEditing,
    required this.isSubmitting,
    required this.onUnitChanged,
    required this.onSelectDate,
    required this.onSubmit,
    required this.onCancel,
  });

  static const _presetUnits = [
    'ساعت',
    '°C',
    '°F',
    'bar',
    'psi',
    'mm/s',
    'rpm',
    'kW',
    '%',
    'سایر...',
  ];

  static const _commonMetrics = [
    'operating_hours',
    'temperature',
    'pressure',
    'vibration',
  ];

  static const _defaultUnits = {
    'operating_hours': 'ساعت',
    'temperature': '°C',
    'pressure': 'bar',
    'vibration': 'mm/s',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final suggestions = {..._commonMetrics, ...metricSuggestions}.toList()
      ..sort();

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isEditing) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'اصلاح خوانش: نسخه قبلی در تاریخچه باقی می‌ماند.',
                style: TextStyle(color: colorScheme.onTertiaryContainer),
              ),
            ),
            const SizedBox(height: 12),
          ],
          RawAutocomplete<String>(
            textEditingController: metricController,
            focusNode: metricFocusNode,
            displayStringForOption: (option) => option,
            optionsBuilder: (textEditingValue) {
              if (isEditing) return const Iterable<String>.empty();
              final query = textEditingValue.text.trim().toLowerCase();
              return suggestions.where(
                (metric) =>
                    query.isEmpty || metric.toLowerCase().contains(query),
              );
            },
            onSelected: (metric) {
              final unit = metricUnits[metric] ?? _defaultUnits[metric];
              if (unit != null) onUnitChanged(unit);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    readOnly: isEditing,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'نوع شاخص',
                      hintText: 'مثلاً operating_hours یا temperature',
                      prefixIcon: Icon(EneftyIcons.category_2_outline),
                    ),
                    validator: (value) =>
                        AppValidators.required(value, fieldName: 'شاخص'),
                    onFieldSubmitted: (_) => onFieldSubmitted(),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 220,
                      maxWidth: 400,
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: options
                          .take(8)
                          .map(
                            (option) => ListTile(
                              dense: true,
                              title: Text(option),
                              onTap: () => onSelected(option),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'مقدار',
                    prefixIcon: Icon(EneftyIcons.speedometer_outline),
                  ),
                  validator: (value) =>
                      AppValidators.positiveNumber(value, fieldName: 'مقدار'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: unitController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'واحد',
                    prefixIcon: Icon(EneftyIcons.ruler_outline),
                  ),
                  validator: (value) =>
                      AppValidators.required(value, fieldName: 'واحد'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetUnits.map((unit) {
              final isCustom = unit == 'سایر...';
              final selected = !isCustom && unitController.text == unit;
              return ChoiceChip(
                label: Text(unit),
                selected: selected,
                onSelected: (_) {
                  onUnitChanged(isCustom ? '' : unit);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onSelectDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'تاریخ و ساعت ثبت',
                prefixIcon: Icon(EneftyIcons.calendar_2_outline),
              ),
              child: Text(
                AppDateUtils.formatDisplay(recordedAt.toIso8601String()),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'یادداشت (اختیاری)',
              alignLabelWithHint: true,
            ),
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: correctionReasonController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'دلیل اصلاح *',
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  AppValidators.required(value, fieldName: 'دلیل اصلاح'),
            ),
          ],
          const SizedBox(height: 16),
          AppFormSubmitButton(
            isSubmitting: isSubmitting,
            onPressed: onSubmit,
            label: isEditing ? 'ذخیره اصلاح' : 'ثبت خوانش',
          ),
          if (isEditing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: isSubmitting ? null : onCancel,
              child: const Text('انصراف از اصلاح'),
            ),
          ],
        ],
      ),
    );
  }
}
