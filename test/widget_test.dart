// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_app/app.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SafeRouteApp(enableUsbBlocker: false));

    // Verify that the app starts and shows the initialization state.
    // Note: Since we use GetIt and Providers, this test might need 
    // proper mocking for a full integration test, but for a smoke test 
    // it checks if the widget tree builds.
    expect(find.text('SafeRoute'), findsNothing); // Should be loading or login
  });
}
