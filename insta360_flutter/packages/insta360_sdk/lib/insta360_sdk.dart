
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'insta360_sdk_platform_interface.dart';

class Insta360Event {
  final String type;
  final Map<String, Object?> payload;

  Insta360Event(this.type, this.payload);

  factory Insta360Event.fromMap(Map<String, Object?> map) {
    final type = map['type'] as String? ?? 'unknown';
    final payload = Map<String, Object?>.from(map);
    payload.remove('type');
    return Insta360Event(type, payload);
  }
}

class Insta360Sdk {
  Insta360Sdk._();

  static final Insta360Sdk instance = Insta360Sdk._();

  Stream<Insta360Event> get events =>
      Insta360SdkPlatform.instance.events.map(Insta360Event.fromMap);

  Future<void> initialize() {
    return Insta360SdkPlatform.instance.initialize();
  }

  Future<void> connectWifi() {
    return Insta360SdkPlatform.instance.connectWifi();
  }

  Future<void> disconnectWifi() {
    return Insta360SdkPlatform.instance.disconnectWifi();
  }

  Future<void> connectUsb() {
    return Insta360SdkPlatform.instance.connectUsb();
  }

  Future<void> disconnectUsb() {
    return Insta360SdkPlatform.instance.disconnectUsb();
  }

  Future<void> connectExternal() {
    return Insta360SdkPlatform.instance.connectExternal();
  }

  Future<void> disconnectExternal() {
    return Insta360SdkPlatform.instance.disconnectExternal();
  }

  Future<void> startBluetoothScan() {
    return Insta360SdkPlatform.instance.startBluetoothScan();
  }

  Future<void> stopBluetoothScan() {
    return Insta360SdkPlatform.instance.stopBluetoothScan();
  }

  Future<void> connectBluetoothDevice(String identifier) {
    return Insta360SdkPlatform.instance.connectBluetoothDevice(identifier);
  }

  Future<void> disconnectBluetoothDevice() {
    return Insta360SdkPlatform.instance.disconnectBluetoothDevice();
  }

  Future<void> openCameraWifi({int channel = 0}) {
    return Insta360SdkPlatform.instance.openCameraWifi(channel: channel);
  }

  Future<void> closeCameraWifi() {
    return Insta360SdkPlatform.instance.closeCameraWifi();
  }

  Future<void> resetCameraWifi({int channel = 0}) {
    return Insta360SdkPlatform.instance.resetCameraWifi(channel: channel);
  }

  Future<void> setWifiCountryCode(String countryCode) {
    return Insta360SdkPlatform.instance.setWifiCountryCode(countryCode);
  }

  Future<Map<String, Object?>> getWifiInfo() {
    return Insta360SdkPlatform.instance.getWifiInfo();
  }

  Future<Map<String, Object?>> getWifiChannelList() {
    return Insta360SdkPlatform.instance.getWifiChannelList();
  }

  Future<void> setWifiProvisioningEnabled(bool enabled) {
    return Insta360SdkPlatform.instance.setWifiProvisioningEnabled(enabled);
  }

  Future<void> startWifiScan({int interval = 1, int count = 3}) {
    return Insta360SdkPlatform.instance.startWifiScan(
      interval: interval,
      count: count,
    );
  }

  Future<void> connectToWifi({
    required String ssid,
    required String password,
    String? bssid,
  }) {
    return Insta360SdkPlatform.instance.connectToWifi(
      ssid: ssid,
      password: password,
      bssid: bssid,
    );
  }

  Future<void> joinCameraWifi({
    required String ssid,
    required String password,
    bool joinOnce = true,
  }) {
    return Insta360SdkPlatform.instance.joinCameraWifi(
      ssid: ssid,
      password: password,
      joinOnce: joinOnce,
    );
  }

  Future<Map<String, Object?>> getConnectedWifiList() {
    return Insta360SdkPlatform.instance.getConnectedWifiList();
  }

  Future<void> startPreview() {
    return Insta360SdkPlatform.instance.startPreview();
  }

  Future<void> stopPreview() {
    return Insta360SdkPlatform.instance.stopPreview();
  }

  Future<void> takePicture() {
    return Insta360SdkPlatform.instance.takePicture();
  }

  Future<void> startCapture() {
    return Insta360SdkPlatform.instance.startCapture();
  }

  Future<void> stopCapture() {
    return Insta360SdkPlatform.instance.stopCapture();
  }

  Future<Map<String, int>> getCameraState() {
    return Insta360SdkPlatform.instance.getCameraState();
  }

  Future<Map<String, Object?>> listMedia({
    int start = 0,
    int limit = 200,
    int storageType = 2,
  }) {
    return Insta360SdkPlatform.instance.listMedia(
      start: start,
      limit: limit,
      storageType: storageType,
    );
  }

  Future<Uint8List> fetchPhoto(String uri) {
    return Insta360SdkPlatform.instance.fetchPhoto(uri);
  }

  Future<String> downloadResource(String uri, {String? targetPath}) {
    return Insta360SdkPlatform.instance.downloadResource(
      uri,
      targetPath: targetPath,
    );
  }

  Future<void> setPlaybackSources(List<String> sources) {
    return Insta360SdkPlatform.instance.setPlaybackSources(sources);
  }

  Future<void> playbackPlay() {
    return Insta360SdkPlatform.instance.playbackPlay();
  }

  Future<void> playbackPause() {
    return Insta360SdkPlatform.instance.playbackPause();
  }

  Future<void> playbackStop() {
    return Insta360SdkPlatform.instance.playbackStop();
  }

  Future<String> exportVideo({
    required List<String> uris,
    String? exportId,
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    return Insta360SdkPlatform.instance.exportVideo(
      uris: uris,
      exportId: exportId,
      options: options,
    );
  }

  Future<String> exportImage({
    required String uri,
    String? exportId,
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    return Insta360SdkPlatform.instance.exportImage(
      uri: uri,
      exportId: exportId,
      options: options,
    );
  }
}

class Insta360Preview extends StatelessWidget {
  const Insta360Preview({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return const UiKitView(
        viewType: 'insta360_sdk/preview',
      );
    }
    if (Platform.isAndroid) {
      return const AndroidView(
        viewType: 'insta360_sdk/preview',
      );
    }
    return const Center(
      child: Text('Insta360 preview is only supported on iOS/Android.'),
    );
  }
}

class Insta360Player extends StatelessWidget {
  const Insta360Player({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return const Center(
        child: Text('Insta360 playback is only supported on iOS.'),
      );
    }
    return const UiKitView(
      viewType: 'insta360_sdk/player',
    );
  }
}
