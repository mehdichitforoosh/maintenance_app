import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/enums/app_enums.dart';
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
  Asset? _existingAsset;

  @override
  void initState() {
    super.initState();
    if (widget.assetId != null) {
      _loadAsset();
    }
  }

  Future<void> _loadAsset() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(assetRepositoryProvider);
      final asset = await repo.getAssetById(widget.assetId!);
      if (asset != null && mounted) {
        _existingAsset = asset;
        _nameController.text = asset.name;
        _codeController.text = asset.code;
        _mfrController.text = asset.manufacturer ?? '';
        _modelController.text = asset.model ?? '';
        _serialController.text = asset.serialNumber ?? '';
        _descController.text = asset.description ?? '';
        _installDateController.text = asset.installationDate ?? '';
        _commDateController.text = asset.commissioningDate ?? '';
        _selectedLocationId = asset.locationId;
        _selectedParentAssetId = asset.parentAssetId;
        _assetType = asset.assetType;
        _status = asset.status;
      }
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
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.now(),
      firstDate: Jalali(1370, 1),
      lastDate: Jalali(1450, 12),
    );
    if (picked != null) {
      final formatted = '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      setState(() => controller.text = formatted);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final facility = await ref.read(primaryFacilityProvider.future);
      if (facility == null) return;
      final repo = ref.read(assetRepositoryProvider);

      if (_existingAsset != null) {
        final updated = _existingAsset!.copyWith(
          locationId: _selectedLocationId,
          parentAssetId: _selectedParentAssetId,
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          assetType: _assetType,
          status: _status,
          manufacturer: _mfrController.text.trim().isEmpty ? null : _mfrController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
          installationDate: _installDateController.text.trim().isEmpty ? null : _installDateController.text.trim(),
          commissioningDate: _commDateController.text.trim().isEmpty ? null : _commDateController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        );
        await repo.updateAsset(updated);
        ref.invalidate(assetDetailProvider(updated.id));
      } else {
        await repo.createAsset(
          facilityId: facility.id,
          locationId: _selectedLocationId,
          parentAssetId: _selectedParentAssetId,
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          assetType: _assetType,
          status: _status,
          manufacturer: _mfrController.text.trim().isEmpty ? null : _mfrController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
          installationDate: _installDateController.text.trim().isEmpty ? null : _installDateController.text.trim(),
          commissioningDate: _commDateController.text.trim().isEmpty ? null : _commDateController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        );
      }

      ref.invalidate(assetsProvider(facility.id));
      if (mounted) context.pop();
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
    final isEditing = widget.assetId != null;
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش تجهیز' : 'ثبت تجهیز جدید', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading && isEditing && _existingAsset == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'نام تجهیز *',
                        prefixIcon: Icon(EneftyIcons.cpu_bold),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => AppValidators.required(v, fieldName: 'نام تجهیز'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'کد تجهیز (یکتا) *',
                        prefixIcon: Icon(EneftyIcons.code_bold),
                        border: OutlineInputBorder(),
                      ),
                      validator: AppValidators.code,
                    ),
                    const SizedBox(height: 16),

                    // Location Selector
                    facilityAsync.when(
                      data: (facility) {
                        if (facility == null) return const SizedBox.shrink();
                        final locationsAsync = ref.watch(locationsProvider(facility.id));
                        return locationsAsync.when(
                          data: (locations) {
                            return DropdownButtonFormField<String?>(
                              initialValue: _selectedLocationId,
                              decoration: const InputDecoration(
                                labelText: 'موقعیت استقرار در کارگاه',
                                prefixIcon: Icon(EneftyIcons.location_bold),
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('بدون موقعیت مشخص')),
                                ...locations.map((loc) => DropdownMenuItem<String?>(value: loc.id, child: Text(loc.name))),
                              ],
                              onChanged: (v) => setState(() => _selectedLocationId = v),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    // Parent Asset Selector
                    facilityAsync.when(
                      data: (facility) {
                        if (facility == null) return const SizedBox.shrink();
                        final assetsAsync = ref.watch(assetsProvider(facility.id));
                        return assetsAsync.when(
                          data: (assets) {
                            final candidates = assets.where((a) => a.id != widget.assetId).toList();
                            return DropdownButtonFormField<String?>(
                              initialValue: _selectedParentAssetId,
                              decoration: const InputDecoration(
                                labelText: 'تجهیز والد (در صورت وجود)',
                                prefixIcon: Icon(EneftyIcons.chart_2_bold),
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('اصلی (بدون والد)')),
                                ...candidates.map((a) => DropdownMenuItem<String?>(value: a.id, child: Text('${a.name} (${a.code})'))),
                              ],
                              onChanged: (v) => setState(() => _selectedParentAssetId = v),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<AssetType>(
                      initialValue: _assetType,
                      decoration: const InputDecoration(
                        labelText: 'نوع تجهیز',
                        prefixIcon: Icon(EneftyIcons.setting_bold),
                        border: OutlineInputBorder(),
                      ),
                      items: AssetType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                      onChanged: (v) => setState(() => _assetType = v ?? AssetType.machine),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AssetStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'وضعیت',
                        prefixIcon: Icon(EneftyIcons.info_circle_bold),
                        border: OutlineInputBorder(),
                      ),
                      items: AssetStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                      onChanged: (v) => setState(() => _status = v ?? AssetStatus.active),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mfrController,
                      decoration: const InputDecoration(
                        labelText: 'سازنده / برند',
                        prefixIcon: Icon(EneftyIcons.building_bold),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'مدل',
                        prefixIcon: Icon(EneftyIcons.box_bold),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serialController,
                      decoration: const InputDecoration(
                        labelText: 'شماره سریال',
                        prefixIcon: Icon(EneftyIcons.document_text_bold),
                        border: OutlineInputBorder(),
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
                              prefixIcon: Icon(EneftyIcons.calendar_2_bold),
                              border: OutlineInputBorder(),
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
                              labelText: 'تاریخ راه اندازی (شمسی)',
                              prefixIcon: Icon(EneftyIcons.calendar_bold),
                              border: OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: Icon(isEditing ? EneftyIcons.edit_2_bold : EneftyIcons.add_bold),
                      onPressed: _isLoading ? null : _save,
                      label: Text(isEditing ? 'بروزرسانی تجهیز' : 'ذخیره تجهیز'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
