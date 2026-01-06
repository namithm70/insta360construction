// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing


import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:insta360_sdk/insta360_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getCameraState test', (WidgetTester tester) async {
    final Insta360Sdk plugin = Insta360Sdk.instance;
    await plugin.initialize();
    final state = await plugin.getCameraState();
    expect(state.isNotEmpty, true);
  });
}
