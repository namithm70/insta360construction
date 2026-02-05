import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:insta360_sdk/insta360_sdk.dart' as sdk;

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/bluetooth_device_info.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/wifi_scan_entry.dart';
import '../../../../core/storage/wifi_credentials_store.dart';
import '../../domain/repositories/insta360_repository.dart';
import 'insta360_event.dart';
import 'insta360_state.dart';

class Insta360Bloc extends Bloc<Insta360UiEvent, Insta360State> {
  Insta360Bloc({
    required Insta360Repository repository,
    required WifiCredentialsStore wifiStore,
  })  : _repository = repository,
        _wifiStore = wifiStore,
        super(Insta360State.initial()) {
    _subscription = _repository.events().listen(
          (event) => add(SdkEventReceived(event)),
          onError: (error) => add(ClientLogRequested('events: $error')),
        );

    on<SdkEventReceived>(_onSdkEvent);
    on<ClientLogRequested>(_onClientLog);
    on<StartBluetoothScanRequested>(_onStartBluetoothScan);
    on<StopBluetoothScanRequested>(_onStopBluetoothScan);
    on<ConnectBluetoothRequested>(_onConnectBluetooth);
    on<DisconnectBluetoothRequested>(_onDisconnectBluetooth);
    on<ResetBluetoothDevicesRequested>(_onResetBluetoothDevices);
    on<InitializeRequested>(_onInitialize);
    on<ConnectDeviceWifiRequested>(_onConnectDeviceWifi);
    on<DisconnectDeviceWifiRequested>(_onDisconnectDeviceWifi);
    on<ConnectUsbRequested>(_onConnectUsb);
    on<DisconnectUsbRequested>(_onDisconnectUsb);
    on<ConnectExternalRequested>(_onConnectExternal);
    on<DisconnectExternalRequested>(_onDisconnectExternal);
    on<StartPreviewRequested>(_onStartPreview);
    on<StopPreviewRequested>(_onStopPreview);
    on<TakePictureRequested>(_onTakePicture);
    on<StartCaptureRequested>(_onStartCapture);
    on<StopCaptureRequested>(_onStopCapture);
    on<FetchCameraStateRequested>(_onFetchCameraState);
    on<GetWifiInfoRequested>(_onGetWifiInfo);
    on<GetWifiChannelListRequested>(_onGetWifiChannelList);
    on<OpenWifiRequested>(_onOpenWifi);
    on<CloseWifiRequested>(_onCloseWifi);
    on<ResetWifiRequested>(_onResetWifi);
    on<SetWifiCountryCodeRequested>(_onSetWifiCountryCode);
    on<SetWifiProvisioningRequested>(_onSetWifiProvisioning);
    on<StartWifiScanRequested>(_onStartWifiScan);
    on<ConnectWifiRequested>(_onConnectWifi);
    on<GetConnectedWifiListRequested>(_onGetConnectedWifiList);
    on<FetchMediaRequested>(_onFetchMedia);
    on<ResetMediaRequested>(_onResetMedia);
    on<SelectPhotoRequested>(_onSelectPhoto);
    on<ToggleVideoSelectionRequested>(_onToggleVideoSelection);
    on<LoadPlaybackSourcesRequested>(_onLoadPlaybackSources);
    on<PlaybackPlayRequested>(_onPlaybackPlay);
    on<PlaybackPauseRequested>(_onPlaybackPause);
    on<PlaybackStopRequested>(_onPlaybackStop);
    on<DownloadMediaRequested>(_onDownloadMedia);
    on<ExportVideoRequested>(_onExportVideo);
    on<ExportPhotoRequested>(_onExportPhoto);
  }

  final Insta360Repository _repository;
  final WifiCredentialsStore _wifiStore;
  StreamSubscription<sdk.Insta360Event>? _subscription;
  bool _pendingPreview = false;
  int _previewRetryCount = 0;
  Future<bool>? _wifiOpenTask;
  Future<bool>? _wifiJoinTask;
  Future<void>? _connectWifiTask;
  bool _wifiJoined = false;
  String? _lastWifiSsid;
  String? _lastWifiPassword;
  static const String _defaultWifiCountryCode = 'US';
  bool _isBluetoothConnected = false;
  bool _connectInProgress = false;
  int _connectToken = 0;
  Timer? _connectTimeout;
  final List<String> _logBuffer = [];
  Timer? _logFlushTimer;
  static const Duration _logFlushInterval = Duration(milliseconds: 300);

