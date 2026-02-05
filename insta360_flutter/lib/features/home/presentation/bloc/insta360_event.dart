import 'package:equatable/equatable.dart';
import 'package:insta360_sdk/insta360_sdk.dart' as sdk;

abstract class Insta360UiEvent extends Equatable {
  const Insta360UiEvent();

  @override
  List<Object?> get props => [];
}

class SdkEventReceived extends Insta360UiEvent {
  const SdkEventReceived(this.event);

  final sdk.Insta360Event event;

  @override
  List<Object?> get props => [event];
}

class ClientLogRequested extends Insta360UiEvent {
  const ClientLogRequested(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class StartBluetoothScanRequested extends Insta360UiEvent {}

class StopBluetoothScanRequested extends Insta360UiEvent {}

class ConnectBluetoothRequested extends Insta360UiEvent {
  const ConnectBluetoothRequested(this.identifier);

  final String identifier;

  @override
  List<Object?> get props => [identifier];
}

class DisconnectBluetoothRequested extends Insta360UiEvent {}

class ResetBluetoothDevicesRequested extends Insta360UiEvent {}

class InitializeRequested extends Insta360UiEvent {}

class ConnectDeviceWifiRequested extends Insta360UiEvent {}

class DisconnectDeviceWifiRequested extends Insta360UiEvent {}

class ConnectUsbRequested extends Insta360UiEvent {}

class DisconnectUsbRequested extends Insta360UiEvent {}

class ConnectExternalRequested extends Insta360UiEvent {}

class DisconnectExternalRequested extends Insta360UiEvent {}

class StartPreviewRequested extends Insta360UiEvent {}

class StopPreviewRequested extends Insta360UiEvent {}

class TakePictureRequested extends Insta360UiEvent {}

class StartCaptureRequested extends Insta360UiEvent {}

class StopCaptureRequested extends Insta360UiEvent {}

class FetchCameraStateRequested extends Insta360UiEvent {}

class GetWifiInfoRequested extends Insta360UiEvent {}

class GetWifiChannelListRequested extends Insta360UiEvent {}

class OpenWifiRequested extends Insta360UiEvent {
  const OpenWifiRequested(this.channel);

  final int channel;

  @override
  List<Object?> get props => [channel];
}

class CloseWifiRequested extends Insta360UiEvent {}

class ResetWifiRequested extends Insta360UiEvent {
  const ResetWifiRequested(this.channel);

  final int channel;

  @override
  List<Object?> get props => [channel];
}

class SetWifiCountryCodeRequested extends Insta360UiEvent {
  const SetWifiCountryCodeRequested(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

class SetWifiProvisioningRequested extends Insta360UiEvent {
  const SetWifiProvisioningRequested(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class StartWifiScanRequested extends Insta360UiEvent {
  const StartWifiScanRequested({required this.interval, required this.count});

  final int interval;
  final int count;

  @override
  List<Object?> get props => [interval, count];
}

class ConnectWifiRequested extends Insta360UiEvent {
  const ConnectWifiRequested({
    required this.ssid,
    required this.password,
    this.bssid,
  });

  final String ssid;
  final String password;
  final String? bssid;

  @override
  List<Object?> get props => [ssid, password, bssid];
}

class GetConnectedWifiListRequested extends Insta360UiEvent {}

class FetchMediaRequested extends Insta360UiEvent {
  const FetchMediaRequested({required this.start, required this.limit});

  final int start;
  final int limit;

  @override
  List<Object?> get props => [start, limit];
}

class ResetMediaRequested extends Insta360UiEvent {}

class SelectPhotoRequested extends Insta360UiEvent {
  const SelectPhotoRequested(this.uri);

  final String uri;

  @override
  List<Object?> get props => [uri];
}

class ToggleVideoSelectionRequested extends Insta360UiEvent {
  const ToggleVideoSelectionRequested(this.uri);

  final String uri;

  @override
  List<Object?> get props => [uri];
}

class LoadPlaybackSourcesRequested extends Insta360UiEvent {}

class PlaybackPlayRequested extends Insta360UiEvent {}

class PlaybackPauseRequested extends Insta360UiEvent {}

class PlaybackStopRequested extends Insta360UiEvent {}

class DownloadMediaRequested extends Insta360UiEvent {
  const DownloadMediaRequested(this.uri);

  final String uri;

  @override
  List<Object?> get props => [uri];
}

class ExportVideoRequested extends Insta360UiEvent {}

class ExportPhotoRequested extends Insta360UiEvent {
  const ExportPhotoRequested(this.uri);

  final String uri;

  @override
  List<Object?> get props => [uri];
}
