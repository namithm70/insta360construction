import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insta360_sdk/insta360_sdk_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelInsta360Sdk platform = MethodChannelInsta360Sdk();
  const MethodChannel channel = MethodChannel('insta360_sdk/methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getCameraState') {
          return <String, int>{'socket': 1};
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getCameraState', () async {
    final state = await platform.getCameraState();
    expect(state['socket'], 1);
  });
}