  @override
  Future<void> close() {
    _subscription?.cancel();
    _connectTimeout?.cancel();
    _logFlushTimer?.cancel();
    return super.close();
  }

  void _appendLog(String message) {
    _logBuffer.insert(0, '${DateTime.now().toIso8601String()} $message');
    if (_logBuffer.length >= 40) {
      _flushLogBuffer();
      return;
    }
    _logFlushTimer ??= Timer(_logFlushInterval, _flushLogBuffer);
  }

  void _flushLogBuffer() {
    _logFlushTimer?.cancel();
    _logFlushTimer = null;
    if (_logBuffer.isEmpty) {
      return;
    }
    final log = List<String>.from(state.eventLog);
    log.insertAll(0, _logBuffer);
    _logBuffer.clear();
    if (log.length > 200) {
      log.removeRange(200, log.length);
    }
    emit(state.copyWith(eventLog: log));
  }

  Future<void> _onSdkEvent(
    SdkEventReceived event,
    Emitter<Insta360State> emit,
  ) async {
    final sdkEvent = event.event;
    switch (sdkEvent.type) {
      case 'bluetooth_scan_started':
        emit(state.copyWith(isScanning: true));
        _appendLog('bluetooth_scan_started');
        return;
      case 'bluetooth_scan_stopped':
        emit(state.copyWith(isScanning: false));
        _appendLog('bluetooth_scan_stopped');
        return;
      case 'bluetooth_device_found':
        final identifier = sdkEvent.payload['identifier'] as String?;
        final name = sdkEvent.payload['name'] as String? ?? 'unknown';
        final rssi = sdkEvent.payload['rssi'] as int? ?? 0;
        if (identifier == null) {
          _appendLog('bluetooth_device_found: missing identifier');
          return;
        }
        final devices = Map<String, BluetoothDeviceInfo>.from(
          state.bluetoothDevices,
        );
        devices[identifier] = _repository.mapBluetoothDevice(
          identifier: identifier,
          name: name,
          rssi: rssi,
        );
        emit(state.copyWith(bluetoothDevices: devices));
        _appendLog('bluetooth_device_found: $name ($identifier) rssi=$rssi');
        return;
      case 'bluetooth_connected':
        final identifier = sdkEvent.payload['identifier'] as String?;
        final name = sdkEvent.payload['name'] as String? ?? 'unknown';
        emit(state.copyWith(connectedBluetoothId: identifier));
        _isBluetoothConnected = true;
        _appendLog('bluetooth_connected: $name ${identifier ?? ''}'.trim());
        return;
      case 'bluetooth_disconnected':
        final identifier = sdkEvent.payload['identifier'] as String?;
        final error = sdkEvent.payload['error'] as String?;
        _isBluetoothConnected = false;
        _wifiJoined = false;
        _lastWifiSsid = null;
        _lastWifiPassword = null;
        _pendingPreview = false;
        _finishConnectWorkflow();
        emit(
          state.copyWith(
            connectedBluetoothId: state.connectedBluetoothId == identifier
                ? null
                : state.connectedBluetoothId,
          ),
        );
        _appendLog(
          'bluetooth_disconnected: ${identifier ?? 'unknown'}'
          '${error != null ? ' ($error)' : ''}',
        );
        return;
      case 'bluetooth_connect_failed':
        final identifier = sdkEvent.payload['identifier'] as String?;
        final error = sdkEvent.payload['error'] as String?;
        _appendLog(
          'bluetooth_connect_failed: ${identifier ?? 'unknown'}'
          '${error != null ? ' ($error)' : ''}',
        );
        return;
      case 'wifi_scan_list':
        final list = sdkEvent.payload['list'] as List<dynamic>? ?? const [];
        final entries = list.map((item) {
          final map = Map<String, Object?>.from(item as Map);
          return _repository.mapWifiScanEntry(map);
        }).toList();
        emit(state.copyWith(wifiScanList: entries));
        _appendLog('wifi_scan_list: ${entries.length} networks');
        return;
      case 'wifi_connection_result':
        final result = Map<String, Object?>.from(
          sdkEvent.payload['result'] as Map,
        );
        final code = result['code'];
        final ssid = result['ssid'];
        emit(
          state.copyWith(wifiConnectionStatus: 'code=$code ssid=$ssid'),
        );
        _appendLog('wifi_connection_result: ${state.wifiConnectionStatus}');
        return;
      case 'download_progress':
        final uri = sdkEvent.payload['uri'] as String?;
        final progress = (sdkEvent.payload['progress'] as num?)?.toDouble();
        if (uri != null && progress != null) {
          final progressMap = Map<String, double>.from(state.downloadProgress);
          progressMap[uri] = progress;
          emit(state.copyWith(downloadProgress: progressMap));
        }
        return;
      case 'download_complete':
        final uri = sdkEvent.payload['uri'] as String?;
        final path = sdkEvent.payload['path'] as String?;
        if (uri != null) {
          final progressMap = Map<String, double>.from(state.downloadProgress);
          progressMap[uri] = 1.0;
          emit(state.copyWith(downloadProgress: progressMap));
        }
        _appendLog(
          'download_complete: ${uri ?? 'unknown'} ${path ?? ''}'.trim(),
        );
        return;
      case 'download_failed':
        final uri = sdkEvent.payload['uri'] as String?;
        final error = sdkEvent.payload['error'] as String?;
        _appendLog(
          'download_failed: ${uri ?? 'unknown'}'
          '${error != null ? ' ($error)' : ''}',
        );
        return;
      case 'export_progress':
        final progress = (sdkEvent.payload['progress'] as num?)?.toDouble();
        if (progress != null) {
          emit(
            state.copyWith(
              exportProgress: progress,
              exportStatus: 'export ${(progress * 100).round()}%',
            ),
          );
        }
        return;
      case 'export_complete':
        final path = sdkEvent.payload['outputPath'] as String?;
        emit(
          state.copyWith(exportProgress: 1.0, exportStatus: 'export complete'),
        );
        _appendLog('export_complete: ${path ?? ''}'.trim());
        return;
      case 'export_failed':
        final error = sdkEvent.payload['error'] as String?;
        emit(
          state.copyWith(exportProgress: null, exportStatus: 'export failed'),
        );
        _appendLog('export_failed: ${error ?? ''}');
        return;
      case 'camera_state':
        final source = sdkEvent.payload['source'];
        final stateName = sdkEvent.payload['stateName'];
        _appendLog('camera_state: $source -> $stateName');
        if (source == 'socket') {
          if (stateName == 'connected') {
            _finishConnectWorkflow();
            if (_pendingPreview) {
              _pendingPreview = false;
              _previewRetryCount = 0;
              await _logResult('start_preview', _repository.startPreview);
            }
          } else if (_pendingPreview && stateName == 'no_connection') {
            if (_previewRetryCount < 3) {
              _previewRetryCount += 1;
              Future<void>(() async {
                await Future.delayed(const Duration(seconds: 2));
                if (_pendingPreview) {
                  await _logResult('connect_wifi_retry', _repository.connectWifi);
                }
              });
            } else {
              _appendLog('start_preview: failed to connect after retries');
              _pendingPreview = false;
              _finishConnectWorkflow();
            }
          } else if (stateName == 'connect_failed' || stateName == 'no_connection') {
            _appendLog('connect_wifi: failed');
            _pendingPreview = false;
            _finishConnectWorkflow();
          }
        }
        return;
      case 'notification':
        final name = sdkEvent.payload['name'];
        _appendLog('notification: $name');
        return;
      default:
        _appendLog('event: ${sdkEvent.type} ${sdkEvent.payload}');
    }
  }

