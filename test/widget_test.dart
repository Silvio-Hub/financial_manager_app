// This is a basic Flutter widget test for Financial Manager app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:financial_manager/main.dart';

void main() {
  testWidgets('Financial Manager app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinancialManagerApp());

    // Verify that the app loads and shows login screen
    expect(find.text('Financial Manager'), findsOneWidget);
  });
}
