import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'insta360_sdk_method_channel.dart';

abstract class Insta360SdkPlatform extends PlatformInterface {
  /// Constructs a Insta360SdkPlatform.
  Insta360SdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static Insta360SdkPlatform _instance = MethodChannelInsta360Sdk();

  /// The default instance of [Insta360SdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelInsta360Sdk].
  static Insta360SdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Insta360SdkPlatform] when
  /// they register themselves.
  static set instance(Insta360SdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<Map<String, Object?>> get events {
    throw UnimplementedError('events has not been implemented.');
  }

  Future<void> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> connectWifi() {
    throw UnimplementedError('connectWifi() has not been implemented.');
  }

  Future<void> disconnectWifi() {
    throw UnimplementedError('disconnectWifi() has not been implemented.');
  }

  Future<void> connectUsb() {
    throw UnimplementedError('connectUsb() has not been implemented.');
  }

  Future<void> disconnectUsb() {
    throw UnimplementedError('disconnectUsb() has not been implemented.');
  }

  Future<void> connectExternal() {
    throw UnimplementedError('connectExternal() has not been implemented.');
  }

  Future<void> disconnectExternal() {
    throw UnimplementedError('disconnectExternal() has not been implemented.');
  }

  Future<void> startBluetoothScan() {
    throw UnimplementedError('startBluetoothScan() has not been implemented.');
  }

  Future<void> stopBluetoothScan() {
    throw UnimplementedError('stopBluetoothScan() has not been implemented.');
  }

  Future<void> connectBluetoothDevice(String identifier) {
    throw UnimplementedError('connectBluetoothDevice() has not been implemented.');
  }

  Future<void> disconnectBluetoothDevice() {
    throw UnimplementedError('disconnectBluetoothDevice() has not been implemented.');
  }

  Future<void> openCameraWifi({int channel = 0}) {
    throw UnimplementedError('openCameraWifi() has not been implemented.');
  }

  Future<void> closeCameraWifi() {
    throw UnimplementedError('closeCameraWifi() has not been implemented.');
  }

  Future<void> resetCameraWifi({int channel = 0}) {
    throw UnimplementedError('resetCameraWifi() has not been implemented.');
  }

  Future<void> setWifiCountryCode(String countryCode) {
    throw UnimplementedError('setWifiCountryCode() has not been implemented.');
  }

  Future<Map<String, Object?>> getWifiInfo() {
    throw UnimplementedError('getWifiInfo() has not been implemented.');
  }

  Future<Map<String, Object?>> getWifiChannelList() {
    throw UnimplementedError('getWifiChannelList() has not been implemented.');
  }

  Future<void> setWifiProvisioningEnabled(bool enabled) {
    throw UnimplementedError('setWifiProvisioningEnabled() has not been implemented.');
  }

  Future<void> startWifiScan({int interval = 1, int count = 3}) {
    throw UnimplementedError('startWifiScan() has not been implemented.');
  }

  Future<void> connectToWifi({
    required String ssid,
    required String password,
    String? bssid,
  }) {
    throw UnimplementedError('connectToWifi() has not been implemented.');
  }

  Future<Map<String, Object?>> getConnectedWifiList() {
    throw UnimplementedError('getConnectedWifiList() has not been implemented.');
  }

  Future<void> startPreview() {
    throw UnimplementedError('startPreview() has not been implemented.');
  }

  Future<void> stopPreview() {
    throw UnimplementedError('stopPreview() has not been implemented.');
  }

  Future<void> takePicture() {
    throw UnimplementedError('takePicture() has not been implemented.');
  }

  Future<void> startCapture() {
    throw UnimplementedError('startCapture() has not been implemented.');
  }

  Future<void> stopCapture() {
    throw UnimplementedError('stopCapture() has not been implemented.');
  }

  Future<Map<String, int>> getCameraState() {
    throw UnimplementedError('getCameraState() has not been implemented.');
  }

  Future<Map<String, Object?>> listMedia({
    int start = 0,
    int limit = 200,
    int storageType = 2,
  }) {
    throw UnimplementedError('listMedia() has not been implemented.');
  }

  Future<Uint8List> fetchPhoto(String uri) {
    throw UnimplementedError('fetchPhoto() has not been implemented.');
  }

  Future<String> downloadResource(String uri, {String? targetPath}) {
    throw UnimplementedError('downloadResource() has not been implemented.');
  }

  Future<void> setPlaybackSources(List<String> sources) {
    throw UnimplementedError('setPlaybackSources() has not been implemented.');
  }

  Future<void> playbackPlay() {
    throw UnimplementedError('playbackPlay() has not been implemented.');
  }

  Future<void> playbackPause() {
    throw UnimplementedError('playbackPause() has not been implemented.');
  }

  Future<void> playbackStop() {
    throw UnimplementedError('playbackStop() has not been implemented.');
  }

  Future<String> exportVideo({
    required List<String> uris,
    String? exportId,
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    throw UnimplementedError('exportVideo() has not been implemented.');
  }

  Future<String> exportImage({
    required String uri,
    String? exportId,
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    throw UnimplementedError('exportImage() has not been implemented.');
  }
}