  Future<void> _onClientLog(
    ClientLogRequested event,
    Emitter<Insta360State> emit,
  ) async {
    _appendLog(event.message);
  }

  Future<void> _onStartBluetoothScan(
    StartBluetoothScanRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('bluetooth_scan', _repository.startBluetoothScan);
  }

  Future<void> _onStopBluetoothScan(
    StopBluetoothScanRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('bluetooth_stop_scan', _repository.stopBluetoothScan);
  }

  Future<void> _onConnectBluetooth(
    ConnectBluetoothRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult(
      'bluetooth_connect',
      () => _repository.connectBluetoothDevice(event.identifier),
    );
  }

  Future<void> _onDisconnectBluetooth(
    DisconnectBluetoothRequested event,
    Emitter<Insta360State> emit,
  ) async {
    _pendingPreview = false;
    await _logResult('bluetooth_disconnect', _repository.disconnectBluetoothDevice);
  }

  Future<void> _onResetBluetoothDevices(
    ResetBluetoothDevicesRequested event,
    Emitter<Insta360State> emit,
  ) async {
    emit(state.copyWith(bluetoothDevices: const {}));
    _appendLog('bluetooth_devices: cleared');
  }

  Future<void> _onInitialize(
    InitializeRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('initialize', _repository.initialize);
  }

