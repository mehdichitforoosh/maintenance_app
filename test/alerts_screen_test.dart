import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/enums/app_enums.dart';
import 'package:maintenance_app/features/alerts/models/alert_event.dart';
import 'package:maintenance_app/features/alerts/providers/alert_providers.dart';
import 'package:maintenance_app/features/alerts/screens/alerts_screen.dart';
import 'package:maintenance_app/features/facilities/models/facility.dart';
import 'package:maintenance_app/features/facilities/providers/facility_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows every alert type by default', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final now = DateTime.now().toUtc().toIso8601String();
    const facility = Facility(
      id: 'facility-1',
      name: 'کارگاه تست',
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: '2026-01-01T00:00:00.000Z',
    );
    final alerts = AlertType.values
        .map(
          (type) => AlertEvent(
            id: type.name,
            facilityId: facility.id,
            alertType: type,
            title: 'عنوان ${type.displayName}',
            message: 'توضیحات ${type.displayName}',
            deduplicationKey: 'alert:${type.name}',
            triggeredAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryFacilityProvider.overrideWith((ref) async => facility),
          alertsProvider(facility.id).overrideWith((ref) async => alerts),
        ],
        child: const MaterialApp(home: AlertsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (final alert in alerts) {
      expect(find.text(alert.title), findsOneWidget);
      expect(
        find.textContaining(alert.alertType.displayName),
        findsAtLeastNWidgets(1),
      );
    }
  });
}
