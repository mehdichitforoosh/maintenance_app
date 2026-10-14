// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maintenance_app/main.dart';
import 'package:maintenance_app/core/routes/app_router.dart';

void main() {
  testWidgets('CMMS App smoke test', (WidgetTester tester) async {
    final appRouter = createAppRouter(initialLocation: '/onboarding');
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(ProviderScope(child: MyApp(router: appRouter)));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('مدیریت تجهیزات و ماشین‌آلات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
