import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/enums/app_enums.dart';
import 'package:maintenance_app/features/assets/models/asset.dart';
import 'package:maintenance_app/features/assets/models/asset_reading.dart';
import 'package:maintenance_app/features/assets/providers/asset_providers.dart';
import 'package:maintenance_app/features/facilities/models/facility.dart';
import 'package:maintenance_app/features/facilities/providers/facility_providers.dart';
import 'package:maintenance_app/features/inventory/providers/inventory_providers.dart';
import 'package:maintenance_app/features/maintenance/screens/maintenance_plan_form_screen.dart';

void main() {
  testWidgets('meter and condition plan selectors use the asset reading unit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const facility = Facility(
      id: 'facility-1',
      name: 'کارگاه',
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    );
    const asset = Asset(
      id: 'asset-1',
      facilityId: 'facility-1',
      name: 'پمپ',
      code: 'PUMP-01',
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    );
    final readings = [
      AssetReading(
        id: 'hours-1',
        assetId: asset.id,
        metricName: 'operating_hours',
        value: 120,
        unit: 'h',
        recordedAt: '2026-10-26T10:00:00Z',
        createdAt: '2026-10-26T10:00:00Z',
        updatedAt: '2026-10-26T10:00:00Z',
      ),
      AssetReading(
        id: 'temperature-1',
        assetId: asset.id,
        metricName: 'temperature',
        value: 75,
        unit: '°C',
        recordedAt: '2026-10-26T11:00:00Z',
        createdAt: '2026-10-26T11:00:00Z',
        updatedAt: '2026-10-26T11:00:00Z',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryFacilityProvider.overrideWith((ref) async => facility),
          assetsProvider(facility.id).overrideWith((ref) async => [asset]),
          assetReadingsProvider(asset.id).overrideWith((ref) async => readings),
          allInventoryItemsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(home: MaintenancePlanFormScreen(assetId: asset.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('نوع زمان‌بندی'));
    await tester.tap(find.byType(DropdownButtonFormField<ScheduleType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('کارکرد (متری) (بر اساس ثبت خوانش)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('شاخص جدید / ورود دستی'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('operating_hours · h'));
    await tester.pumpAndSettle();
    expect(find.text('واحد متصل به شاخص: h'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<ScheduleType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('شرطی (سنسور/وضعیت)'));
    await tester.pumpAndSettle();
    expect(find.text('واحد متصل به شاخص: °C'), findsOneWidget);
  });
}
