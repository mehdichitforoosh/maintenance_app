import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/widgets/app_form_body.dart';

void main() {
  testWidgets('shows loading and error states before the form', (tester) async {
    final formKey = GlobalKey<FormState>();
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormBody(
            formKey: formKey,
            isLoading: true,
            children: const [Text('Form field')],
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Form field'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormBody(
            formKey: formKey,
            loadError: 'Could not load',
            onRetry: () => retryCount++,
            children: const [Text('Form field')],
          ),
        ),
      ),
    );

    expect(find.text('Could not load'), findsOneWidget);
    await tester.tap(find.text('تلاش مجدد'));
    expect(retryCount, 1);
    expect(find.text('Form field'), findsNothing);
  });

  testWidgets('wraps ready form content in a scrollable form', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormBody(
            formKey: formKey,
            children: const [Text('Form field')],
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byKey(formKey), findsOneWidget);
    expect(find.text('Form field'), findsOneWidget);
  });
}
