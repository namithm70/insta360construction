import Foundation
import Flutter
#if !targetEnvironment(simulator)
import INSCameraSDK
import INSCameraServiceSDK
#endif

#if targetEnvironment(simulator)
final class Insta360EventStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = eventSink
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func emit(_ payload: [String: Any]) {
    eventSink?(payload)
  }
}
#else
final class Insta360EventStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var notificationObservers: [NSObjectProtocol] = []
  private var isObserving = false

  private static var socketContext = 0
  private static var usbContext = 0
  private static var externalContext = 0

  func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = eventSink
    startObserving()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopObserving()
    eventSink = nil
    return nil
  }

  func emit(_ payload: [String: Any]) {
    eventSink?(payload)
  }

  override func observeValue(forKeyPath keyPath: String?,
                             of object: Any?,
                             change: [NSKeyValueChangeKey : Any]?,
                             context: UnsafeMutableRawPointer?) {
    guard keyPath == #keyPath(INSCameraManager.cameraState),
          let stateValue = change?[.newKey] as? UInt else {
      return
    }
    let source: String
    if context == &Self.socketContext {
      source = "socket"
    } else if context == &Self.usbContext {
      source = "usb"
    } else if context == &Self.externalContext {
      source = "external"
    } else {
      source = "unknown"
    }
    sendCameraState(source: source, stateValue: stateValue)
  }

  private func startObserving() {
    guard !isObserving else { return }
    isObserving = true

    let center = NotificationCenter.default
    let notificationNames: [Notification.Name] = [
      .INSCameraDidConnect,
      .INSCameraDidDisconnect,
      .INSCameraConnectionError,
      .INSCameraCaptureStopped,
      .INSCameraCaptureSplit,
      .INSCameraTakePictureStateUpdate,
      .INSCameraStorageStatus,
      .INSCameraStorageFull,
      .INSCameraBatteryStatus,
      .INSCameraBatteryLow,
      .INSCameraWillShutDown,
      .INSCameraFWUpgradeDone,
      .INSCameraTemperatureStatus,
      .INSCameraWifiStatusUpdate,
      .INSCameraCameraWifiStatus,
      .INSCameraWifiModeChange,
      .INSCameraWifiScanListChanged,
      .INSCameraAuthorizationResult
    ]
    for name in notificationNames {
      let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
        self?.sendNotification(notification)
      }
      notificationObservers.append(token)
    }

    INSCameraManager.socket().addObserver(self,
                                          forKeyPath: #keyPath(INSCameraManager.cameraState),
                                          options: [.new],
                                          context: &Self.socketContext)
    INSCameraManager.usb().addObserver(self,
                                       forKeyPath: #keyPath(INSCameraManager.cameraState),
                                       options: [.new],
                                       context: &Self.usbContext)
    INSCameraManager.external().addObserver(self,
                                            forKeyPath: #keyPath(INSCameraManager.cameraState),
                                            options: [.new],
                                            context: &Self.externalContext)
  }

  private func stopObserving() {
    guard isObserving else { return }
    isObserving = false

    notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    notificationObservers.removeAll()

    INSCameraManager.socket().removeObserver(self, forKeyPath: #keyPath(INSCameraManager.cameraState), context: &Self.socketContext)
    INSCameraManager.usb().removeObserver(self, forKeyPath: #keyPath(INSCameraManager.cameraState), context: &Self.usbContext)
    INSCameraManager.external().removeObserver(self, forKeyPath: #keyPath(INSCameraManager.cameraState), context: &Self.externalContext)
  }

  private func sendNotification(_ notification: Notification) {
    if notification.name == .INSCameraWifiScanListChanged {
      if let list = extractWifiScanList(from: notification.userInfo) {
        emit([
          "type": "wifi_scan_list",
          "list": list
        ])
        return
      }
    }
    if notification.name == .INSCameraCameraWifiStatus {
      if let result = extractWifiConnectionResult(from: notification.userInfo) {
        emit([
          "type": "wifi_connection_result",
          "result": result
        ])
        return
      }
    }
    let payload: [String: Any] = [
      "type": "notification",
      "name": notification.name.rawValue,
      "userInfo": sanitizeUserInfo(notification.userInfo)
    ]
    emit(payload)
  }

  private func sendCameraState(source: String, stateValue: UInt) {
    let state = INSCameraState(rawValue: stateValue)
    let payload: [String: Any] = [
      "type": "camera_state",
      "source": source,
      "state": Int(stateValue),
      "stateName": stateName(for: state)
    ]
    emit(payload)
  }

  private func sanitizeUserInfo(_ userInfo: [AnyHashable: Any]?) -> [String: String] {
    guard let userInfo else { return [:] }
    var sanitized: [String: String] = [:]
    for (key, value) in userInfo {
      sanitized[String(describing: key)] = String(describing: value)
    }
    return sanitized
  }

  private func stateName(for state: INSCameraState?) -> String {
    guard let state else { return "unknown" }
    switch state {
    case .found:
      return "found"
    case .synchronized:
      return "synchronized"
    case .connected:
      return "connected"
    case .connectFailed:
      return "connect_failed"
    case .noConnection:
      return "no_connection"
    @unknown default:
      return "unknown"
    }
  }

  private func extractWifiScanList(from userInfo: [AnyHashable: Any]?) -> [[String: Any]]? {
    guard let userInfo else { return nil }
    if let list = userInfo["scanWifiList"] as? INSWifiScanInfoList {
      let items = list.wifiInfoArray as? [INSWifiScanInfo] ?? []
      return items.map { info in
        [
          "ssid": info.ssid,
          "bssid": info.bssid,
          "frequency": Int(info.frequency),
          "signalLevel": Int(info.signalLevel),
          "flags": info.flags
        ]
      }
    }
    if let list = userInfo["scanWifiList"] as? [Any] {
      let infos = list.compactMap { $0 as? INSWifiScanInfo }
      return infos.map { info in
        [
          "ssid": info.ssid,
          "bssid": info.bssid,
          "frequency": Int(info.frequency),
          "signalLevel": Int(info.signalLevel),
          "flags": info.flags
        ]
      }
    }
    return nil
  }

  private func extractWifiConnectionResult(from userInfo: [AnyHashable: Any]?) -> [String: Any]? {
    guard let userInfo else { return nil }
    guard let result = userInfo["wifiConnectionResult"] as? INSCameraWifiConnectionResult else {
      return nil
    }
    var payload: [String: Any] = [
      "code": Int(result.wifiConnectionResult.rawValue)
    ]
    if result.hasWifiConnectionInfo {
      let info = result.wifiConnectionInfo
      payload["ssid"] = info.ssid
      payload["bssid"] = info.bssid
      payload["ipAddr"] = info.ipAddr
    }
    return payload
  }
}
#endif
