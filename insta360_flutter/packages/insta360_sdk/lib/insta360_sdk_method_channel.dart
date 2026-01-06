import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'insta360_sdk_platform_interface.dart';

/// An implementation of [Insta360SdkPlatform] that uses method channels.
class MethodChannelInsta360Sdk extends Insta360SdkPlatform {
  @visibleForTesting
  final MethodChannel methodChannel =
      const MethodChannel('insta360_sdk/methods');
  @visibleForTesting
  final EventChannel eventChannel =
      const EventChannel('insta360_sdk/events');

  Stream<Map<String, Object?>>? _eventStream;

  @override
  Stream<Map<String, Object?>> get events {
    _eventStream ??= eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, Object?>.from(event as Map));
    return _eventStream!;
  }

  @override
  Future<void> initialize() async {
    await methodChannel.invokeMethod<void>('initialize');
  }

  @override
  Future<void> connectWifi() async {
    await methodChannel.invokeMethod<void>('connectWifi');
  }

  @override
  Future<void> disconnectWifi() async {
    await methodChannel.invokeMethod<void>('disconnectWifi');
  }

  @override
  Future<void> connectUsb() async {
    await methodChannel.invokeMethod<void>('connectUsb');
  }

  @override
  Future<void> disconnectUsb() async {
    await methodChannel.invokeMethod<void>('disconnectUsb');
  }

  @override
  Future<void> connectExternal() async {
    await methodChannel.invokeMethod<void>('connectExternal');
  }

  @override
  Future<void> disconnectExternal() async {
    await methodChannel.invokeMethod<void>('disconnectExternal');
  }

  @override
  Future<void> startBluetoothScan() async {
    await methodChannel.invokeMethod<void>('startBluetoothScan');
  }

  @override
  Future<void> stopBluetoothScan() async {
    await methodChannel.invokeMethod<void>('stopBluetoothScan');
  }

  @override
  Future<void> connectBluetoothDevice(String identifier) async {
    await methodChannel.invokeMethod<void>(
      'connectBluetoothDevice',
      <String, Object?>{'identifier': identifier},
    );
  }

  @override
  Future<void> disconnectBluetoothDevice() async {
    await methodChannel.invokeMethod<void>('disconnectBluetoothDevice');
  }

  @override
  Future<void> openCameraWifi({int channel = 0}) async {
    await methodChannel.invokeMethod<void>(
      'openCameraWifi',
      <String, Object?>{'channel': channel},
    );
  }

  @override
  Future<void> closeCameraWifi() async {
    await methodChannel.invokeMethod<void>('closeCameraWifi');
  }

  @override
  Future<void> resetCameraWifi({int channel = 0}) async {
    await methodChannel.invokeMethod<void>(
      'resetCameraWifi',
      <String, Object?>{'channel': channel},
    );
  }

  @override
  Future<void> setWifiCountryCode(String countryCode) async {
    await methodChannel.invokeMethod<void>(
      'setWifiCountryCode',
      <String, Object?>{'countryCode': countryCode},
    );
  }

  @override
  Future<Map<String, Object?>> getWifiInfo() async {
    final result = await methodChannel.invokeMapMethod<String, Object?>(
      'getWifiInfo',
    );
    return result ?? <String, Object?>{};
  }

  @override
  Future<Map<String, Object?>> getWifiChannelList() async {
    final result = await methodChannel.invokeMapMethod<String, Object?>(
      'getWifiChannelList',
    );
    return result ?? <String, Object?>{};
  }

  @override
  Future<void> setWifiProvisioningEnabled(bool enabled) async {
    await methodChannel.invokeMethod<void>(
      'setWifiProvisioningEnabled',
      <String, Object?>{'enabled': enabled},
    );
  }

  @override
  Future<void> startWifiScan({int interval = 1, int count = 3}) async {
    await methodChannel.invokeMethod<void>(
      'startWifiScan',
      <String, Object?>{'interval': interval, 'count': count},
    );
  }

  @override
  Future<void> connectToWifi({
    required String ssid,
    required String password,
    String? bssid,
  }) async {
    await methodChannel.invokeMethod<void>(
      'connectToWifi',
      <String, Object?>{
        'ssid': ssid,
        'password': password,
        if (bssid != null) 'bssid': bssid,
      },
    );
  }

  @override
  Future<Map<String, Object?>> getConnectedWifiList() async {
    final result = await methodChannel.invokeMapMethod<String, Object?>(
      'getConnectedWifiList',
    );
    return result ?? <String, Object?>{};
  }

  @override
  Future<void> startPreview() async {
    await methodChannel.invokeMethod<void>('startPreview');
  }

  @override
  Future<void> stopPreview() async {
    await methodChannel.invokeMethod<void>('stopPreview');
  }

  @override
  Future<void> takePicture() async {
    await methodChannel.invokeMethod<void>('takePicture');
  }

  @override
  Future<void> startCapture() async {
    await methodChannel.invokeMethod<void>('startCapture');
  }

  @override
  Future<void> stopCapture() async {
    await methodChannel.invokeMethod<void>('stopCapture');
  }

  @override
  Future<Map<String, int>> getCameraState() async {
    final result =
        await methodChannel.invokeMapMethod<String, int>('getCameraState');
    return result ?? <String, int>{};
  }

  @override
  Future<Map<String, Object?>> listMedia({
    int start = 0,
    int limit = 200,
    int storageType = 2,
  }) async {
    final result = await methodChannel.invokeMapMethod<String, Object?>(
      'listMedia',
      <String, Object?>{
        'start': start,
        'limit': limit,
        'storageType': storageType,
      },
    );
    return result ?? <String, Object?>{};
  }

  @override
  Future<Uint8List> fetchPhoto(String uri) async {
    final result = await methodChannel.invokeMethod<Uint8List>(
      'fetchPhoto',
      <String, Object?>{'uri': uri},
    );
    return result ?? Uint8List(0);
  }

  @override
  Future<String> downloadResource(String uri, {String? targetPath}) async {
    final result = await methodChannel.invokeMethod<String>(
      'downloadResource',
      <String, Object?>{
        'uri': uri,
        if (targetPath != null) 'targetPath': targetPath,
      },
    );
    return result ?? '';
  }

  @override
  Future<void> setPlaybackSources(List<String> sources) async {
    await methodChannel.invokeMethod<void>(
      'setPlaybackSources',
      <String, Object?>{'sources': sources},
    );
  }

  @override
  Future<void> playbackPlay() async {
    await methodChannel.invokeMethod<void>('playbackPlay');
  }

  @override
  Future<void> playbackPause() async {
    await methodChannel.invokeMethod<void>('playbackPause');
  }

  @override
  Future<void> playbackStop() async {
    await methodChannel.invokeMethod<void>('playbackStop');
  }

  @override
  Future<String> exportVideo({
    required List<String> uris,
    String? exportId,
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    final result = await methodChannel.invokeMethod<String>(
      'exportVideo',
      <String, Object?>{
        'uris': uris,
        if (exportId != null) 'exportId': exportId,
        'options': options,
      },
    );
    return result ?? '';
  }

  @override
  Future<String> exportImage({
    required String uri,
    String? exportId,
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    final result = await methodChannel.invokeMethod<String>(
      'exportImage',
      <String, Object?>{
        'uri': uri,
        if (exportId != null) 'exportId': exportId,
        'options': options,
      },
    );
    return result ?? '';
  }
}
