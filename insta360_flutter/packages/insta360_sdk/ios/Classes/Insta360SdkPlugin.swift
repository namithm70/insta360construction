import Flutter
import UIKit
import NetworkExtension

public class Insta360SdkPlugin: NSObject, FlutterPlugin {
  private let cameraController = Insta360CameraController.shared
  private let eventHandler = Insta360EventStreamHandler()
  private let playbackController = Insta360PlaybackController.shared

  override init() {
    super.init()
    cameraController.eventHandler = eventHandler
    playbackController.eventHandler = eventHandler
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = Insta360SdkPlugin()
    let methodChannel = FlutterMethodChannel(name: "insta360_sdk/methods", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(name: "insta360_sdk/events", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance.eventHandler)

    let previewFactory = Insta360PreviewFactory(messenger: registrar.messenger(), cameraController: Insta360CameraController.shared)
    registrar.register(previewFactory, withId: "insta360_sdk/preview")

    let playbackFactory = Insta360PlaybackFactory(messenger: registrar.messenger(), playbackController: Insta360PlaybackController.shared)
    registrar.register(playbackFactory, withId: "insta360_sdk/player")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      cameraController.initialize()
      result(nil)
    case "connectWifi":
      cameraController.connectWifi()
      result(nil)
    case "disconnectWifi":
      cameraController.disconnectWifi()
      result(nil)
    case "connectUsb":
      cameraController.connectUsb()
      result(nil)
    case "disconnectUsb":
      cameraController.disconnectUsb()
      result(nil)
    case "connectExternal":
      cameraController.connectExternal()
      result(nil)
    case "disconnectExternal":
      cameraController.disconnectExternal()
      result(nil)
    case "startBluetoothScan":
      if let errorMessage = cameraController.startBluetoothScan() {
        result(FlutterError(code: "bluetooth_scan_failed", message: errorMessage, details: nil))
      } else {
        result(nil)
      }
    case "stopBluetoothScan":
      cameraController.stopBluetoothScan()
      result(nil)
    case "connectBluetoothDevice":
      guard let args = call.arguments as? [String: Any],
            let identifier = args["identifier"] as? String else {
        result(FlutterError(code: "invalid_arguments", message: "Missing identifier", details: nil))
        return
      }
      cameraController.connectBluetoothDevice(identifier: identifier) { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "bluetooth_connect_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "disconnectBluetoothDevice":
      cameraController.disconnectBluetoothDevice()
      result(nil)
    case "openCameraWifi":
      let args = call.arguments as? [String: Any]
      let channel = (args?["channel"] as? NSNumber)?.uint32Value ?? 0
      cameraController.openCameraWifi(channel: channel) { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "wifi_open_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "closeCameraWifi":
      cameraController.closeCameraWifi { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "wifi_close_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "resetCameraWifi":
      let args = call.arguments as? [String: Any]
      let channel = (args?["channel"] as? NSNumber)?.uint32Value ?? 0
      cameraController.resetCameraWifi(channel: channel) { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "wifi_reset_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "setWifiCountryCode":
      guard let args = call.arguments as? [String: Any],
            let countryCode = args["countryCode"] as? String else {
        result(FlutterError(code: "invalid_arguments", message: "Missing countryCode", details: nil))
        return
      }
      cameraController.setWifiCountryCode(countryCode) { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "wifi_country_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "getWifiInfo":
      cameraController.getWifiInfo { resultValue in
        switch resultValue {
        case .success(let payload):
          result(payload)
        case .failure(let error):
          result(FlutterError(code: "wifi_info_failed", message: error.message, details: nil))
        }
      }
    case "getWifiChannelList":
      cameraController.getWifiChannelList { resultValue in
        switch resultValue {
        case .success(let payload):
          result(payload)
        case .failure(let error):
          result(FlutterError(code: "wifi_channel_list_failed", message: error.message, details: nil))
        }
      }
    case "setWifiProvisioningEnabled":
      guard let args = call.arguments as? [String: Any],
            let enabled = args["enabled"] as? Bool else {
        result(FlutterError(code: "invalid_arguments", message: "Missing enabled", details: nil))
        return
      }
      cameraController.setWifiProvisioningEnabled(enabled) { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "wifi_provision_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "startWifiScan":
      let args = call.arguments as? [String: Any]
      let interval = (args?["interval"] as? NSNumber)?.uint32Value ?? 1
      let count = (args?["count"] as? NSNumber)?.uint32Value ?? 3
      cameraController.startWifiScan(interval: interval, count: count) { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "wifi_scan_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "connectToWifi":
      guard let args = call.arguments as? [String: Any],
            let ssid = args["ssid"] as? String,
            let password = args["password"] as? String else {
        result(FlutterError(code: "invalid_arguments", message: "Missing ssid/password", details: nil))
        return
      }
      let bssid = args["bssid"] as? String
      cameraController.connectToWifi(ssid: ssid, bssid: bssid, password: password) { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "wifi_connect_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "joinCameraWifi":
      guard let args = call.arguments as? [String: Any],
            let ssid = args["ssid"] as? String else {
        result(FlutterError(code: "invalid_arguments", message: "Missing ssid", details: nil))
        return
      }
      let password = args["password"] as? String ?? ""
      let joinOnce = args["joinOnce"] as? Bool ?? true
      let configuration: NEHotspotConfiguration
      if password.isEmpty {
        configuration = NEHotspotConfiguration(ssid: ssid)
      } else {
        configuration = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
      }
      configuration.joinOnce = joinOnce
      NEHotspotConfigurationManager.shared.apply(configuration) { error in
        if let error {
          let nsError = error as NSError
          if nsError.domain == NEHotspotConfigurationErrorDomain &&
              nsError.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
            result(nil)
            return
          }
          result(FlutterError(code: "wifi_join_failed", message: nsError.localizedDescription, details: nsError.code))
          return
        }
        result(nil)
      }
    case "getConnectedWifiList":
      cameraController.getConnectedWifiList { resultValue in
        switch resultValue {
        case .success(let payload):
          result(payload)
        case .failure(let error):
          result(FlutterError(code: "wifi_connect_list_failed", message: error.message, details: nil))
        }
      }
    case "startPreview":
      cameraController.startPreview { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "preview_start_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "stopPreview":
      cameraController.stopPreview { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "preview_stop_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "takePicture":
      cameraController.takePicture { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "take_picture_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "startCapture":
      cameraController.startCapture { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "start_capture_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "stopCapture":
      cameraController.stopCapture { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "stop_capture_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "listMedia":
      let args = call.arguments as? [String: Any]
      let start = (args?["start"] as? NSNumber)?.uintValue ?? 0
      let limit = (args?["limit"] as? NSNumber)?.uintValue ?? 200
      let storageType = (args?["storageType"] as? NSNumber)?.uint8Value ?? 2
      cameraController.listMedia(storageType: storageType, start: start, limit: limit) { resultValue in
        switch resultValue {
        case .success(let payload):
          result(payload)
        case .failure(let error):
          result(FlutterError(code: "list_media_failed", message: error.message, details: nil))
        }
      }
    case "fetchPhoto":
      guard let args = call.arguments as? [String: Any],
            let uri = args["uri"] as? String else {
        result(FlutterError(code: "invalid_arguments", message: "Missing uri", details: nil))
        return
      }
      cameraController.fetchPhoto(uri: uri) { resultValue in
        switch resultValue {
        case .success(let data):
          result(data)
        case .failure(let error):
          result(FlutterError(code: "fetch_photo_failed", message: error.message, details: nil))
        }
      }
    case "downloadResource":
      guard let args = call.arguments as? [String: Any],
            let uri = args["uri"] as? String else {
        result(FlutterError(code: "invalid_arguments", message: "Missing uri", details: nil))
        return
      }
      let targetPath = args["targetPath"] as? String
      cameraController.downloadResource(uri: uri, targetPath: targetPath) { resultValue in
        switch resultValue {
        case .success(let path):
          result(path)
        case .failure(let error):
          result(FlutterError(code: "download_failed", message: error.message, details: nil))
        }
      }
    case "setPlaybackSources":
      guard let args = call.arguments as? [String: Any],
            let sources = args["sources"] as? [String] else {
        result(FlutterError(code: "invalid_arguments", message: "Missing sources", details: nil))
        return
      }
      playbackController.setVideoSources(sources) { errorMessage in
        if let errorMessage {
          result(FlutterError(code: "playback_source_failed", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    case "playbackPlay":
      playbackController.play()
      result(nil)
    case "playbackPause":
      playbackController.pause()
      result(nil)
    case "playbackStop":
      playbackController.stop()
      result(nil)
    case "exportVideo":
      guard let args = call.arguments as? [String: Any],
            let uris = args["uris"] as? [String] else {
        result(FlutterError(code: "invalid_arguments", message: "Missing uris", details: nil))
        return
      }
      let options = args["options"] as? [String: Any] ?? [:]
      let exportId = args["exportId"] as? String
      cameraController.exportVideo(uris: uris, options: options, exportId: exportId) { resultValue in
        switch resultValue {
        case .success(let path):
          result(path)
        case .failure(let error):
          result(FlutterError(code: "export_video_failed", message: error.message, details: nil))
        }
      }
    case "exportImage":
      guard let args = call.arguments as? [String: Any],
            let uri = args["uri"] as? String else {
        result(FlutterError(code: "invalid_arguments", message: "Missing uri", details: nil))
        return
      }
      let options = args["options"] as? [String: Any] ?? [:]
      let exportId = args["exportId"] as? String
      cameraController.exportImage(uri: uri, options: options, exportId: exportId) { resultValue in
        switch resultValue {
        case .success(let path):
          result(path)
        case .failure(let error):
          result(FlutterError(code: "export_image_failed", message: error.message, details: nil))
        }
      }
    case "getCameraState":
      result(cameraController.cameraStateSummary())
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
