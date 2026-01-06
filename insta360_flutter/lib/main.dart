import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insta360_sdk/insta360_sdk.dart';

void main() {
  runApp(const Insta360App());
}

class Insta360App extends StatelessWidget {
  const Insta360App({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0C8B7D),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Insta360 Connect',
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.spaceGroteskTextTheme(baseTheme.textTheme),
        scaffoldBackgroundColor: const Color(0xFFF6F3EE),
        cardTheme: CardThemeData(
          color: const Color(0xFFFDFBF7),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE4DED5)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1EEE8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0DAD0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0DAD0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const Insta360Home(),
    );
  }
}

class BluetoothDeviceInfo {
  const BluetoothDeviceInfo({
    required this.identifier,
    required this.name,
    required this.rssi,
  });

  final String identifier;
  final String name;
  final int rssi;
}

class WifiScanEntry {
  const WifiScanEntry({
    required this.ssid,
    required this.bssid,
    required this.frequency,
    required this.signalLevel,
    required this.flags,
  });

  final String ssid;
  final String bssid;
  final int frequency;
  final int signalLevel;
  final String flags;
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class Insta360Home extends StatefulWidget {
  const Insta360Home({super.key});

  @override
  State<Insta360Home> createState() => _Insta360HomeState();
}

class _Insta360HomeState extends State<Insta360Home> {
  final Insta360Sdk _sdk = Insta360Sdk.instance;
  final List<String> _eventLog = <String>[];
  final Map<String, BluetoothDeviceInfo> _bluetoothDevices =
      <String, BluetoothDeviceInfo>{};
  final List<WifiScanEntry> _wifiScanList = <WifiScanEntry>[];
  final TextEditingController _wifiChannelController =
      TextEditingController(text: '0');
  final TextEditingController _countryCodeController =
      TextEditingController(text: 'US');
  final TextEditingController _wifiSsidController = TextEditingController();
  final TextEditingController _wifiBssidController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  final TextEditingController _wifiScanIntervalController =
      TextEditingController(text: '1');
  final TextEditingController _wifiScanCountController =
      TextEditingController(text: '3');
  final TextEditingController _mediaStartController =
      TextEditingController(text: '0');
  final TextEditingController _mediaLimitController =
      TextEditingController(text: '200');
  String? _connectedBluetoothId;
  bool _isScanning = false;
  bool _wifiProvisioningEnabled = false;
  String? _wifiConnectionStatus;
  bool _isLoadingMedia = false;
  String? _selectedPhotoUri;
  Uint8List? _selectedPhotoBytes;
  final List<String> _selectedVideoUris = <String>[];
  final List<Map<String, Object?>> _photoList = <Map<String, Object?>>[];
  final List<Map<String, Object?>> _videoList = <Map<String, Object?>>[];
  final Map<String, double> _downloadProgress = <String, double>{};
  double? _exportProgress;
  String? _exportStatus;
  StreamSubscription<Insta360Event>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _sdk.events.listen(_handleEvent, onError: (error) {
      _log('events: $error');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _wifiChannelController.dispose();
    _countryCodeController.dispose();
    _wifiSsidController.dispose();
    _wifiBssidController.dispose();
    _wifiPasswordController.dispose();
    _wifiScanIntervalController.dispose();
    _wifiScanCountController.dispose();
    _mediaStartController.dispose();
    _mediaLimitController.dispose();
    super.dispose();
  }

  void _handleEvent(Insta360Event event) {
    if (event.type == 'bluetooth_scan_started') {
      setState(() {
        _isScanning = true;
        _log('bluetooth_scan_started', insideSetState: true);
      });
      return;
    }
    if (event.type == 'bluetooth_scan_stopped') {
      setState(() {
        _isScanning = false;
        _log('bluetooth_scan_stopped', insideSetState: true);
      });
      return;
    }
    if (event.type == 'bluetooth_device_found') {
      final identifier = event.payload['identifier'] as String?;
      final name = event.payload['name'] as String? ?? 'unknown';
      final rssi = event.payload['rssi'] as int? ?? 0;
      if (identifier != null) {
        setState(() {
          _bluetoothDevices[identifier] = BluetoothDeviceInfo(
            identifier: identifier,
            name: name,
            rssi: rssi,
          );
          _log(
            'bluetooth_device_found: $name ($identifier) rssi=$rssi',
            insideSetState: true,
          );
        });
      } else {
        _log('bluetooth_device_found: missing identifier');
      }
      return;
    }
    if (event.type == 'bluetooth_connected') {
      final identifier = event.payload['identifier'] as String?;
      final name = event.payload['name'] as String? ?? 'unknown';
      setState(() {
        _connectedBluetoothId = identifier;
        _log(
          'bluetooth_connected: $name ${identifier ?? ''}'.trim(),
          insideSetState: true,
        );
      });
      return;
    }
    if (event.type == 'bluetooth_disconnected') {
      final identifier = event.payload['identifier'] as String?;
      final error = event.payload['error'] as String?;
      setState(() {
        if (_connectedBluetoothId == identifier) {
          _connectedBluetoothId = null;
        }
        _log(
          'bluetooth_disconnected: ${identifier ?? 'unknown'}'
          '${error != null ? ' ($error)' : ''}',
          insideSetState: true,
        );
      });
      return;
    }
    if (event.type == 'bluetooth_connect_failed') {
      final identifier = event.payload['identifier'] as String?;
      final error = event.payload['error'] as String?;
      _log(
        'bluetooth_connect_failed: ${identifier ?? 'unknown'}'
        '${error != null ? ' ($error)' : ''}',
      );
      return;
    }
    if (event.type == 'wifi_scan_list') {
      final list = event.payload['list'] as List<dynamic>? ?? <dynamic>[];
      final entries = list.map((item) {
        final map = Map<String, Object?>.from(item as Map);
        return WifiScanEntry(
          ssid: map['ssid'] as String? ?? '',
          bssid: map['bssid'] as String? ?? '',
          frequency: map['frequency'] as int? ?? 0,
          signalLevel: map['signalLevel'] as int? ?? 0,
          flags: map['flags'] as String? ?? '',
        );
      }).toList();
      setState(() {
        _wifiScanList
          ..clear()
          ..addAll(entries);
        _log('wifi_scan_list: ${entries.length} networks',
            insideSetState: true);
      });
      return;
    }
    if (event.type == 'wifi_connection_result') {
      final result = Map<String, Object?>.from(
        event.payload['result'] as Map,
      );
      final code = result['code'];
      final ssid = result['ssid'];
      setState(() {
        _wifiConnectionStatus = 'code=$code ssid=$ssid';
        _log('wifi_connection_result: $_wifiConnectionStatus',
            insideSetState: true);
      });
      return;
    }
    if (event.type == 'download_progress') {
      final uri = event.payload['uri'] as String?;
      final progress = (event.payload['progress'] as num?)?.toDouble();
      if (uri != null && progress != null) {
        setState(() {
          _downloadProgress[uri] = progress;
        });
      }
      return;
    }
    if (event.type == 'download_complete') {
      final uri = event.payload['uri'] as String?;
      final path = event.payload['path'] as String?;
      setState(() {
        if (uri != null) {
          _downloadProgress[uri] = 1.0;
        }
        _log(
          'download_complete: ${uri ?? 'unknown'} ${path ?? ''}'.trim(),
          insideSetState: true,
        );
      });
      return;
    }
    if (event.type == 'download_failed') {
      final uri = event.payload['uri'] as String?;
      final error = event.payload['error'] as String?;
      _log(
        'download_failed: ${uri ?? 'unknown'}'
        '${error != null ? ' ($error)' : ''}',
      );
      return;
    }
    if (event.type == 'export_progress') {
      final progress = (event.payload['progress'] as num?)?.toDouble();
      if (progress != null) {
        setState(() {
          _exportProgress = progress;
          _exportStatus = 'export ${(_exportProgress! * 100).round()}%';
        });
      }
      return;
    }
    if (event.type == 'export_complete') {
      final path = event.payload['outputPath'] as String?;
      setState(() {
        _exportProgress = 1.0;
        _exportStatus = 'export complete';
        _log(
          'export_complete: ${path ?? ''}'.trim(),
          insideSetState: true,
        );
      });
      return;
    }
    if (event.type == 'export_failed') {
      final error = event.payload['error'] as String?;
      setState(() {
        _exportProgress = null;
        _exportStatus = 'export failed';
        _log('export_failed: ${error ?? ''}', insideSetState: true);
      });
      return;
    }
    if (event.type == 'camera_state') {
      final source = event.payload['source'];
      final stateName = event.payload['stateName'];
      _log('camera_state: $source -> $stateName');
      return;
    }
    if (event.type == 'notification') {
      final name = event.payload['name'];
      _log('notification: $name');
      return;
    }
    _log('event: ${event.type} ${event.payload}');
  }

  void _log(String message, {bool insideSetState = false}) {
    void apply() {
      _eventLog.insert(0, '${DateTime.now().toIso8601String()} $message');
      if (_eventLog.length > 200) {
        _eventLog.removeLast();
      }
    }

    if (insideSetState) {
      apply();
    } else {
      setState(apply);
    }
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    try {
      await action();
      _log('$label: ok');
    } catch (error) {
      _log('$label: $error');
    }
  }

  Future<void> _runWithResult<T>(String label, Future<T> Function() action) async {
    try {
      final value = await action();
      _log('$label: $value');
    } catch (error) {
      _log('$label: $error');
    }
  }

  Future<void> _fetchCameraState() async {
    try {
      final state = await _sdk.getCameraState();
      _log('camera_state_snapshot: $state');
    } catch (error) {
      _log('camera_state_snapshot: $error');
    }
  }

  int _parseChannel() {
    final raw = _wifiChannelController.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      _log('invalid channel: $raw');
      return 0;
    }
    return parsed;
  }