  Future<void> _onConnectDeviceWifi(
    ConnectDeviceWifiRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _startConnectWorkflow(startPreview: false);
  }

  Future<void> _onDisconnectDeviceWifi(
    DisconnectDeviceWifiRequested event,
    Emitter<Insta360State> emit,
  ) async {
    _pendingPreview = false;
    _wifiJoined = false;
    _lastWifiSsid = null;
    _lastWifiPassword = null;
    _finishConnectWorkflow();
    await _logResult('disconnect_wifi', _repository.disconnectWifi);
  }

  Future<void> _onConnectUsb(
    ConnectUsbRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('connect_usb', _repository.connectUsb);
  }

  Future<void> _onDisconnectUsb(
    DisconnectUsbRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('disconnect_usb', _repository.disconnectUsb);
  }

  Future<void> _onConnectExternal(
    ConnectExternalRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('connect_external', _repository.connectExternal);
  }

  Future<void> _onDisconnectExternal(
    DisconnectExternalRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('disconnect_external', _repository.disconnectExternal);
  }

  Future<void> _onStartPreview(
    StartPreviewRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _startConnectWorkflow(startPreview: true);
  }

  Future<void> _onStopPreview(
    StopPreviewRequested event,
    Emitter<Insta360State> emit,
  ) async {
    _pendingPreview = false;
    await _logResult('stop_preview', _repository.stopPreview);
  }

  Future<void> _onTakePicture(
    TakePictureRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('take_picture', _repository.takePicture);
  }

  Future<void> _onStartCapture(
    StartCaptureRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('start_capture', _repository.startCapture);
  }

  Future<void> _onStopCapture(
    StopCaptureRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('stop_capture', _repository.stopCapture);
  }

  Future<void> _onFetchCameraState(
    FetchCameraStateRequested event,
    Emitter<Insta360State> emit,
  ) async {
    final result = await _repository.getCameraState();
    _handleLog('camera_state_snapshot', result);
  }

  Future<void> _onGetWifiInfo(
    GetWifiInfoRequested event,
    Emitter<Insta360State> emit,
  ) async {
    final result = await _repository.getWifiInfo();
    _handleLog('wifi_info', result);
  }

  Future<void> _onGetWifiChannelList(
    GetWifiChannelListRequested event,
    Emitter<Insta360State> emit,
  ) async {
    final result = await _repository.getWifiChannelList();
    _handleLog('wifi_channel_list', result);
  }

  Future<void> _onOpenWifi(
    OpenWifiRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('wifi_open', () => _repository.openWifi(channel: event.channel));
  }

  Future<void> _onCloseWifi(
    CloseWifiRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('wifi_close', _repository.closeWifi);
  }

  Future<void> _onResetWifi(
    ResetWifiRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('wifi_reset', () => _repository.resetWifi(channel: event.channel));
  }

  Future<void> _onSetWifiCountryCode(
    SetWifiCountryCodeRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult(
      'wifi_country_code',
      () => _repository.setWifiCountryCode(event.code),
    );
  }

