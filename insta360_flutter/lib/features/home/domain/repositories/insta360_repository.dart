import 'dart:typed_data';

import 'package:insta360_sdk/insta360_sdk.dart';

import '../../../../core/error/result.dart';
import '../entities/bluetooth_device_info.dart';
import '../entities/media_item.dart';
import '../entities/wifi_scan_entry.dart';

abstract class Insta360Repository {
  Stream<Insta360Event> events();

  Future<Result<void>> startBluetoothScan();
  Future<Result<void>> stopBluetoothScan();
  Future<Result<void>> connectBluetoothDevice(String identifier);
  Future<Result<void>> disconnectBluetoothDevice();

  Future<Result<void>> initialize();
  Future<Result<void>> connectWifi();
  Future<Result<void>> disconnectWifi();
  Future<Result<void>> connectUsb();
  Future<Result<void>> disconnectUsb();
  Future<Result<void>> connectExternal();
  Future<Result<void>> disconnectExternal();

  Future<Result<void>> startPreview();
  Future<Result<void>> stopPreview();
  Future<Result<void>> takePicture();
  Future<Result<void>> startCapture();
  Future<Result<void>> stopCapture();

  Future<Result<Map<String, Object?>>> getCameraState();

  Future<Result<Map<String, Object?>>> getWifiInfo();
  Future<Result<Map<String, Object?>>> getWifiChannelList();
  Future<Result<void>> openWifi({required int channel});
  Future<Result<void>> closeWifi();
  Future<Result<void>> resetWifi({required int channel});
  Future<Result<void>> setWifiCountryCode(String code);
  Future<Result<void>> setWifiProvisioningEnabled(bool enabled);
  Future<Result<void>> startWifiScan({required int interval, required int count});
  Future<Result<void>> connectToWifi({
    required String ssid,
    required String password,
    String? bssid,
  });
  Future<Result<void>> joinCameraWifi({
    required String ssid,
    required String password,
    bool joinOnce = true,
  });
  Future<Result<Map<String, Object?>>> getConnectedWifiList();

  Future<Result<List<MediaItem>>> listPhotos({required int start, required int limit});
  Future<Result<List<MediaItem>>> listVideos({required int start, required int limit});
  Future<Result<Uint8List>> fetchPhoto(String uri);
  Future<Result<void>> setPlaybackSources(List<String> uris);
  Future<Result<void>> playbackPlay();
  Future<Result<void>> playbackPause();
  Future<Result<void>> playbackStop();
  Future<Result<String>> downloadResource(String uri);
  Future<Result<String>> exportVideo({required List<String> uris});
  Future<Result<String>> exportImage({required String uri});

  BluetoothDeviceInfo mapBluetoothDevice({
    required String identifier,
    required String name,
    required int rssi,
  });

  WifiScanEntry mapWifiScanEntry(Map<String, Object?> payload);
}
