import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/theme/app_theme.dart';
import 'package:maintenance_app/features/onboarding/screens/onboarding_screen.dart';

void main() {
  testWidgets('onboarding content and illustration fit on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: OnboardingScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مدیریت تجهیزات و ماشین‌آلات'), findsOneWidget);
    expect(
      find.textContaining('ثبت دقیق شناسنامه فنی تجهیزات'),
      findsOneWidget,
    );
    expect(find.byIcon(EneftyIcons.cpu_bold), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNWidgets(4));

    final pageViewBottom = tester.getBottomRight(find.byType(PageView)).dy;
    final indicatorTop = tester
        .getTopLeft(find.byType(AnimatedContainer).first)
        .dy;
    expect(indicatorTop, greaterThanOrEqualTo(pageViewBottom));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('قبلی'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    expect(find.text('شروع راه‌اندازی کارگاه'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
