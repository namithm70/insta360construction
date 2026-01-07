import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insta360_sdk/insta360_sdk.dart';

import '../../../auth/presentation/pages/profile_page.dart';
import '../bloc/insta360_bloc.dart';
import '../bloc/insta360_event.dart';
import '../bloc/insta360_state.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';

class Insta360Home extends StatefulWidget {
  const Insta360Home({super.key});

  @override
  State<Insta360Home> createState() => _Insta360HomeState();
}

class _Insta360HomeState extends State<Insta360Home> {
  int _tabIndex = 0;
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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

  void _logClient(String message) {
    context.read<Insta360Bloc>().add(ClientLogRequested(message));
  }

  int _parseChannel() {
    final raw = _wifiChannelController.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      _logClient('invalid channel: $raw');
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

  void _getWifiInfo() {
    context.read<Insta360Bloc>().add(GetWifiInfoRequested());
  }

  void _getWifiChannelList() {
    context.read<Insta360Bloc>().add(GetWifiChannelListRequested());
  }

  void _openWifi() {
    context.read<Insta360Bloc>().add(OpenWifiRequested(_parseChannel()));
  }

  void _closeWifi() {
    context.read<Insta360Bloc>().add(CloseWifiRequested());
  }

  void _resetWifi() {
    context.read<Insta360Bloc>().add(ResetWifiRequested(_parseChannel()));
  }

  void _setWifiCountryCode() {
    final code = _countryCodeController.text.trim();
    if (code.isEmpty) {
      _logClient('country code required');
      return;
    }
    context.read<Insta360Bloc>().add(SetWifiCountryCodeRequested(code));
  }

  void _setWifiProvisioning(bool enabled) {
    context.read<Insta360Bloc>().add(SetWifiProvisioningRequested(enabled));
  }

  void _startWifiScan() {
    context.read<Insta360Bloc>().add(StartWifiScanRequested(
          interval: _parseScanInterval(),
          count: _parseScanCount(),
        ));
  }

  void _connectToWifi() {
    final ssid = _wifiSsidController.text.trim();
    final password = _wifiPasswordController.text;
    final bssid = _wifiBssidController.text.trim();
    if (ssid.isEmpty) {
      _logClient('ssid required');
      return;
    }
    if (password.isEmpty) {
      _logClient('password required');
      return;
    }
    context.read<Insta360Bloc>().add(
          ConnectWifiRequested(
            ssid: ssid,
            password: password,
            bssid: bssid.isEmpty ? null : bssid,
          ),
        );
  }

  void _getConnectedWifiList() {
    context.read<Insta360Bloc>().add(GetConnectedWifiListRequested());
  }

  int _parseMediaStart() {
    final raw = _mediaStartController.text.trim();
    return int.tryParse(raw) ?? 0;
  }

  int _parseMediaLimit() {
    final raw = _mediaLimitController.text.trim();
    return int.tryParse(raw) ?? 200;
  }

  void _refreshMedia() {
    context.read<Insta360Bloc>().add(
          FetchMediaRequested(
            start: _parseMediaStart(),
            limit: _parseMediaLimit(),
          ),
        );
  }

  void _selectPhoto(String uri) {
    context.read<Insta360Bloc>().add(SelectPhotoRequested(uri));
  }

  void _toggleVideoSelection(String uri) {
    context.read<Insta360Bloc>().add(ToggleVideoSelectionRequested(uri));
  }

  void _loadPlaybackSources() {
    context.read<Insta360Bloc>().add(LoadPlaybackSourcesRequested());
  }

  void _downloadMedia(String uri) {
    context.read<Insta360Bloc>().add(DownloadMediaRequested(uri));
  }

  void _exportSelectedVideo() {
    context.read<Insta360Bloc>().add(ExportVideoRequested());
  }

  void _exportSelectedPhoto(String uri) {
    context.read<Insta360Bloc>().add(ExportPhotoRequested(uri));
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

  Widget _buildBluetoothSection(TextTheme textTheme, Insta360State state) {
    final devices = state.bluetoothDevices.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Bluetooth Devices',
        trailing: state.isScanning
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
                        device.identifier == state.connectedBluetoothId;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(device.name),
                      subtitle: Text('RSSI ${device.rssi}'),
                      trailing: FilledButton.tonal(
                        onPressed: isConnected
                            ? () => context
                                .read<Insta360Bloc>()
                                .add(DisconnectBluetoothRequested())
                            : () => context
                                .read<Insta360Bloc>()
                                .add(ConnectBluetoothRequested(
                                  device.identifier,
                                )),
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

  Widget _buildWifiSection() {
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
                  onPressed: _openWifi,
                  child: const Text('Open Wi-Fi'),
                ),
                FilledButton.tonal(
                  onPressed: _closeWifi,
                  child: const Text('Close Wi-Fi'),
                ),
                FilledButton.tonal(
                  onPressed: _resetWifi,
                  child: const Text('Reset Wi-Fi'),
                ),
                OutlinedButton(
                  onPressed: _getWifiInfo,
                  child: const Text('Get Wi-Fi Info'),
                ),
                OutlinedButton(
                  onPressed: _getWifiChannelList,
                  child: const Text('Get Channels'),
                ),
                OutlinedButton(
                  onPressed: _setWifiCountryCode,
                  child: const Text('Set Country Code'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiProvisioningSection(TextTheme textTheme, Insta360State state) {
    final list = state.wifiScanList;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Camera Wi-Fi Provisioning',
        trailing: StatusPill(
          label: state.wifiProvisioningEnabled ? 'Enabled' : 'Disabled',
          color: state.wifiProvisioningEnabled
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
                  onPressed: () => _setWifiProvisioning(true),
                  child: const Text('Enable Provisioning'),
                ),
                FilledButton.tonal(
                  onPressed: () => _setWifiProvisioning(false),
                  child: const Text('Disable Provisioning'),
                ),
                OutlinedButton(
                  onPressed: _startWifiScan,
                  child: const Text('Start Scan'),
                ),
                OutlinedButton(
                  onPressed: _getConnectedWifiList,
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
                  onPressed: _connectToWifi,
                  child: const Text('Connect'),
                ),
              ],
            ),
            if (state.wifiConnectionStatus != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last result: ${state.wifiConnectionStatus}',
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
                          _wifiSsidController.text = entry.ssid;
                          _wifiBssidController.text = entry.bssid;
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

  Widget _buildMediaSection(TextTheme textTheme, Insta360State state) {
    final photoPreview = state.selectedPhotoBytes;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Media Library',
        trailing: state.isLoadingMedia
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
                  onPressed: state.isLoadingMedia ? null : _refreshMedia,
                  child: Text(
                    state.isLoadingMedia ? 'Loading...' : 'Refresh Media',
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    context.read<Insta360Bloc>().add(ResetMediaRequested());
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
            Text('Photos (${state.photoList.length})', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            if (state.photoList.isEmpty)
              Text('No photos loaded.', style: textTheme.bodySmall)
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  itemCount: state.photoList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = state.photoList[index];
                    final uri = item.uri;
                    final isSelected = uri == state.selectedPhotoUri;
                    final progress = state.downloadProgress[uri];
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
            Text('Videos (${state.videoList.length})', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            if (state.videoList.isEmpty)
              Text('No videos loaded.', style: textTheme.bodySmall)
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  itemCount: state.videoList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = state.videoList[index];
                    final uri = item.uri;
                    final isSelected = state.selectedVideoUris.contains(uri);
                    final sizeLabel = _formatFileSize(item.sizeBytes);
                    final progress = state.downloadProgress[uri];
                    final subtitle = <String>[];
                    if (sizeLabel.isNotEmpty) {
                      subtitle.add(sizeLabel);
                    }
                    final totalTime = item.raw['totalTime'];
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
            if (state.selectedVideoUris.isNotEmpty)
              Text(
                'Selected videos: ${state.selectedVideoUris.join(', ')}',
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
                  onPressed: state.selectedVideoUris.isEmpty
                      ? null
                      : _loadPlaybackSources,
                  child: const Text('Load Player'),
                ),
                FilledButton.tonal(
                  onPressed: () => context
                      .read<Insta360Bloc>()
                      .add(PlaybackPlayRequested()),
                  child: const Text('Play'),
                ),
                FilledButton.tonal(
                  onPressed: () => context
                      .read<Insta360Bloc>()
                      .add(PlaybackPauseRequested()),
                  child: const Text('Pause'),
                ),
                OutlinedButton(
                  onPressed: () => context
                      .read<Insta360Bloc>()
                      .add(PlaybackStopRequested()),
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
                  onPressed: state.selectedVideoUris.isEmpty
                      ? null
                      : _exportSelectedVideo,
                  child: const Text('Export Video'),
                ),
                FilledButton.tonal(
                  onPressed: state.selectedPhotoUri == null
                      ? null
                      : () => _exportSelectedPhoto(state.selectedPhotoUri ?? ''),
                  child: const Text('Export Photo'),
                ),
              ],
            ),
            if (state.exportProgress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: state.exportProgress),
            ],
            if (state.exportStatus != null) ...[
              const SizedBox(height: 4),
              Text(state.exportStatus!, style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required TextTheme textTheme,
    required Insta360State state,
    required String title,
    required String subtitle,
  }) {
    final hasBluetooth = state.connectedBluetoothId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
            ),
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
                label: state.wifiProvisioningEnabled
                    ? 'Provisioning on'
                    : 'Provisioning off',
                color: state.wifiProvisioningEnabled
                    ? const Color(0xFF0C8B7D)
                    : const Color(0xFF6B6B6B),
              ),
              if (state.exportProgress != null)
                StatusPill(
                  label: state.exportStatus ?? 'Exporting',
                  color: const Color(0xFFCF6F2B),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
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
                  onPressed: () => context
                      .read<Insta360Bloc>()
                      .add(StartPreviewRequested()),
                  child: const Text('Start Preview'),
                ),
                FilledButton.tonal(
                  onPressed: () => context
                      .read<Insta360Bloc>()
                      .add(StopPreviewRequested()),
                  child: const Text('Stop Preview'),
                ),
                OutlinedButton(
                  onPressed: () => context
                      .read<Insta360Bloc>()
                      .add(TakePictureRequested()),
                  child: const Text('Take Picture'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionControls(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Connections',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () =>
                      context.read<Insta360Bloc>().add(InitializeRequested()),
                  child: const Text('Initialize SDK'),
                ),
                FilledButton.tonal(
                  onPressed: () =>
                      context
                          .read<Insta360Bloc>()
                          .add(ConnectDeviceWifiRequested()),
                  child: const Text('Connect Wi-Fi'),
                ),
                OutlinedButton(
                  onPressed: () => context
                      .read<Insta360Bloc>()
                      .add(DisconnectDeviceWifiRequested()),
                  child: const Text('Disconnect Wi-Fi'),
                ),
                FilledButton.tonal(
                  onPressed: () =>
                      context.read<Insta360Bloc>().add(ConnectUsbRequested()),
                  child: const Text('Connect USB'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      context.read<Insta360Bloc>().add(DisconnectUsbRequested()),
                  child: const Text('Disconnect USB'),
                ),
                FilledButton.tonal(
                  onPressed: () => context
                      .read<Insta360Bloc>()
                      .add(ConnectExternalRequested()),
                  child: const Text('Connect External'),
                ),
                OutlinedButton(
                  onPressed: () => context
                      .read<Insta360Bloc>()
                      .add(DisconnectExternalRequested()),
                  child: const Text('Disconnect External'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureControls(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Capture',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () =>
                  context.read<Insta360Bloc>().add(StartCaptureRequested()),
              child: const Text('Start Capture'),
            ),
            FilledButton.tonal(
              onPressed: () =>
                  context.read<Insta360Bloc>().add(StopCaptureRequested()),
              child: const Text('Stop Capture'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothControls(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Bluetooth Control',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: () {
                context
                    .read<Insta360Bloc>()
                    .add(ResetBluetoothDevicesRequested());
                context.read<Insta360Bloc>().add(StartBluetoothScanRequested());
              },
              child: const Text('Start BT Scan'),
            ),
            OutlinedButton(
              onPressed: () =>
                  context.read<Insta360Bloc>().add(StopBluetoothScanRequested()),
              child: const Text('Stop BT Scan'),
            ),
            OutlinedButton(
              onPressed: () =>
                  context.read<Insta360Bloc>().add(FetchCameraStateRequested()),
              child: const Text('Get Camera State'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLog(TextTheme textTheme, Insta360State state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SectionCard(
        title: 'Activity Log',
        trailing: Text(
          '${state.eventLog.length} events',
          style: textTheme.bodySmall,
        ),
        child: SizedBox(
          height: 200,
          child: state.eventLog.isEmpty
              ? Center(
                  child: Text(
                    'No events yet.',
                    style: textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: state.eventLog.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        state.eventLog[index],
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
    return BlocBuilder<Insta360Bloc, Insta360State>(
      builder: (context, state) {
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
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    _buildConnectTab(textTheme, state),
                    _buildBluetoothTab(textTheme, state),
                    _buildWifiTab(textTheme, state),
                    _buildLiveTab(textTheme, state),
                    _buildMediaTab(textTheme, state),
                    const ProfilePage(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (index) {
              setState(() {
                _tabIndex = index;
              });
            },
            indicatorColor: const Color(0xFF0C8B7D).withOpacity(0.2),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.hub_outlined),
                selectedIcon: Icon(Icons.hub),
                label: 'Connect',
              ),
              NavigationDestination(
                icon: Icon(Icons.bluetooth_outlined),
                selectedIcon: Icon(Icons.bluetooth),
                label: 'Bluetooth',
              ),
              NavigationDestination(
                icon: Icon(Icons.wifi_outlined),
                selectedIcon: Icon(Icons.wifi),
                label: 'Wi-Fi',
              ),
              NavigationDestination(
                icon: Icon(Icons.videocam_outlined),
                selectedIcon: Icon(Icons.videocam),
                label: 'Live',
              ),
              NavigationDestination(
                icon: Icon(Icons.photo_library_outlined),
                selectedIcon: Icon(Icons.photo_library),
                label: 'Media',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectTab(TextTheme textTheme, Insta360State state) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            textTheme: textTheme,
            state: state,
            title: 'Connect',
            subtitle: 'Pair devices, provision Wi-Fi, and manage sessions.',
          ),
        ),
        SliverToBoxAdapter(child: _buildConnectionControls(textTheme)),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildBluetoothTab(TextTheme textTheme, Insta360State state) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            textTheme: textTheme,
            state: state,
            title: 'Bluetooth',
            subtitle: 'Scan, connect, and manage Bluetooth devices.',
          ),
        ),
        SliverToBoxAdapter(child: _buildBluetoothControls(textTheme)),
        SliverToBoxAdapter(child: _buildBluetoothSection(textTheme, state)),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildWifiTab(TextTheme textTheme, Insta360State state) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            textTheme: textTheme,
            state: state,
            title: 'Wi-Fi',
            subtitle: 'Configure camera Wi-Fi and provisioning.',
          ),
        ),
        SliverToBoxAdapter(child: _buildWifiSection()),
        SliverToBoxAdapter(
          child: _buildWifiProvisioningSection(textTheme, state),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildLiveTab(TextTheme textTheme, Insta360State state) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            textTheme: textTheme,
            state: state,
            title: 'Live',
            subtitle: 'Preview, capture, and control playback quickly.',
          ),
        ),
        SliverToBoxAdapter(child: _buildPreviewSection()),
        SliverToBoxAdapter(child: _buildCaptureControls(textTheme)),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildMediaTab(TextTheme textTheme, Insta360State state) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            textTheme: textTheme,
            state: state,
            title: 'Media',
            subtitle: 'Browse files, download, export, and review logs.',
          ),
        ),
        SliverToBoxAdapter(child: _buildMediaSection(textTheme, state)),
        SliverToBoxAdapter(child: _buildEventLog(textTheme, state)),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
