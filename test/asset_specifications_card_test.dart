import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/enums/app_enums.dart';
import 'package:maintenance_app/features/assets/models/asset.dart';
import 'package:maintenance_app/features/assets/screens/widgets/asset_detail_sections.dart';

void main() {
  testWidgets('shows Jalali installation and commissioning dates', (
    tester,
  ) async {
    const asset = Asset(
      id: 'asset-1',
      facilityId: 'facility-1',
      name: 'پمپ اصلی',
      code: 'PUMP-01',
      assetType: AssetType.pump,
      installationDate: '2023-05-28',
      commissioningDate: '2023-07-03',
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: '2026-01-01T00:00:00.000Z',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AssetSpecificationsCard(asset: asset)),
      ),
    );

    expect(find.text('تاریخ نصب'), findsOneWidget);
    expect(find.text('۱۴۰۲/۰۳/۰۷'), findsOneWidget);
    expect(find.text('تاریخ بهره‌برداری'), findsOneWidget);
    expect(find.text('۱۴۰۲/۰۴/۱۲'), findsOneWidget);
  });
}
