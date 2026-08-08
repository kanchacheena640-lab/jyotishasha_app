import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('integration test infrastructure is discoverable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Text('Integration testing foundation ready')),
    );

    expect(find.text('Integration testing foundation ready'), findsOneWidget);
  });
}