  Future<void> _onSetWifiProvisioning(
    SetWifiProvisioningRequested event,
    Emitter<Insta360State> emit,
  ) async {
    final result = await _repository.setWifiProvisioningEnabled(event.enabled);
    _handleLog('wifi_provisioning', result);
    if (result.isRight()) {
      emit(state.copyWith(wifiProvisioningEnabled: event.enabled));
    }
  }

  Future<void> _onStartWifiScan(
    StartWifiScanRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult(
      'wifi_scan',
      () => _repository.startWifiScan(interval: event.interval, count: event.count),
    );
  }

  Future<void> _onConnectWifi(
    ConnectWifiRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult(
      'wifi_connect',
      () => _repository.connectToWifi(
        ssid: event.ssid,
        password: event.password,
        bssid: event.bssid,
      ),
    );
  }

  Future<void> _onGetConnectedWifiList(
    GetConnectedWifiListRequested event,
    Emitter<Insta360State> emit,
  ) async {
    final result = await _repository.getConnectedWifiList();
    _handleLog('wifi_connect_list', result);
  }

  Future<void> _onFetchMedia(
    FetchMediaRequested event,
    Emitter<Insta360State> emit,
  ) async {
    emit(state.copyWith(isLoadingMedia: true));
    final photosResult =
        await _repository.listPhotos(start: event.start, limit: event.limit);
    final videosResult =
        await _repository.listVideos(start: event.start, limit: event.limit);

    photosResult.fold(
      (error) => _appendLog('media_list: ${error.message}'),
      (photos) => emit(state.copyWith(photoList: photos)),
    );
    videosResult.fold(
      (error) => _appendLog('media_list: ${error.message}'),
      (videos) => emit(state.copyWith(videoList: videos)),
    );

    emit(state.copyWith(isLoadingMedia: false));
    if (photosResult.isRight() && videosResult.isRight()) {
      _appendLog(
        'media_list: photos=${state.photoList.length} videos=${state.videoList.length}',
      );
    }
  }

  Future<void> _onResetMedia(
    ResetMediaRequested event,
    Emitter<Insta360State> emit,
  ) async {
    emit(
      state.copyWith(
        photoList: const [],
        videoList: const [],
        selectedPhotoUri: null,
        selectedPhotoBytes: null,
        selectedVideoUris: const [],
        downloadProgress: const {},
        exportProgress: null,
        exportStatus: null,
      ),
    );
    _appendLog('media_list: cleared');
  }

  Future<void> _onSelectPhoto(
    SelectPhotoRequested event,
    Emitter<Insta360State> emit,
  ) async {
    emit(state.copyWith(selectedPhotoUri: event.uri, selectedPhotoBytes: null));
    final result = await _repository.fetchPhoto(event.uri);
    result.fold(
      (error) => _appendLog('fetch_photo: ${error.message}'),
      (bytes) => emit(state.copyWith(selectedPhotoBytes: bytes)),
    );
  }

  Future<void> _onToggleVideoSelection(
    ToggleVideoSelectionRequested event,
    Emitter<Insta360State> emit,
  ) async {
    final selected = List<String>.from(state.selectedVideoUris);
    if (selected.contains(event.uri)) {
      selected.remove(event.uri);
    } else {
      if (selected.length >= 2) {
        selected.removeAt(0);
      }
      selected.add(event.uri);
    }
    emit(state.copyWith(selectedVideoUris: selected));
  }

  Future<void> _onLoadPlaybackSources(
    LoadPlaybackSourcesRequested event,
    Emitter<Insta360State> emit,
  ) async {
    if (state.selectedVideoUris.isEmpty) {
      _appendLog('select a video to play');
      return;
    }
    await _logResult(
      'set_playback_sources',
      () => _repository.setPlaybackSources(List<String>.from(state.selectedVideoUris)),
    );
  }

  Future<void> _onPlaybackPlay(
    PlaybackPlayRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('playback_play', _repository.playbackPlay);
  }

  Future<void> _onPlaybackPause(
    PlaybackPauseRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('playback_pause', _repository.playbackPause);
  }

  Future<void> _onPlaybackStop(
    PlaybackStopRequested event,
    Emitter<Insta360State> emit,
  ) async {
    await _logResult('playback_stop', _repository.playbackStop);
  }