  int _parseScanInterval() {
    final raw = _wifiScanIntervalController.text.trim();
    return int.tryParse(raw) ?? 1;
  }

  int _parseScanCount() {
    final raw = _wifiScanCountController.text.trim();
    return int.tryParse(raw) ?? 3;
  }

  Future<void> _getWifiInfo() async {
    try {
      final info = await _sdk.getWifiInfo();
      _log('wifi_info: $info');
    } catch (error) {
      _log('wifi_info: $error');
    }
  }

  Future<void> _getWifiChannelList() async {
    try {
      final info = await _sdk.getWifiChannelList();
      _log('wifi_channel_list: $info');
    } catch (error) {
      _log('wifi_channel_list: $error');
    }
  }

  Future<void> _openWifi() async {
    await _sdk.openCameraWifi(channel: _parseChannel());
  }

  Future<void> _closeWifi() async {
    await _sdk.closeCameraWifi();
  }

  Future<void> _resetWifi() async {
    await _sdk.resetCameraWifi(channel: _parseChannel());
  }

  Future<void> _setWifiCountryCode() async {
    final code = _countryCodeController.text.trim();
    if (code.isEmpty) {
      _log('country code required');
      return;
    }
    await _sdk.setWifiCountryCode(code);
  }

  Future<void> _setWifiProvisioning(bool enabled) async {
    await _sdk.setWifiProvisioningEnabled(enabled);
    setState(() {
      _wifiProvisioningEnabled = enabled;
    });
  }

