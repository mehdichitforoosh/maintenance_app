import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../models/location.dart';
import '../providers/facility_providers.dart';

class LocationFormScreen extends ConsumerStatefulWidget {
  final String? locationId;

  const LocationFormScreen({super.key, this.locationId});

  @override
  ConsumerState<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends ConsumerState<LocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedParentLocationId;
  bool _isActive = true;
  bool _isLoading = false;
  Location? _existingLocation;

  @override
  void initState() {
    super.initState();
    if (widget.locationId != null) {
      _loadLocation();
    }
  }

  Future<void> _loadLocation() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(locationRepositoryProvider);
      final loc = await repo.getLocationById(widget.locationId!);
      if (loc != null && mounted) {
        _existingLocation = loc;
        _nameController.text = loc.name;
        _codeController.text = loc.code ?? '';
        _descController.text = loc.description ?? '';
        _selectedParentLocationId = loc.parentLocationId;
        _isActive = loc.isActive;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final facility = await ref.read(primaryFacilityProvider.future);
      if (facility == null) return;
      final repo = ref.read(locationRepositoryProvider);

      if (_existingLocation != null) {
        final updated = _existingLocation!.copyWith(
          parentLocationId: _selectedParentLocationId,
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          isActive: _isActive,
        );
        await repo.updateLocation(updated, parentLocationId: _selectedParentLocationId);
      } else {
        await repo.createLocation(
          facilityId: facility.id,
          parentLocationId: _selectedParentLocationId,
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          isActive: _isActive,
        );
      }

      ref.invalidate(locationsProvider(facility.id));
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
    final isEditing = widget.locationId != null;
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش موقعیت' : 'افزودن موقعیت جدید', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'نام موقعیت / سالن *',
                  prefixIcon: Icon(EneftyIcons.location_bold),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => AppValidators.required(v, fieldName: 'نام موقعیت'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'کد موقعیت',
                  prefixIcon: Icon(EneftyIcons.code_bold),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Parent Location Selector
              facilityAsync.when(
                data: (facility) {
                  if (facility == null) return const SizedBox.shrink();
                  final locationsAsync = ref.watch(locationsProvider(facility.id));
                  return locationsAsync.when(
                    data: (locations) {
                      final candidates = locations.where((loc) => loc.id != widget.locationId).toList();
                      return DropdownButtonFormField<String?>(
                        initialValue: _selectedParentLocationId,
                        decoration: const InputDecoration(
                          labelText: 'موقعیت والد (در صورت وجود)',
                          prefixIcon: Icon(EneftyIcons.hierarchy_bold),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('اصلی (بدون والد)')),
                          ...candidates.map((loc) => DropdownMenuItem<String?>(value: loc.id, child: Text(loc.name))),
                        ],
                        onChanged: (v) => setState(() => _selectedParentLocationId = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Active Switch
              Card(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('وضعیت فعال بودن موقعیت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(_isActive ? 'موقعیت فعال و قابل انتخاب است' : 'موقعیت غیرفعال شده است'),
                  secondary: Icon(
                    _isActive ? EneftyIcons.tick_circle_bold : EneftyIcons.close_circle_bold,
                    color: _isActive ? Colors.green : Colors.grey,
                  ),
                ),
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
                label: Text(isEditing ? 'بروزرسانی موقعیت' : 'ذخیره موقعیت'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
