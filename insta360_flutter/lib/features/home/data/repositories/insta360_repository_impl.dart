import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:insta360_sdk/insta360_sdk.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/bluetooth_device_info.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/wifi_scan_entry.dart';
import '../../domain/repositories/insta360_repository.dart';
import '../datasources/insta360_sdk_data_source.dart';

class Insta360RepositoryImpl implements Insta360Repository {
  Insta360RepositoryImpl({required Insta360SdkDataSource dataSource})
      : _dataSource = dataSource;

  final Insta360SdkDataSource _dataSource;

  @override
  Stream<Insta360Event> events() => _dataSource.events();

  @override
  Future<Result<void>> startBluetoothScan() => _guard(() => _dataSource.startBluetoothScan());

  @override
  Future<Result<void>> stopBluetoothScan() => _guard(() => _dataSource.stopBluetoothScan());

  @override
  Future<Result<void>> connectBluetoothDevice(String identifier) =>
      _guard(() => _dataSource.connectBluetoothDevice(identifier));

  @override
  Future<Result<void>> disconnectBluetoothDevice() =>
      _guard(() => _dataSource.disconnectBluetoothDevice());

  @override
  Future<Result<void>> initialize() => _guard(() => _dataSource.initialize());

  @override
  Future<Result<void>> connectWifi() => _guard(() => _dataSource.connectWifi());

  @override
  Future<Result<void>> disconnectWifi() => _guard(() => _dataSource.disconnectWifi());

  @override
  Future<Result<void>> connectUsb() => _guard(() => _dataSource.connectUsb());

  @override
  Future<Result<void>> disconnectUsb() => _guard(() => _dataSource.disconnectUsb());

  @override
  Future<Result<void>> connectExternal() => _guard(() => _dataSource.connectExternal());

  @override
  Future<Result<void>> disconnectExternal() =>
      _guard(() => _dataSource.disconnectExternal());

  @override
  Future<Result<void>> startPreview() => _guard(() => _dataSource.startPreview());

  @override
  Future<Result<void>> stopPreview() => _guard(() => _dataSource.stopPreview());

  @override
  Future<Result<void>> takePicture() => _guard(() => _dataSource.takePicture());

  @override
  Future<Result<void>> startCapture() => _guard(() => _dataSource.startCapture());

  @override
  Future<Result<void>> stopCapture() => _guard(() => _dataSource.stopCapture());

  @override
  Future<Result<Map<String, Object?>>> getCameraState() =>
      _guard(() => _dataSource.getCameraState());

  @override
  Future<Result<Map<String, Object?>>> getWifiInfo() =>
      _guard(() => _dataSource.getWifiInfo());

  @override
  Future<Result<Map<String, Object?>>> getWifiChannelList() =>
      _guard(() => _dataSource.getWifiChannelList());

  @override
  Future<Result<void>> openWifi({required int channel}) =>
      _guard(() => _dataSource.openWifi(channel: channel));

  @override
  Future<Result<void>> closeWifi() => _guard(() => _dataSource.closeWifi());

  @override
  Future<Result<void>> resetWifi({required int channel}) =>
      _guard(() => _dataSource.resetWifi(channel: channel));

  @override
  Future<Result<void>> setWifiCountryCode(String code) =>
      _guard(() => _dataSource.setWifiCountryCode(code));

  @override
  Future<Result<void>> setWifiProvisioningEnabled(bool enabled) =>
      _guard(() => _dataSource.setWifiProvisioningEnabled(enabled));

  @override
  Future<Result<void>> startWifiScan({required int interval, required int count}) =>
      _guard(() => _dataSource.startWifiScan(interval: interval, count: count));

  @override
  Future<Result<void>> connectToWifi({
    required String ssid,
    required String password,
    String? bssid,
  }) => _guard(() => _dataSource.connectToWifi(ssid: ssid, password: password, bssid: bssid));

  @override
  Future<Result<void>> joinCameraWifi({
    required String ssid,
    required String password,
    bool joinOnce = true,
  }) => _guard(
        () => _dataSource.joinCameraWifi(
          ssid: ssid,
          password: password,
          joinOnce: joinOnce,
        ),
      );

  @override
  Future<Result<Map<String, Object?>>> getConnectedWifiList() =>
      _guard(() => _dataSource.getConnectedWifiList());

  @override
  Future<Result<List<MediaItem>>> listPhotos({required int start, required int limit}) async {
    final response = await _guard(() => _dataSource.listMedia(start: start, limit: limit));
    return response.map((data) => _mapMedia(data['photos'] as List<dynamic>? ?? const []));
  }

  @override
  Future<Result<List<MediaItem>>> listVideos({required int start, required int limit}) async {
    final response = await _guard(() => _dataSource.listMedia(start: start, limit: limit));
    return response.map((data) => _mapMedia(data['videos'] as List<dynamic>? ?? const []));
  }

  @override
  Future<Result<Uint8List>> fetchPhoto(String uri) => _guard(() => _dataSource.fetchPhoto(uri));

  @override
  Future<Result<void>> setPlaybackSources(List<String> uris) =>
      _guard(() => _dataSource.setPlaybackSources(uris));

  @override
  Future<Result<void>> playbackPlay() => _guard(() => _dataSource.playbackPlay());

  @override
  Future<Result<void>> playbackPause() => _guard(() => _dataSource.playbackPause());

  @override
  Future<Result<void>> playbackStop() => _guard(() => _dataSource.playbackStop());

  @override
  Future<Result<String>> downloadResource(String uri) =>
      _guard(() => _dataSource.downloadResource(uri));

  @override
  Future<Result<String>> exportVideo({required List<String> uris}) =>
      _guard(() => _dataSource.exportVideo(uris: uris));

  @override
  Future<Result<String>> exportImage({required String uri}) =>
      _guard(() => _dataSource.exportImage(uri: uri));

  @override
  BluetoothDeviceInfo mapBluetoothDevice({
    required String identifier,
    required String name,
    required int rssi,
  }) {
    return BluetoothDeviceInfo(identifier: identifier, name: name, rssi: rssi);
  }

  @override
  WifiScanEntry mapWifiScanEntry(Map<String, Object?> payload) {
    return WifiScanEntry(
      ssid: payload['ssid'] as String? ?? '',
      bssid: payload['bssid'] as String? ?? '',
      frequency: payload['frequency'] as int? ?? 0,
      signalLevel: payload['signalLevel'] as int? ?? 0,
      flags: payload['flags'] as String? ?? '',
    );
  }

  List<MediaItem> _mapMedia(List<dynamic> list) {
    return list.map((item) {
      final map = Map<String, Object?>.from(item as Map);
      return MediaItem(
        uri: map['uri']?.toString() ?? '',
        name: map['name']?.toString() ?? 'media',
        sizeBytes: (map['size'] as num?)?.toInt() ?? 0,
        raw: map,
      );
    }).toList();
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      final data = await action();
      return right(data);
    } catch (error) {
      if (error is PlatformException) {
        final parts = <String>[];
        if (error.code.isNotEmpty) {
          parts.add('code=${error.code}');
        }
        final message = error.message?.trim();
        if (message != null && message.isNotEmpty) {
          parts.add(message);
        }
        if (error.details != null) {
          parts.add(error.details.toString());
        }
        final detail = parts.isEmpty ? 'SDK operation failed' : parts.join(' | ');
        return left(AppException(detail, details: error));
      }
      return left(AppException('SDK operation failed', details: error));
    }
  }
}