  Future<void> _startWifiScan() async {
    await _sdk.startWifiScan(
      interval: _parseScanInterval(),
      count: _parseScanCount(),
    );
  }

  Future<void> _connectToWifi() async {
    final ssid = _wifiSsidController.text.trim();
    final password = _wifiPasswordController.text;
    final bssid = _wifiBssidController.text.trim();
    if (ssid.isEmpty) {
      _log('ssid required');
      return;
    }
    if (password.isEmpty) {
      _log('password required');
      return;
    }
    await _sdk.connectToWifi(
      ssid: ssid,
      password: password,
      bssid: bssid.isEmpty ? null : bssid,
    );
  }

  Future<void> _getConnectedWifiList() async {
    try {
      final info = await _sdk.getConnectedWifiList();
      _log('wifi_connect_list: $info');
    } catch (error) {
      _log('wifi_connect_list: $error');
    }
  }

  int _parseMediaStart() {
    final raw = _mediaStartController.text.trim();
    return int.tryParse(raw) ?? 0;
  }

  int _parseMediaLimit() {
    final raw = _mediaLimitController.text.trim();
    return int.tryParse(raw) ?? 200;
  }

  Future<void> _refreshMedia() async {
    setState(() {
      _isLoadingMedia = true;
    });
    try {
      final result = await _sdk.listMedia(
        start: _parseMediaStart(),
        limit: _parseMediaLimit(),
      );
      final photos = (result['photos'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => Map<String, Object?>.from(item as Map))
          .toList();
      final videos = (result['videos'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => Map<String, Object?>.from(item as Map))
          .toList();
      setState(() {
        _photoList
          ..clear()
          ..addAll(photos);
        _videoList
          ..clear()
          ..addAll(videos);
      });
      _log('media_list: photos=${photos.length} videos=${videos.length}');
    } catch (error) {
      _log('media_list: $error');
    } finally {
      setState(() {
        _isLoadingMedia = false;
      });
    }
  }

  Future<void> _selectPhoto(String uri) async {
    setState(() {
      _selectedPhotoUri = uri;
      _selectedPhotoBytes = null;
    });
    try {
      final bytes = await _sdk.fetchPhoto(uri);
      setState(() {
        _selectedPhotoBytes = bytes;
      });
    } catch (error) {
      _log('fetch_photo: $error');
    }
  }

  void _toggleVideoSelection(String uri) {
    setState(() {
      if (_selectedVideoUris.contains(uri)) {
        _selectedVideoUris.remove(uri);
      } else {
        if (_selectedVideoUris.length >= 2) {
          _selectedVideoUris.removeAt(0);
        }
        _selectedVideoUris.add(uri);
      }
    });
  }

  Future<void> _loadPlaybackSources() async {
    if (_selectedVideoUris.isEmpty) {
      _log('select a video to play');
      return;
    }
    await _sdk.setPlaybackSources(List<String>.from(_selectedVideoUris));
  }

  Future<void> _downloadMedia(String uri) async {
    await _runWithResult('download', () => _sdk.downloadResource(uri));
  }

  Future<void> _exportSelectedVideo() async {
    if (_selectedVideoUris.isEmpty) {
      _log('select a video to export');
      return;
    }
    setState(() {
      _exportProgress = 0;
      _exportStatus = 'export started';
    });
    await _runWithResult(
      'export_video',
      () => _sdk.exportVideo(uris: List<String>.from(_selectedVideoUris)),
    );
  }

  Future<void> _exportSelectedPhoto() async {
    final uri = _selectedPhotoUri;
    if (uri == null || uri.isEmpty) {
      _log('select a photo to export');
      return;
    }
    setState(() {
      _exportProgress = 0;
      _exportStatus = 'export started';
    });
    await _runWithResult('export_image', () => _sdk.exportImage(uri: uri));
  }

  String _formatFileSize(Object? value) {
    final bytes = value is num ? value.toInt() : null;
    if (bytes == null) {
      return '';
    }
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  Widget _buildBluetoothSection(TextTheme textTheme) {
    final devices = _bluetoothDevices.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Bluetooth Devices',
        trailing: _isScanning
            ? const StatusPill(label: 'Scanning', color: Color(0xFF0C8B7D))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (devices.isEmpty)
              Text(
                'No devices found yet.',
                style: textTheme.bodySmall,
              )
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isConnected =
                        device.identifier == _connectedBluetoothId;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(device.name),
                      subtitle: Text('RSSI ${device.rssi}'),
                      trailing: FilledButton.tonal(
                        onPressed: isConnected
                            ? () => _run(
                                  'bluetooth_disconnect',
                                  _sdk.disconnectBluetoothDevice,
                                )
                            : () => _run(
                                  'bluetooth_connect',
                                  () => _sdk.connectBluetoothDevice(
                                    device.identifier,
                                  ),
                                ),
                        child: Text(isConnected ? 'Disconnect' : 'Connect'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiSection(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Wi-Fi (Bluetooth)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _countryCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Country Code',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _wifiChannelController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Channel',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _run('wifi_open', _openWifi),
                  child: const Text('Open Wi-Fi'),
                ),
                FilledButton.tonal(
                  onPressed: () => _run('wifi_close', _closeWifi),
                  child: const Text('Close Wi-Fi'),
                ),
                FilledButton.tonal(
                  onPressed: () => _run('wifi_reset', _resetWifi),
                  child: const Text('Reset Wi-Fi'),
                ),
                OutlinedButton(
                  onPressed: () => _run('wifi_info', _getWifiInfo),
                  child: const Text('Get Wi-Fi Info'),
                ),
                OutlinedButton(
                  onPressed: () => _run('wifi_channels', _getWifiChannelList),
                  child: const Text('Get Channels'),
                ),
                OutlinedButton(
                  onPressed: () => _run('wifi_country', _setWifiCountryCode),
                  child: const Text('Set Country Code'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiProvisioningSection(TextTheme textTheme) {
    final list = _wifiScanList;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Camera Wi-Fi Provisioning',
        trailing: StatusPill(
          label: _wifiProvisioningEnabled ? 'Enabled' : 'Disabled',
          color: _wifiProvisioningEnabled
              ? const Color(0xFF0C8B7D)
              : const Color(0xFF6B6B6B),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _run(
                    'wifi_provision_enable',
                    () => _setWifiProvisioning(true),
                  ),
                  child: const Text('Enable Provisioning'),
                ),
                FilledButton.tonal(
                  onPressed: () => _run(
                    'wifi_provision_disable',
                    () => _setWifiProvisioning(false),
                  ),
                  child: const Text('Disable Provisioning'),
                ),
                OutlinedButton(
                  onPressed: () => _run('wifi_scan', _startWifiScan),
                  child: const Text('Start Scan'),
                ),
                OutlinedButton(
                  onPressed: () => _run(
                    'wifi_connect_list',
                    _getConnectedWifiList,
                  ),
                  child: const Text('Get Connected List'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wifiScanIntervalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Scan Interval (s)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _wifiScanCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Scan Count',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wifiSsidController,
                    decoration: const InputDecoration(
                      labelText: 'SSID',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _wifiBssidController,
                    decoration: const InputDecoration(
                      labelText: 'BSSID (optional)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wifiPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Wi-Fi Password',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _run('wifi_connect', _connectToWifi),
                  child: const Text('Connect'),
                ),
              ],
            ),
            if (_wifiConnectionStatus != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last result: $_wifiConnectionStatus',
                style: textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            if (list.isEmpty)
              Text('No scan results yet.', style: textTheme.bodySmall)
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = list[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.ssid.isEmpty ? '(hidden)' : entry.ssid),
                      subtitle: Text(
                        'RSSI ${entry.signalLevel}  ${entry.frequency}MHz',
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            _wifiSsidController.text = entry.ssid;
                            _wifiBssidController.text = entry.bssid;
                          });
                        },
                        child: const Text('Use'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(TextTheme textTheme) {
    final photoPreview = _selectedPhotoBytes;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Media Library',
        trailing: _isLoadingMedia
            ? const StatusPill(label: 'Loading', color: Color(0xFF0C8B7D))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mediaStartController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Start',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _mediaLimitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Limit',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _isLoadingMedia ? null : _refreshMedia,
                  child: Text(_isLoadingMedia ? 'Loading...' : 'Refresh Media'),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _photoList.clear();
                      _videoList.clear();
                      _selectedPhotoBytes = null;
                      _selectedPhotoUri = null;
                      _selectedVideoUris.clear();
                      _downloadProgress.clear();
                      _exportProgress = null;
                      _exportStatus = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            if (photoPreview != null) ...[
              const SizedBox(height: 12),
              Text('Selected Photo', style: textTheme.bodySmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Image.memory(photoPreview, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text('Photos (${_photoList.length})', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            if (_photoList.isEmpty)
              Text('No photos loaded.', style: textTheme.bodySmall)
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  itemCount: _photoList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _photoList[index];
                    final uri = item['uri'] as String? ?? '';
                    final isSelected = uri == _selectedPhotoUri;
                    final progress = _downloadProgress[uri];
                    final subtitle = <String>[];
                    if (progress != null && progress < 1) {
                      subtitle.add('download ${(progress * 100).round()}%');
                    }
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(uri, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: subtitle.isEmpty
                          ? null
                          : Text(subtitle.join(' • ')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.tonal(
                            onPressed:
                                uri.isEmpty ? null : () => _selectPhoto(uri),
                            child: Text(isSelected ? 'Viewing' : 'View'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed:
                                uri.isEmpty ? null : () => _downloadMedia(uri),
                            child: const Text('Download'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Text('Videos (${_videoList.length})', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            if (_videoList.isEmpty)
              Text('No videos loaded.', style: textTheme.bodySmall)
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  itemCount: _videoList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _videoList[index];
                    final uri = item['uri'] as String? ?? '';
                    final isSelected = _selectedVideoUris.contains(uri);
                    final sizeLabel = _formatFileSize(item['fileSize']);
                    final progress = _downloadProgress[uri];
                    final subtitle = <String>[];
                    if (sizeLabel.isNotEmpty) {
                      subtitle.add(sizeLabel);
                    }
                    final totalTime = item['totalTime'];
                    if (totalTime != null) {
                      subtitle.add('time $totalTime');
                    }
                    if (progress != null && progress < 1) {
                      subtitle.add('download ${(progress * 100).round()}%');
                    }
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(uri, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: subtitle.isEmpty
                          ? null
                          : Text(subtitle.join(' • ')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.tonal(
                            onPressed: uri.isEmpty
                                ? null
                                : () => _toggleVideoSelection(uri),
                            child: Text(isSelected ? 'Selected' : 'Select'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed:
                                uri.isEmpty ? null : () => _downloadMedia(uri),
                            child: const Text('Download'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            if (_selectedVideoUris.isNotEmpty)
              Text(
                'Selected videos: ${_selectedVideoUris.join(', ')}',
                style: textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            Text('Playback', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Insta360Player(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed:
                      _selectedVideoUris.isEmpty ? null : _loadPlaybackSources,
                  child: const Text('Load Player'),
                ),
                FilledButton.tonal(
                  onPressed: () => _run('playback_play', _sdk.playbackPlay),
                  child: const Text('Play'),
                ),
                FilledButton.tonal(
                  onPressed: () => _run('playback_pause', _sdk.playbackPause),
                  child: const Text('Pause'),
                ),
                OutlinedButton(
                  onPressed: () => _run('playback_stop', _sdk.playbackStop),
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Export', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed:
                      _selectedVideoUris.isEmpty ? null : _exportSelectedVideo,
                  child: const Text('Export Video'),
                ),
                FilledButton.tonal(
                  onPressed:
                      _selectedPhotoUri == null ? null : _exportSelectedPhoto,
                  child: const Text('Export Photo'),
                ),
              ],
            ),
            if (_exportProgress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _exportProgress),
            ],
            if (_exportStatus != null) ...[
              const SizedBox(height: 4),
              Text(_exportStatus!, style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    final hasBluetooth = _connectedBluetoothId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insta360 Connect',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Control cameras, monitor media, and export quickly.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: hasBluetooth ? 'BT connected' : 'BT idle',
                color: hasBluetooth
                    ? const Color(0xFF0C8B7D)
                    : const Color(0xFF6B6B6B),
              ),
              StatusPill(
                label: _wifiProvisioningEnabled
                    ? 'Provisioning on'
                    : 'Provisioning off',
                color: _wifiProvisioningEnabled
                    ? const Color(0xFF0C8B7D)
                    : const Color(0xFF6B6B6B),
              ),
              if (_exportProgress != null)
                StatusPill(
                  label: _exportStatus ?? 'Exporting',
                  color: const Color(0xFFCF6F2B),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Live Preview',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 220,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Insta360Preview(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _run('start_preview', _sdk.startPreview),
                  child: const Text('Start Preview'),
                ),
                FilledButton.tonal(
                  onPressed: () => _run('stop_preview', _sdk.stopPreview),
                  child: const Text('Stop Preview'),
                ),
                OutlinedButton(
                  onPressed: () => _run('take_picture', _sdk.takePicture),
                  child: const Text('Take Picture'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionControls(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Session Controls',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connection', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _run('initialize', _sdk.initialize),
                  child: const Text('Initialize SDK'),
                ),
                FilledButton.tonal(
                  onPressed: () => _run('connect_wifi', _sdk.connectWifi),
                  child: const Text('Connect Wi-Fi'),
                ),
                OutlinedButton(
                  onPressed: () => _run('disconnect_wifi', _sdk.disconnectWifi),
                  child: const Text('Disconnect Wi-Fi'),
                ),
                FilledButton.tonal(
                  onPressed: () => _run('connect_usb', _sdk.connectUsb),
                  child: const Text('Connect USB'),
                ),
                OutlinedButton(
                  onPressed: () => _run('disconnect_usb', _sdk.disconnectUsb),
                  child: const Text('Disconnect USB'),
                ),
                FilledButton.tonal(
                  onPressed: () => _run('connect_external', _sdk.connectExternal),
                  child: const Text('Connect External'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _run('disconnect_external', _sdk.disconnectExternal),
                  child: const Text('Disconnect External'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Capture', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _run('start_capture', _sdk.startCapture),
                  child: const Text('Start Capture'),
                ),
                FilledButton.tonal(
                  onPressed: () => _run('stop_capture', _sdk.stopCapture),
                  child: const Text('Stop Capture'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Bluetooth', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _bluetoothDevices.clear();
                    });
                    _run('bluetooth_scan_start', _sdk.startBluetoothScan);
                  },
                  child: const Text('Start BT Scan'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _run('bluetooth_scan_stop', _sdk.stopBluetoothScan),
                  child: const Text('Stop BT Scan'),
                ),
                OutlinedButton(
                  onPressed: _fetchCameraState,
                  child: const Text('Get Camera State'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLog(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Activity Log',
        trailing: Text(
          '${_eventLog.length} events',
          style: textTheme.bodySmall,
        ),
        child: SizedBox(
          height: 200,
          child: _eventLog.isEmpty
              ? Center(
                  child: Text(
                    'No events yet.',
                    style: textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _eventLog.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _eventLog[index],
                        style: textTheme.bodySmall,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF6F3EE),
                    const Color(0xFFE7F3F0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -60,
            top: 80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB7E4DA).withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            left: -80,
            top: 360,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2C9A1).withOpacity(0.35),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(textTheme)),
                SliverToBoxAdapter(child: _buildPreviewSection(textTheme)),
                SliverToBoxAdapter(child: _buildSessionControls(textTheme)),
                SliverToBoxAdapter(child: _buildBluetoothSection(textTheme)),
                SliverToBoxAdapter(child: _buildWifiSection(textTheme)),
                SliverToBoxAdapter(child: _buildWifiProvisioningSection(textTheme)),
                SliverToBoxAdapter(child: _buildMediaSection(textTheme)),
                SliverToBoxAdapter(child: _buildEventLog(textTheme)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