  Future<void> _onDownloadMedia(
    DownloadMediaRequested event,
    Emitter<Insta360State> emit,
  ) async {
    final result = await _repository.downloadResource(event.uri);
    _handleLog('download', result);
  }

  Future<void> _onExportVideo(
    ExportVideoRequested event,
    Emitter<Insta360State> emit,
  ) async {
    if (state.selectedVideoUris.isEmpty) {
      _appendLog('select a video to export');
      return;
    }
    emit(state.copyWith(exportProgress: 0, exportStatus: 'export started'));
    final result = await _repository.exportVideo(
      uris: List<String>.from(state.selectedVideoUris),
    );
    _handleLog('export_video', result);
  }

  Future<void> _onExportPhoto(
    ExportPhotoRequested event,
    Emitter<Insta360State> emit,
  ) async {
    if (event.uri.isEmpty) {
      _appendLog('select a photo to export');
      return;
    }
    emit(state.copyWith(exportProgress: 0, exportStatus: 'export started'));
    final result = await _repository.exportImage(uri: event.uri);
    _handleLog('export_image', result);
  }

  Future<void> _logResult(String label, Future<Either<AppException, void>> Function() action) async {
    final result = await action();
    _handleLog(label, result);
  }

  void _handleLog<T>(String label, Either<AppException, T> result) {
    result.fold(
      (error) => _appendLog('$label: ${error.message}'),
      (data) => _appendLog('$label: $data'),
    );
  }

  Future<void> _startConnectWorkflow({required bool startPreview}) async {
    if (_connectInProgress) {
      _appendLog('connect_workflow: busy');
      return;
    }
    if (!_isBluetoothConnected) {
      _appendLog('connect_workflow: bluetooth not connected');
      return;
    }
    _connectInProgress = true;
    emit(state.copyWith(isConnectingWifi: true));
    final token = ++_connectToken;
    _connectTimeout?.cancel();
    _connectTimeout = Timer(const Duration(seconds: 20), () {
      if (_isActiveToken(token) && _connectInProgress) {
        _appendLog('connect_workflow: timeout');
        _pendingPreview = false;
        _finishConnectWorkflow();
      }
    });

    if (startPreview) {
      _pendingPreview = true;
      _previewRetryCount = 0;
    }

    if (state.isScanning) {
      await _logResult('bluetooth_stop_scan', _repository.stopBluetoothScan);
    }

    final opened = await _openWifiWithRetry(channel: 0);
    if (!_isActiveToken(token) || !opened) {
      _finishConnectWorkflow(clearPendingPreview: true);
      return;
    }

    final joined = await _attemptJoinCameraWifi();
    if (!_isActiveToken(token) || !joined) {
      _finishConnectWorkflow(clearPendingPreview: true);
      return;
    }

    await Future.delayed(const Duration(seconds: 2));
    if (!_isActiveToken(token)) {
      _finishConnectWorkflow(clearPendingPreview: true);
      return;
    }

    await _connectWifiOnce();
  }

  bool _isActiveToken(int token) => _connectToken == token;

  void _finishConnectWorkflow({bool clearPendingPreview = false}) {
    if (!_connectInProgress && !state.isConnectingWifi) {
      return;
    }
    _connectTimeout?.cancel();
    _connectTimeout = null;
    _connectInProgress = false;
    if (clearPendingPreview) {
      _pendingPreview = false;
    }
    emit(state.copyWith(isConnectingWifi: false));
  }

  Future<bool> _attemptJoinCameraWifi() async {
    if (_wifiJoined) {
      _appendLog('wifi_join: already joined');
      return true;
    }
    final inFlight = _wifiJoinTask;
    if (inFlight != null) {
      _appendLog('wifi_join: awaiting in-flight');
      return await inFlight;
    }
    final task = _attemptJoinCameraWifiInternal();
    _wifiJoinTask = task;
    try {
      return await task;
    } finally {
      _wifiJoinTask = null;
    }
  }

