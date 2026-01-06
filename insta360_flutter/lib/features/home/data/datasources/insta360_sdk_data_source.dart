import 'dart:typed_data';

import 'package:insta360_sdk/insta360_sdk.dart';

class Insta360SdkDataSource {
  Insta360SdkDataSource({Insta360Sdk? sdk}) : _sdk = sdk ?? Insta360Sdk.instance;

  final Insta360Sdk _sdk;

  Stream<Insta360Event> events() => _sdk.events;

  Future<void> startBluetoothScan() => _sdk.startBluetoothScan();
  Future<void> stopBluetoothScan() => _sdk.stopBluetoothScan();
  Future<void> connectBluetoothDevice(String identifier) =>
      _sdk.connectBluetoothDevice(identifier);
  Future<void> disconnectBluetoothDevice() => _sdk.disconnectBluetoothDevice();

  Future<void> initialize() => _sdk.initialize();
  Future<void> connectWifi() => _sdk.connectWifi();
  Future<void> disconnectWifi() => _sdk.disconnectWifi();
  Future<void> connectUsb() => _sdk.connectUsb();
  Future<void> disconnectUsb() => _sdk.disconnectUsb();
  Future<void> connectExternal() => _sdk.connectExternal();
  Future<void> disconnectExternal() => _sdk.disconnectExternal();

  Future<void> startPreview() => _sdk.startPreview();
  Future<void> stopPreview() => _sdk.stopPreview();
  Future<void> takePicture() => _sdk.takePicture();
  Future<void> startCapture() => _sdk.startCapture();
  Future<void> stopCapture() => _sdk.stopCapture();

  Future<Map<String, Object?>> getCameraState() => _sdk.getCameraState();

  Future<Map<String, Object?>> getWifiInfo() => _sdk.getWifiInfo();
  Future<Map<String, Object?>> getWifiChannelList() => _sdk.getWifiChannelList();
  Future<void> openWifi({required int channel}) => _sdk.openCameraWifi(channel: channel);
  Future<void> closeWifi() => _sdk.closeCameraWifi();
  Future<void> resetWifi({required int channel}) => _sdk.resetCameraWifi(channel: channel);
  Future<void> setWifiCountryCode(String code) => _sdk.setWifiCountryCode(code);
  Future<void> setWifiProvisioningEnabled(bool enabled) =>
      _sdk.setWifiProvisioningEnabled(enabled);
  Future<void> startWifiScan({required int interval, required int count}) =>
      _sdk.startWifiScan(interval: interval, count: count);
  Future<void> connectToWifi({
    required String ssid,
    required String password,
    String? bssid,
  }) =>
      _sdk.connectToWifi(ssid: ssid, password: password, bssid: bssid);
  Future<Map<String, Object?>> getConnectedWifiList() => _sdk.getConnectedWifiList();

  Future<Map<String, Object?>> listMedia({required int start, required int limit}) =>
      _sdk.listMedia(start: start, limit: limit);
  Future<Uint8List> fetchPhoto(String uri) => _sdk.fetchPhoto(uri);
  Future<void> setPlaybackSources(List<String> uris) => _sdk.setPlaybackSources(uris);
  Future<void> playbackPlay() => _sdk.playbackPlay();
  Future<void> playbackPause() => _sdk.playbackPause();
  Future<void> playbackStop() => _sdk.playbackStop();
  Future<String> downloadResource(String uri) => _sdk.downloadResource(uri);
  Future<String> exportVideo({required List<String> uris}) => _sdk.exportVideo(uris: uris);
  Future<String> exportImage({required String uri}) => _sdk.exportImage(uri: uri);
}
