import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_form_body.dart';
import '../../../core/widgets/app_form_submit_button.dart';
import '../../../core/utils/validators.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/asset.dart';
import '../providers/asset_providers.dart';

class AssetFormScreen extends ConsumerStatefulWidget {
  final String? assetId;

  const AssetFormScreen({super.key, this.assetId});

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _mfrController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _descController = TextEditingController();
  final _installDateController = TextEditingController();
  final _commDateController = TextEditingController();

  String? _selectedLocationId;
  String? _selectedParentAssetId;
  AssetType _assetType = AssetType.machine;
  AssetStatus _status = AssetStatus.active;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;
  Asset? _existingAsset;

  @override
  void initState() {
    super.initState();
    if (widget.assetId != null) {
      _loadAsset();
    }
  }

  Future<void> _loadAsset() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final repo = ref.read(assetRepositoryProvider);
      final asset = await repo.getAssetById(widget.assetId!);
      if (asset == null) {
        _loadError = 'تجهیز موردنظر پیدا نشد.';
      } else if (mounted) {
        _existingAsset = asset;
        _nameController.text = asset.name;
        _codeController.text = asset.code;
        _mfrController.text = asset.manufacturer ?? '';
        _modelController.text = asset.model ?? '';
        _serialController.text = asset.serialNumber ?? '';
        _descController.text = asset.description ?? '';
        _installDateController.text = _dateInputValue(asset.installationDate);
        _commDateController.text = _dateInputValue(asset.commissioningDate);
        _selectedLocationId = asset.locationId;
        _selectedParentAssetId = asset.parentAssetId;
        _assetType = asset.assetType;
        _status = asset.status;
      }
    } catch (error) {
      if (mounted) _loadError = 'بارگذاری تجهیز ناموفق بود: $error';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _mfrController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _descController.dispose();
    _installDateController.dispose();
    _commDateController.dispose();
    super.dispose();
  }

  Future<void> _selectPersianDate(TextEditingController controller) async {
    final selectedDate = AppDateUtils.parseDateOnlyAsJalali(controller.text);
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: selectedDate ?? Jalali.now(),
      firstDate: Jalali(1370, 1),
      lastDate: Jalali(1450, 12),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        controller.text = AppDateUtils.formatDateOnlyAsJalali(formatted);
      });
    }
  }

  String _dateInputValue(String? value) {
    return AppDateUtils.parseDateOnlyAsJalali(value) == null
        ? ''
        : AppDateUtils.formatDateOnlyAsJalali(value);
  }

  Future<void> _save() async {
    if (_isSubmitting || _loadError != null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final facility = await ref.read(primaryFacilityProvider.future);
      if (facility == null) {
        throw StateError('ابتدا اطلاعات کارگاه را ثبت کنید.');
      }
      if (_existingAsset != null) {
        final updated = _existingAsset!.copyWith(
          locationId: _selectedLocationId,
          parentAssetId: _selectedParentAssetId,
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          assetType: _assetType,
          status: _status,
          manufacturer: _mfrController.text.trim().isEmpty
              ? null
              : _mfrController.text.trim(),
          model: _modelController.text.trim().isEmpty
              ? null
              : _modelController.text.trim(),
          serialNumber: _serialController.text.trim().isEmpty
              ? null
              : _serialController.text.trim(),
          installationDate: AppDateUtils.jalaliDateToIsoDate(
            _installDateController.text,
          ),
          commissioningDate: AppDateUtils.jalaliDateToIsoDate(
            _commDateController.text,
          ),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
        );
        await ref.read(assetActionsProvider).update(updated);
      } else {
        await ref
            .read(assetActionsProvider)
            .create(
              facilityId: facility.id,
              locationId: _selectedLocationId,
              parentAssetId: _selectedParentAssetId,
              name: _nameController.text.trim(),
              code: _codeController.text.trim(),
              assetType: _assetType,
              status: _status,
              manufacturer: _mfrController.text.trim().isEmpty
                  ? null
                  : _mfrController.text.trim(),
              model: _modelController.text.trim().isEmpty
                  ? null
                  : _modelController.text.trim(),
              serialNumber: _serialController.text.trim().isEmpty
                  ? null
                  : _serialController.text.trim(),
              installationDate: AppDateUtils.jalaliDateToIsoDate(
                _installDateController.text,
              ),
              commissioningDate: AppDateUtils.jalaliDateToIsoDate(
                _commDateController.text,
              ),
              description: _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
            );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.assetId != null;
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'ویرایش تجهیز' : 'ثبت تجهیز جدید',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: AppFormBody(
        formKey: _formKey,
        isLoading: _isLoading && isEditing && _existingAsset == null,
        loadError: _loadError,
        onRetry: _loadAsset,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'نام تجهیز *',
              hintText: 'مثلاً کمپرسور اصلی یا دستگاه برش',
              prefixIcon: Icon(EneftyIcons.cpu_outline),
            ),
            validator: (v) => AppValidators.required(v, fieldName: 'نام تجهیز'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'کد تجهیز (یکتا) *',
              hintText: 'مثلاً EQ-001 یا CMP-07',
              prefixIcon: Icon(EneftyIcons.code_outline),
            ),
            validator: AppValidators.code,
          ),
          const SizedBox(height: 16),

          // Location Selector
          facilityAsync.when(
            data: (facility) {
              if (facility == null) {
                return const Text('ابتدا اطلاعات کارگاه را ثبت کنید.');
              }
              final locationsAsync = ref.watch(locationsProvider(facility.id));
              return locationsAsync.when(
                data: (locations) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedLocationId,
                    decoration: const InputDecoration(
                      labelText: 'موقعیت استقرار در کارگاه',
                      hintText: 'محل نصب تجهیز را انتخاب کنید',
                      prefixIcon: Icon(EneftyIcons.location_outline),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('بدون موقعیت مشخص'),
                      ),
                      ...locations.map(
                        (loc) => DropdownMenuItem<String?>(
                          value: loc.id,
                          child: Text(loc.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedLocationId = v),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(
                  'خطا در دریافت موقعیت‌ها: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(
              'خطا در دریافت اطلاعات کارگاه: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          const SizedBox(height: 16),

          // Parent Asset Selector
          facilityAsync.when(
            data: (facility) {
              if (facility == null) {
                return const SizedBox.shrink();
              }
              final assetsAsync = ref.watch(assetsProvider(facility.id));
              return assetsAsync.when(
                data: (assets) {
                  final candidates = assets
                      .where((a) => a.id != widget.assetId)
                      .toList();
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedParentAssetId,
                    decoration: const InputDecoration(
                      labelText: 'تجهیز والد (در صورت وجود)',
                      prefixIcon: Icon(EneftyIcons.hierarchy_outline),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('اصلی (بدون والد)'),
                      ),
                      ...candidates.map(
                        (a) => DropdownMenuItem<String?>(
                          value: a.id,
                          child: Text('${a.name} (${a.code})'),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedParentAssetId = v),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(
                  'خطا در دریافت تجهیزات: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(
              'خطا در دریافت اطلاعات کارگاه: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<AssetType>(
            initialValue: _assetType,
            decoration: const InputDecoration(
              labelText: 'نوع تجهیز',
              hintText: 'نوع تجهیز را تعیین کنید',
              prefixIcon: Icon(EneftyIcons.setting_outline),
            ),
            items: AssetType.values
                .map(
                  (t) => DropdownMenuItem(value: t, child: Text(t.displayName)),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _assetType = v ?? AssetType.machine),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AssetStatus>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'وضعیت',
              hintText: 'وضعیت فعلی تجهیز را انتخاب کنید',
              prefixIcon: Icon(EneftyIcons.info_circle_outline),
            ),
            items: AssetStatus.values
                .map(
                  (s) => DropdownMenuItem(value: s, child: Text(s.displayName)),
                )
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? AssetStatus.active),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _mfrController,
            decoration: const InputDecoration(
              labelText: 'سازنده / برند',
              hintText: 'مثلاً ایران‌موتور یا کاترپیلار',
              prefixIcon: Icon(EneftyIcons.building_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'مدل',
              hintText: 'مثلاً ۳۰۰۰- M یا X12',
              prefixIcon: Icon(EneftyIcons.box_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _serialController,
            decoration: const InputDecoration(
              labelText: 'شماره سریال',
              hintText: 'شماره سریال یا شناسه کارخانه',
              prefixIcon: Icon(EneftyIcons.document_text_outline),
            ),
          ),
          const SizedBox(height: 16),

          // Persian Date Pickers
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _installDateController,
                  readOnly: true,
                  onTap: () => _selectPersianDate(_installDateController),
                  decoration: const InputDecoration(
                    labelText: 'تاریخ نصب (شمسی)',
                    hintText: 'انتخاب تاریخ نصب',
                    prefixIcon: Icon(EneftyIcons.calendar_2_outline),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _commDateController,
                  readOnly: true,
                  onTap: () => _selectPersianDate(_commDateController),
                  decoration: const InputDecoration(
                    labelText: 'تاریخ راه‌اندازی (شمسی)',
                    hintText: 'انتخاب تاریخ راه‌اندازی',
                    prefixIcon: Icon(EneftyIcons.calendar_outline),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'توضیحات',
              hintText: 'توضیح کوتاه درباره تجهیز، مشکل یا ویژگی خاص',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          AppFormSubmitButton(
            label: isEditing ? 'بروزرسانی تجهیز' : 'ذخیره تجهیز',
            icon: Icon(
              isEditing ? EneftyIcons.edit_2_bold : EneftyIcons.add_bold,
            ),
            isSubmitting: _isSubmitting,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