  Future<bool> _attemptJoinCameraWifiInternal() async {
    _WifiInfoSnapshot? info;
    if (_isBluetoothConnected) {
      info = await _fetchWifiInfoWithRetry();
      if (info != null) {
        await _cacheWifiCredentials(info.ssid, info.password);
      }
    } else {
      _appendLog('wifi_join: bluetooth not connected');
    }

    _WifiInfoSnapshot? source = info;
    if (source == null) {
      source = await _loadCachedWifiCredentials();
      if (source != null) {
        _appendLog('wifi_join: using cached ssid ${source.ssid}');
      }
    }

    String? ssid = source?.ssid ?? _lastWifiSsid;
    String password = source?.password ?? _lastWifiPassword ?? '';
    if (ssid == null || ssid.trim().isEmpty) {
      _appendLog('wifi_join: missing ssid');
      return false;
    }
    _lastWifiSsid = ssid.trim();
    _lastWifiPassword = password;
    final joinResult = await _repository.joinCameraWifi(
      ssid: ssid.trim(),
      password: password,
      joinOnce: false,
    );
    var ok = false;
    joinResult.fold(
      (error) => _appendLog('wifi_join: ${error.message}'),
      (_) => ok = true,
    );
    if (ok) {
      _wifiJoined = true;
      _appendLog('wifi_join: ok');
    }
    return ok;
  }

