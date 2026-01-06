import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insta360_sdk/insta360_sdk.dart';
import 'package:insta360_sdk/insta360_sdk_platform_interface.dart';
import 'package:insta360_sdk/insta360_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockInsta360SdkPlatform
    with MockPlatformInterfaceMixin
    implements Insta360SdkPlatform {
  @override
  Stream<Map<String, Object?>> get events => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> connectWifi() async {}

  @override
  Future<void> disconnectWifi() async {}

  @override
  Future<void> connectUsb() async {}

  @override
  Future<void> disconnectUsb() async {}

  @override
  Future<void> connectExternal() async {}

  @override
  Future<void> disconnectExternal() async {}

  @override
  Future<void> startBluetoothScan() async {}

  @override
  Future<void> stopBluetoothScan() async {}

  @override
  Future<void> connectBluetoothDevice(String identifier) async {}

  @override
  Future<void> disconnectBluetoothDevice() async {}

  @override
  Future<void> openCameraWifi({int channel = 0}) async {}

  @override
  Future<void> closeCameraWifi() async {}

  @override
  Future<void> resetCameraWifi({int channel = 0}) async {}

  @override
  Future<void> setWifiCountryCode(String countryCode) async {}

  @override
  Future<Map<String, Object?>> getWifiInfo() async {
    return <String, Object?>{'ssid': 'test'};
  }

  @override
  Future<Map<String, Object?>> getWifiChannelList() async {
    return <String, Object?>{'countryCode': 'US'};
  }

  @override
  Future<void> setWifiProvisioningEnabled(bool enabled) async {}

  @override
  Future<void> startWifiScan({int interval = 1, int count = 3}) async {}

  @override
  Future<void> connectToWifi({
    required String ssid,
    required String password,
    String? bssid,
  }) async {}

  @override
  Future<Map<String, Object?>> getConnectedWifiList() async {
    return <String, Object?>{'list': <Object?>[]};
  }

  @override
  Future<void> startPreview() async {}

  @override
  Future<void> stopPreview() async {}

  @override
  Future<void> takePicture() async {}

  @override
  Future<void> startCapture() async {}

  @override
  Future<void> stopCapture() async {}

  @override
  Future<Map<String, int>> getCameraState() async {
    return <String, int>{'socket': 1};
  }

  @override
  Future<Map<String, Object?>> listMedia({
    int start = 0,
    int limit = 200,
    int storageType = 2,
  }) async {
    return <String, Object?>{
      'photos': <Object?>[],
      'videos': <Object?>[],
    };
  }

  @override
  Future<Uint8List> fetchPhoto(String uri) async {
    return Uint8List(0);
  }

  @override
  Future<String> downloadResource(String uri, {String? targetPath}) async {
    return '/tmp/$uri';
  }

  @override
  Future<void> setPlaybackSources(List<String> sources) async {}

  @override
  Future<void> playbackPlay() async {}

  @override
  Future<void> playbackPause() async {}

  @override
  Future<void> playbackStop() async {}

  @override
  Future<String> exportVideo({
    required List<String> uris,
    String? exportId,
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    return '/tmp/export.mp4';
  }

  @override
  Future<String> exportImage({
    required String uri,
    String? exportId,
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    return '/tmp/export.jpg';
  }
}

void main() {
  final Insta360SdkPlatform initialPlatform = Insta360SdkPlatform.instance;

  test('$MethodChannelInsta360Sdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelInsta360Sdk>());
  });

  test('getCameraState', () async {
    final Insta360Sdk insta360SdkPlugin = Insta360Sdk.instance;
    MockInsta360SdkPlatform fakePlatform = MockInsta360SdkPlatform();
    Insta360SdkPlatform.instance = fakePlatform;

    final state = await insta360SdkPlugin.getCameraState();
    expect(state['socket'], 1);
    Insta360SdkPlatform.instance = initialPlatform;
  });
}
