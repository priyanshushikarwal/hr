// HRMS Desktop - Widget Test
// Basic smoke test for the HRMS application

import 'package:flutter_test/flutter_test.dart';
import 'package:hr_desktop/main.dart';

void main() {
  testWidgets('HRMS app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HRMSApp());

    // Verify that the app starts without crashing
    // The app should show the dashboard or a loading indicator
    expect(find.byType(HRMSApp), findsOneWidget);
  });
}