  Future<_WifiInfoSnapshot?> _fetchWifiInfoWithRetry() async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      if (!_isBluetoothConnected) {
        _appendLog('wifi_info: bluetooth not connected');
        return null;
      }
      final infoResult = await _repository.getWifiInfo();
      _WifiInfoSnapshot? snapshot;
      infoResult.fold(
        (error) => _appendLog('wifi_info: ${error.message}'),
        (data) {
          final ssid = data['ssid']?.toString() ?? '';
          final password = data['password']?.toString() ?? '';
          final state = data['state'] as int? ?? 0;
          final isBusy = data['isBusy'] == true;
          _appendLog('wifi_info: state=$state busy=$isBusy ssid=$ssid');
          if (ssid.isNotEmpty) {
            snapshot = _WifiInfoSnapshot(ssid: ssid, password: password);
          }
        },
      );
      if (snapshot != null) {
        return snapshot;
      }
      await Future.delayed(const Duration(milliseconds: 800));
    }
    return null;
  }

  Future<void> _cacheWifiCredentials(String ssid, String password) async {
    try {
      await _wifiStore.save(ssid: ssid, password: password);
    } catch (error) {
      _appendLog('wifi_cache: save failed ($error)');
    }
  }

  Future<_WifiInfoSnapshot?> _loadCachedWifiCredentials() async {
    try {
      final cached = await _wifiStore.read();
      if (cached == null) {
        _appendLog('wifi_cache: empty');
        return null;
      }
      return _WifiInfoSnapshot(ssid: cached.ssid, password: cached.password);
    } catch (error) {
      _appendLog('wifi_cache: read failed ($error)');
      return null;
    }
  }

  Future<void> _connectWifiOnce() async {
    final inFlight = _connectWifiTask;
    if (inFlight != null) {
      _appendLog('connect_wifi: awaiting in-flight');
      return await inFlight;
    }
    final task = _logResult('connect_wifi', _repository.connectWifi);
    _connectWifiTask = task;
    try {
      await task;
    } finally {
      _connectWifiTask = null;
    }
  }

  Future<bool> _openWifiWithRetry({required int channel}) async {
    final inFlight = _wifiOpenTask;
    if (inFlight != null) {
      _appendLog('wifi_open: awaiting in-flight');
      return await inFlight;
    }
    final task = _openWifiWithRetryInternal(channel: channel);
    _wifiOpenTask = task;
    try {
      return await task;
    } finally {
      _wifiOpenTask = null;
    }
  }

  Future<bool> _openWifiWithRetryInternal({required int channel}) async {
    if (!_isBluetoothConnected) {
      _appendLog('wifi_open: bluetooth not connected');
      return false;
    }
    const maxAttempts = 3;
    var channelToUse = channel;
    var triedFallbackChannel = false;

    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      if (attempt > 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
      final result = await _repository.openWifi(channel: channelToUse);
      if (result.isRight()) {
        _appendLog('wifi_open: ok');
        return true;
      }
      var message = '';
      result.fold(
        (error) {
          message = error.message.toLowerCase();
          _appendLog('wifi_open: ${error.message}');
        },
        (_) {},
      );
      if (_isWifiOpenAlready(message)) {
        _appendLog('wifi_open: already open');
        return true;
      }
      if (message.contains('error 444')) {
        _appendLog('wifi_open: camera busy, retrying');
        continue;
      }

      final wifiState = await _checkWifiState();
      if (wifiState == _WifiOpenState.open) {
        _appendLog('wifi_open: confirmed open via wifi_info');
        return true;
      }
      if (wifiState == _WifiOpenState.busy) {
        _appendLog('wifi_open: wifi busy, waiting');
        continue;
      }

      if (!triedFallbackChannel && channelToUse == 0) {
        final fallback = await _pickFallbackChannel();
        if (fallback != null && fallback > 0) {
          triedFallbackChannel = true;
          channelToUse = fallback;
          _appendLog('wifi_open: retry with channel $channelToUse');
          continue;
        }
      }

      if (message.contains('timeout') || message.contains('bluetooth_not_connected')) {
        await _logResult('wifi_reset', () => _repository.resetWifi(channel: channelToUse));
        continue;
      }
      return false;
    }
    return false;
  }

  Future<_WifiOpenState> _checkWifiState() async {
    final infoResult = await _repository.getWifiInfo();
    var state = _WifiOpenState.unknown;
    infoResult.fold(
      (error) => _appendLog('wifi_info: ${error.message}'),
      (data) {
        final rawState = data['state'] as int? ?? 0;
        final isBusy = data['isBusy'] == true;
        _appendLog('wifi_info: state=$rawState busy=$isBusy');
        if (isBusy) {
          state = _WifiOpenState.busy;
          return;
        }
        if (rawState == 1 || rawState == 2) {
          state = _WifiOpenState.open;
        } else if (rawState == 3) {
          state = _WifiOpenState.closed;
        }
      },
    );
    return state;
  }

  Future<int?> _pickFallbackChannel() async {
    if (!_isBluetoothConnected) {
      _appendLog('wifi_channel_list: bluetooth not connected');
      return null;
    }
    final listResult = await _repository.getWifiChannelList();
    int? selected;
    listResult.fold(
      (error) => _appendLog('wifi_channel_list: ${error.message}'),
      (data) {
        final list24Raw = data['channelList24g'] as List<dynamic>? ?? const [];
        final list5Raw = data['channelList5g'] as List<dynamic>? ?? const [];
        final list24 = list24Raw.map((value) => (value as num).toInt()).toList();
        final list5 = list5Raw.map((value) => (value as num).toInt()).toList();
        if (list24.isNotEmpty) {
          selected = list24.first;
          return;
        }
        if (list5.isNotEmpty) {
          selected = list5.first;
          return;
        }
      },
    );
    if (selected == null) {
      await _logResult(
        'wifi_country_code',
        () => _repository.setWifiCountryCode(_defaultWifiCountryCode),
      );
      final retryResult = await _repository.getWifiChannelList();
      retryResult.fold(
        (error) => _appendLog('wifi_channel_list: ${error.message}'),
        (data) {
          final list24Raw = data['channelList24g'] as List<dynamic>? ?? const [];
          final list5Raw = data['channelList5g'] as List<dynamic>? ?? const [];
          final list24 =
              list24Raw.map((value) => (value as num).toInt()).toList();
          final list5 =
              list5Raw.map((value) => (value as num).toInt()).toList();
          if (list24.isNotEmpty) {
            selected = list24.first;
            return;
          }
          if (list5.isNotEmpty) {
            selected = list5.first;
          }
        },
      );
    }
    return selected;
  }

  bool _isWifiOpenAlready(String message) {
    return message.contains('already') ||
        message.contains('opened') ||
        message.contains('open') && message.contains('busy');
  }
}

enum _WifiOpenState {
  unknown,
  busy,
  open,
  closed,
}

class _WifiInfoSnapshot {
  const _WifiInfoSnapshot({required this.ssid, required this.password});

  final String ssid;
  final String password;
}
