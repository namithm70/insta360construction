import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../domain/entities/bluetooth_device_info.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/wifi_scan_entry.dart';

class Insta360State extends Equatable {
  const Insta360State({
    required this.eventLog,
    required this.bluetoothDevices,
    required this.wifiScanList,
    required this.connectedBluetoothId,
    required this.isScanning,
    required this.isConnectingWifi,
    required this.wifiProvisioningEnabled,
    required this.wifiConnectionStatus,
    required this.isLoadingMedia,
    required this.selectedPhotoUri,
    required this.selectedPhotoBytes,
    required this.selectedVideoUris,
    required this.photoList,
    required this.videoList,
    required this.downloadProgress,
    required this.exportProgress,
    required this.exportStatus,
  });

  final List<String> eventLog;
  final Map<String, BluetoothDeviceInfo> bluetoothDevices;
  final List<WifiScanEntry> wifiScanList;
  final String? connectedBluetoothId;
  final bool isScanning;
  final bool isConnectingWifi;
  final bool wifiProvisioningEnabled;
  final String? wifiConnectionStatus;
  final bool isLoadingMedia;
  final String? selectedPhotoUri;
  final Uint8List? selectedPhotoBytes;
  final List<String> selectedVideoUris;
  final List<MediaItem> photoList;
  final List<MediaItem> videoList;
  final Map<String, double> downloadProgress;
  final double? exportProgress;
  final String? exportStatus;

  factory Insta360State.initial() {
    return Insta360State(
      eventLog: const [],
      bluetoothDevices: const {},
      wifiScanList: const [],
      connectedBluetoothId: null,
      isScanning: false,
      isConnectingWifi: false,
      wifiProvisioningEnabled: false,
      wifiConnectionStatus: null,
      isLoadingMedia: false,
      selectedPhotoUri: null,
      selectedPhotoBytes: null,
      selectedVideoUris: const [],
      photoList: const [],
      videoList: const [],
      downloadProgress: const {},
      exportProgress: null,
      exportStatus: null,
    );
  }

  Insta360State copyWith({
    List<String>? eventLog,
    Map<String, BluetoothDeviceInfo>? bluetoothDevices,
    List<WifiScanEntry>? wifiScanList,
    String? connectedBluetoothId,
    bool? isScanning,
    bool? isConnectingWifi,
    bool? wifiProvisioningEnabled,
    String? wifiConnectionStatus,
    bool? isLoadingMedia,
    String? selectedPhotoUri,
    Uint8List? selectedPhotoBytes,
    List<String>? selectedVideoUris,
    List<MediaItem>? photoList,
    List<MediaItem>? videoList,
    Map<String, double>? downloadProgress,
    double? exportProgress,
    String? exportStatus,
  }) {
    return Insta360State(
      eventLog: eventLog ?? this.eventLog,
      bluetoothDevices: bluetoothDevices ?? this.bluetoothDevices,
      wifiScanList: wifiScanList ?? this.wifiScanList,
      connectedBluetoothId: connectedBluetoothId ?? this.connectedBluetoothId,
      isScanning: isScanning ?? this.isScanning,
      isConnectingWifi: isConnectingWifi ?? this.isConnectingWifi,
      wifiProvisioningEnabled:
          wifiProvisioningEnabled ?? this.wifiProvisioningEnabled,
      wifiConnectionStatus: wifiConnectionStatus ?? this.wifiConnectionStatus,
      isLoadingMedia: isLoadingMedia ?? this.isLoadingMedia,
      selectedPhotoUri: selectedPhotoUri ?? this.selectedPhotoUri,
      selectedPhotoBytes: selectedPhotoBytes ?? this.selectedPhotoBytes,
      selectedVideoUris: selectedVideoUris ?? this.selectedVideoUris,
      photoList: photoList ?? this.photoList,
      videoList: videoList ?? this.videoList,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      exportProgress: exportProgress ?? this.exportProgress,
      exportStatus: exportStatus ?? this.exportStatus,
    );
  }

  @override
  List<Object?> get props => [
        eventLog,
        bluetoothDevices,
        wifiScanList,
        connectedBluetoothId,
        isScanning,
        isConnectingWifi,
        wifiProvisioningEnabled,
        wifiConnectionStatus,
        isLoadingMedia,
        selectedPhotoUri,
        selectedPhotoBytes,
        selectedVideoUris,
        photoList,
        videoList,
        downloadProgress,
        exportProgress,
        exportStatus,
      ];
}
