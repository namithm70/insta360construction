import Foundation
import UIKit
#if !targetEnvironment(simulator)
import INSCameraSDK
import INSCameraServiceSDK
import INSCoreMedia
#endif

struct Insta360SdkError: Error {
  let message: String
}

#if targetEnvironment(simulator)
final class Insta360CameraController: NSObject {
  static let shared = Insta360CameraController()

  weak var eventHandler: Insta360EventStreamHandler?

  private func emitEvent(_ payload: [String: Any]) {
    eventHandler?.emit(payload)
  }

  func initialize() {}

  func connectWifi() {}

  func disconnectWifi() {}

  func connectUsb() {}

  func disconnectUsb() {}

  func connectExternal() {}

  func disconnectExternal() {}

  func startBluetoothScan() -> String? {
    emitEvent(["type": "bluetooth_scan_started"])
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.emitEvent(["type": "bluetooth_scan_stopped"])
    }
    return nil
  }

  func stopBluetoothScan() {
    emitEvent(["type": "bluetooth_scan_stopped"])
  }

  func connectBluetoothDevice(identifier: String, completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func disconnectBluetoothDevice() {}

  func openCameraWifi(channel: UInt32, completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func closeCameraWifi(completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func resetCameraWifi(channel: UInt32, completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func setWifiCountryCode(_ countryCode: String, completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func getWifiInfo(completion: @escaping (Result<[String: Any], Insta360SdkError>) -> Void) {
    completion(.failure(Insta360SdkError(message: "simulator_not_supported")))
  }

  func getWifiChannelList(completion: @escaping (Result<[String: Any], Insta360SdkError>) -> Void) {
    completion(.failure(Insta360SdkError(message: "simulator_not_supported")))
  }

  func setWifiProvisioningEnabled(_ enabled: Bool, completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func startWifiScan(interval: UInt32, count: UInt32, completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func connectToWifi(ssid: String, bssid: String?, password: String, completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func getConnectedWifiList(completion: @escaping (Result<[String: Any], Insta360SdkError>) -> Void) {
    completion(.failure(Insta360SdkError(message: "simulator_not_supported")))
  }

  func listMedia(storageType: UInt8, start: UInt, limit: UInt, completion: @escaping (Result<[String: Any], Insta360SdkError>) -> Void) {
    completion(.success([
      "photos": [],
      "videos": []
    ]))
  }

  func fetchPhoto(uri: String, completion: @escaping (Result<Data, Insta360SdkError>) -> Void) {
    completion(.failure(Insta360SdkError(message: "simulator_not_supported")))
  }

  func downloadResource(uri: String, targetPath: String?, completion: @escaping (Result<String, Insta360SdkError>) -> Void) {
    completion(.failure(Insta360SdkError(message: "simulator_not_supported")))
  }

  func exportVideo(uris: [String], options: [String: Any], exportId: String?, completion: @escaping (Result<String, Insta360SdkError>) -> Void) {
    completion(.failure(Insta360SdkError(message: "simulator_not_supported")))
  }

  func exportImage(uri: String, options: [String: Any], exportId: String?, completion: @escaping (Result<String, Insta360SdkError>) -> Void) {
    completion(.failure(Insta360SdkError(message: "simulator_not_supported")))
  }

  func setPreviewContainer(_ container: UIView) {}

  func clearPreviewContainer(_ container: UIView) {}

  func startPreview(completion: ((String?) -> Void)? = nil) {
    completion?(nil)
  }

  func stopPreview(completion: ((String?) -> Void)? = nil) {
    completion?(nil)
  }

  func takePicture(completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func startCapture(completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func stopCapture(completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func cameraStateSummary() -> [String: Int] {
    return [
      "socket": 0,
      "usb": 0,
      "external": 0
    ]
  }
}
#else
final class Insta360CameraController: NSObject, INSBluetoothManagerDelegate, INSRExporter2ManagerDelegate {
  static let shared = Insta360CameraController()

  weak var eventHandler: Insta360EventStreamHandler?

  private var isInitialized = false
  private let mediaSession = INSCameraMediaSession()
  private var previewPlayer: INSCameraPreviewPlayer?
  private weak var previewContainer: UIView?
  private var isPreviewPlugged = false
  private var isSessionRunning = false
  private var heartbeatTimer: DispatchSourceTimer?

  private var videoExporter: INSExportSimplify?
  private var imageExporter: INSExportImageSimplify?
  private var exportCompletion: ((Result<String, Insta360SdkError>) -> Void)?
  private var exportOutputPath: String?
  private var exportId: String?
  private var exportKind: String?

  private let bluetoothManager = INSBluetoothManager()
  private var bluetoothDevicesById: [String: INSBluetoothDevice] = [:]
  private var connectedBluetoothDevice: INSBluetoothDevice?
  private var bluetoothConnectTask: Any?

  override init() {
    super.init()
    bluetoothManager.delegate = self
  }

  func initialize() {
    guard !isInitialized else { return }
    isInitialized = true
    INSCameraManager.shared().setup()
  }

  func connectWifi() {
    INSCameraManager.socket().autoReconnect = true
    INSCameraManager.socket().setup()
  }

  func disconnectWifi() {
    INSCameraManager.socket().shutdown()
    stopHeartbeats()
  }

  func connectUsb() {
    INSCameraManager.usb().setup()
  }

  func disconnectUsb() {
    INSCameraManager.usb().shutdown()
    stopHeartbeats()
  }

  func connectExternal() {
    INSCameraManager.external().setup()
  }

  func disconnectExternal() {
    INSCameraManager.external().shutdown()
    stopHeartbeats()
  }

  func startBluetoothScan() -> String? {
    guard bluetoothManager.state == .ready else {
      return "bluetooth_not_ready"
    }
    bluetoothDevicesById.removeAll()
    emitEvent([
      "type": "bluetooth_scan_started"
    ])
    bluetoothManager.scanCameras { [weak self] device, rssi, _ in
      guard let self else { return }
      let identifier = device.identifierUUIDStringSafe
      if self.bluetoothDevicesById[identifier] == nil {
        self.bluetoothDevicesById[identifier] = device
        let name = device.name.isEmpty ? "unknown" : device.name
        self.emitEvent([
          "type": "bluetooth_device_found",
          "identifier": identifier,
          "name": name,
          "rssi": rssi.intValue
        ])
      }
    }
    return nil
  }

  func stopBluetoothScan() {
    bluetoothManager.stopScan()
    emitEvent([
      "type": "bluetooth_scan_stopped"
    ])
  }

  func connectBluetoothDevice(identifier: String, completion: @escaping (String?) -> Void) {
    guard bluetoothManager.state == .ready else {
      completion("bluetooth_not_ready")
      return
    }
    guard let device = bluetoothDevicesById[identifier] else {
      completion("bluetooth_device_not_found")
      return
    }
    if let connected = connectedBluetoothDevice {
      bluetoothManager.disconnectDevice(connected)
    }
    bluetoothConnectTask = bluetoothManager.connect(device) { [weak self] error in
      guard let self else { return }
      if let error {
        self.emitEvent([
          "type": "bluetooth_connect_failed",
          "identifier": identifier,
          "error": error.localizedDescription
        ])
        completion(error.localizedDescription)
      } else {
        self.connectedBluetoothDevice = device
        let name = device.name.isEmpty ? "unknown" : device.name
        self.emitEvent([
          "type": "bluetooth_connected",
          "identifier": identifier,
          "name": name
        ])
        completion(nil)
      }
    }
  }

  func disconnectBluetoothDevice() {
    guard let connected = connectedBluetoothDevice else { return }
    bluetoothManager.disconnectDevice(connected)
    connectedBluetoothDevice = nil
  }

  func openCameraWifi(channel: UInt32, completion: @escaping (String?) -> Void) {
    guard let commandManager = bluetoothCommandManager() else {
      completion("bluetooth_not_connected")
      return
    }
    let options = makeWifiRequestOptions()
    commandManager.openCameraWifi(with: options, channel: channel) { error in
      completion(error?.localizedDescription)
    }
  }

  func closeCameraWifi(completion: @escaping (String?) -> Void) {
    guard let commandManager = bluetoothCommandManager() else {
      completion("bluetooth_not_connected")
      return
    }
    let options = makeWifiRequestOptions()
    commandManager.closeCameraWifi(with: options) { error in
      completion(error?.localizedDescription)
    }
  }

  func resetCameraWifi(channel: UInt32, completion: @escaping (String?) -> Void) {
    guard let commandManager = bluetoothCommandManager() else {
      completion("bluetooth_not_connected")
      return
    }
    let options = makeWifiRequestOptions()
    commandManager.resetCameraWifi(with: options, channel: channel) { error in
      completion(error?.localizedDescription)
    }
  }

  func setWifiCountryCode(_ countryCode: String, completion: @escaping (String?) -> Void) {
    guard let commandManager = bluetoothCommandManager() else {
      completion("bluetooth_not_connected")
      return
    }
    let options = INSCameraOptions()
    options.wifiChannelList = INSCameraWifiChannelList(countryCode: countryCode)
    let types = [NSNumber(value: INSCameraOptionsType.wifiChannelList.rawValue)]
    let requestOptions = makeWifiRequestOptions()
    commandManager.setOptions(options, requestOptions: requestOptions, forTypes: types) { error, _ in
      completion(error?.localizedDescription)
    }
  }

  func getWifiInfo(completion: @escaping (Result<[String: Any], Insta360SdkError>) -> Void) {
    guard let commandManager = bluetoothCommandManager() else {
      completion(.failure(Insta360SdkError(message: "bluetooth_not_connected")))
      return
    }
    let types = [NSNumber(value: INSCameraOptionsType.wifiInfo.rawValue)]
    let requestOptions = makeWifiRequestOptions()
    commandManager.getOptionsWithTypes(types, requestOptions: requestOptions) { error, options, _ in
      if let error {
        completion(.failure(Insta360SdkError(message: error.localizedDescription)))
        return
      }
      guard let wifiInfo = options?.wifiInfo else {
        completion(.failure(Insta360SdkError(message: "wifi_info_unavailable")))
        return
      }
      let payload: [String: Any] = [
        "ssid": wifiInfo.ssid,
        "password": wifiInfo.password,
        "channel": wifiInfo.channel,
        "mode": Int(wifiInfo.mode.rawValue),
        "state": Int(wifiInfo.wifiState.rawValue),
        "isBusy": wifiInfo.isBusy
      ]
      completion(.success(payload))
    }
  }

  func getWifiChannelList(completion: @escaping (Result<[String: Any], Insta360SdkError>) -> Void) {
    guard let commandManager = bluetoothCommandManager() else {
      completion(.failure(Insta360SdkError(message: "bluetooth_not_connected")))
      return
    }
    let types = [NSNumber(value: INSCameraOptionsType.wifiChannelList.rawValue)]
    let requestOptions = makeWifiRequestOptions()
    commandManager.getOptionsWithTypes(types, requestOptions: requestOptions) { error, options, _ in
      if let error {
        completion(.failure(Insta360SdkError(message: error.localizedDescription)))
        return
      }
      guard let list = options?.wifiChannelList else {
        completion(.failure(Insta360SdkError(message: "wifi_channel_list_unavailable")))
        return
      }
      let payload: [String: Any] = [
        "countryCode": list.countryCode,
        "channelList5g": list.channelList_5g.map { $0.intValue },
        "channelList24g": list.channelList_2_4g.map { $0.intValue }
      ]
      completion(.success(payload))
    }
  }

  func setWifiProvisioningEnabled(_ enabled: Bool, completion: @escaping (String?) -> Void) {
    guard let commandManager = bluetoothCommandManager() else {
      completion("bluetooth_not_connected")
      return
    }
    let enableType: INSSetNetworkConfigEnableType = enabled ? .enable : .disable
    commandManager.setNetworkConfigEnableType(enableType) { error in
      completion(error?.localizedDescription)
    }
  }

  func startWifiScan(interval: UInt32, count: UInt32, completion: @escaping (String?) -> Void) {
    guard let commandManager = bluetoothCommandManager() else {
      completion("bluetooth_not_connected")
      return
    }
    let params = INSGetWifiScanParams()
    params.interval = interval
    params.count = count
    commandManager.getWifiScanInfo(with: params) { error in
      completion(error?.localizedDescription)
    }
  }

  func connectToWifi(ssid: String, bssid: String?, password: String, completion: @escaping (String?) -> Void) {
    guard let commandManager = bluetoothCommandManager() else {
      completion("bluetooth_not_connected")
      return
    }
    let info = INSWifiConnectionInfo()
    info.ssid = ssid
    if let bssid, !bssid.isEmpty {
      info.bssid = bssid
    }
    info.password = password
    commandManager.setCameraWifiConnectionInfo(info) { error in
      completion(error?.localizedDescription)
    }
  }

  func getConnectedWifiList(completion: @escaping (Result<[String: Any], Insta360SdkError>) -> Void) {
    guard let commandManager = bluetoothCommandManager() else {
      completion(.failure(Insta360SdkError(message: "bluetooth_not_connected")))
      return
    }
    commandManager.getCameraConnectedWifiList { error, response in
      if let error {
        completion(.failure(Insta360SdkError(message: error.localizedDescription)))
        return
      }
      guard let response else {
        completion(.failure(Insta360SdkError(message: "wifi_connect_list_unavailable")))
        return
      }
      let list = response.connectListArray as? [INSWifiConnectionInfo] ?? []
      let mapped = list.map { info -> [String: Any] in
        [
          "ssid": info.ssid,
          "bssid": info.bssid,
          "ipAddr": info.ipAddr,
          "result": Int(info.result.rawValue),
          "isAuthWifi": Int(info.isAuthWifi)
        ]
      }
      var payload: [String: Any] = [
        "list": mapped
      ]
      let current = response.currentWifiConnectInfo
      payload["current"] = [
        "ssid": current.ssid,
        "bssid": current.bssid,
        "ipAddr": current.ipAddr,
        "result": Int(current.result.rawValue),
        "isAuthWifi": Int(current.isAuthWifi)
      ]
      completion(.success(payload))
    }
  }

  func listMedia(storageType: UInt8, start: UInt, limit: UInt, completion: @escaping (Result<[String: Any], Insta360SdkError>) -> Void) {
    let options = INSGetFileListOptions()
    options.type = storageType == 0
        ? .camera
        : INSStorageType(rawValue: storageType)
    options.start = start
    options.limit = limit

    INSCameraManager.shared().commandManager.fetchPhotoList(with: options) { error, photoRes in
      if let error {
        completion(.failure(Insta360SdkError(message: error.localizedDescription)))
        return
      }
      let photos = self.mapResources(photoRes, storageType: options.type)

      INSCameraManager.shared().commandManager.fetchVideoList(with: options) { error, videoRes in
        if let error {
          completion(.failure(Insta360SdkError(message: error.localizedDescription)))
          return
        }
        let videos = self.mapResources(videoRes, storageType: options.type)
        let payload: [String: Any] = [
          "photos": photos,
          "videos": videos
        ]
        completion(.success(payload))
      }
    }
  }

  func fetchPhoto(uri: String, completion: @escaping (Result<Data, Insta360SdkError>) -> Void) {
    INSCameraManager.shared().commandManager.fetchPhoto(withURI: uri) { error, data in
      if let error {
        completion(.failure(Insta360SdkError(message: error.localizedDescription)))
        return
      }
      guard let data else {
        completion(.failure(Insta360SdkError(message: "photo_data_unavailable")))
        return
      }
      completion(.success(data))
    }
  }

  func downloadResource(uri: String, targetPath: String?, completion: @escaping (Result<String, Insta360SdkError>) -> Void) {
    let outputUrl: URL
    if let targetPath, !targetPath.isEmpty {
      if targetPath.hasPrefix("file://"), let url = URL(string: targetPath) {
        outputUrl = url
      } else {
        outputUrl = URL(fileURLWithPath: targetPath)
      }
    } else {
      let outputDir = defaultDocumentsSubdir(named: "insta360_downloads")
      let fileName = (uri as NSString).lastPathComponent
      let safeName = fileName.isEmpty ? "resource_\(timestampString())" : fileName
      outputUrl = outputDir.appendingPathComponent(safeName)
    }

    if !ensureDirectory(outputUrl.deletingLastPathComponent()) {
      completion(.failure(Insta360SdkError(message: "download_directory_unavailable")))
      return
    }

    INSCameraManager.shared().commandManager.fetchResource(withURI: uri, toLocalFile: outputUrl, progress: { progress in
      let fraction = progress?.fractionCompleted ?? 0
      self.emitEvent([
        "type": "download_progress",
        "uri": uri,
        "progress": fraction,
        "completed": progress?.completedUnitCount ?? 0,
        "total": progress?.totalUnitCount ?? 0
      ])
    }, completion: { error in
      if let error {
        self.emitEvent([
          "type": "download_failed",
          "uri": uri,
          "error": error.localizedDescription
        ])
        completion(.failure(Insta360SdkError(message: error.localizedDescription)))
      } else {
        self.emitEvent([
          "type": "download_complete",
          "uri": uri,
          "path": outputUrl.path
        ])
        completion(.success(outputUrl.path))
      }
    })
  }

  func exportVideo(uris: [String], options: [String: Any], exportId: String?, completion: @escaping (Result<String, Insta360SdkError>) -> Void) {
    guard exportCompletion == nil else {
      completion(.failure(Insta360SdkError(message: "export_in_progress")))
      return
    }
    guard !uris.isEmpty else {
      completion(.failure(Insta360SdkError(message: "missing_uris")))
      return
    }

    let urls = uris.compactMap { urlFromStringOrURI($0) }
    guard !urls.isEmpty else {
      completion(.failure(Insta360SdkError(message: "invalid_uris")))
      return
    }

    let outputDir = defaultDocumentsSubdir(named: "insta360_exports")
    if !ensureDirectory(outputDir) {
      completion(.failure(Insta360SdkError(message: "export_directory_unavailable")))
      return
    }
    let outputUrl = outputDir.appendingPathComponent("video_export_\(timestampString()).mp4")

    let exporter = INSExportSimplify(urls: urls, outputUrl: outputUrl)
    applyExportOptions(options, to: exporter)

    let videoAsset = INSVideoAsset(path: urls[0].absoluteString, cacheDir: nil, option: .All)
    if videoAsset.open() == nil {
      if videoAsset.extraMetadata?.videoTrackCount == 2 || urls.count > 1 {
        exporter.imageLayout = .respective2Images
      } else {
        exporter.imageLayout = .horizontalMerged
      }
    }

    exporter.exportManagedelegate = self

    let startError = exporter.start()
    if let startError {
      completion(.failure(Insta360SdkError(message: startError.localizedDescription)))
      return
    }

    videoExporter = exporter
    exportCompletion = completion
    exportOutputPath = outputUrl.path
    self.exportId = exportId
    exportKind = "video"
  }

  func exportImage(uri: String, options: [String: Any], exportId: String?, completion: @escaping (Result<String, Insta360SdkError>) -> Void) {
    guard exportCompletion == nil else {
      completion(.failure(Insta360SdkError(message: "export_in_progress")))
      return
    }
    guard let inputUrl = urlFromStringOrURI(uri) else {
      completion(.failure(Insta360SdkError(message: "invalid_uri")))
      return
    }

    let outputDir = defaultDocumentsSubdir(named: "insta360_exports")
    if !ensureDirectory(outputDir) {
      completion(.failure(Insta360SdkError(message: "export_directory_unavailable")))
      return
    }
    let outputUrl = outputDir.appendingPathComponent("image_export_\(timestampString()).jpg")

    let exporter = INSExportImageSimplify()
    applyExportOptions(options, to: exporter)

    imageExporter = exporter
    exportCompletion = completion
    exportOutputPath = outputUrl.path
    self.exportId = exportId
    exportKind = "image"

    DispatchQueue.global(qos: .userInitiated).async {
      let exportError = exporter.exportImage(withInputUrl: inputUrl, outputUrl: outputUrl)
      DispatchQueue.main.async {
        let nsError = exportError as NSError
        if nsError.code != 0 {
          self.emitEvent([
            "type": "export_failed",
            "kind": "image",
            "exportId": exportId ?? "",
            "error": nsError.localizedDescription
          ])
          self.finishExport(with: .failure(Insta360SdkError(message: nsError.localizedDescription)))
        } else {
          self.emitEvent([
            "type": "export_complete",
            "kind": "image",
            "exportId": exportId ?? "",
            "outputPath": outputUrl.path
          ])
          self.finishExport(with: .success(outputUrl.path))
        }
      }
    }
  }

  func setPreviewContainer(_ container: UIView) {
    DispatchQueue.main.async {
      self.previewContainer = container
      self.attachPreviewPlayerIfNeeded()
    }
  }

  func clearPreviewContainer(_ container: UIView) {
    DispatchQueue.main.async {
      if self.previewContainer === container {
        self.previewContainer = nil
      }
      if let renderView = self.previewPlayer?.renderView, renderView.superview === container {
        renderView.removeFromSuperview()
      }
    }
  }

  func startPreview(completion: ((String?) -> Void)? = nil) {
    DispatchQueue.main.async {
      self.attachPreviewPlayerIfNeeded()
      guard let previewPlayer = self.previewPlayer else {
        completion?("Preview player is not ready.")
        return
      }
      self.mediaSession.flag = .live
      self.mediaSession.automaticallyAdjustsRotation = true
      self.mediaSession.previewStreamType = .main
      if !self.isPreviewPlugged {
        self.mediaSession.plug(previewPlayer)
        self.isPreviewPlugged = true
      }
      if self.isSessionRunning {
        completion?(nil)
        return
      }
      self.setLiveViewEnabled(true) { _ in
        self.startHeartbeats()
        self.mediaSession.startRunning { error in
          self.isSessionRunning = (error == nil)
          if let error {
            completion?(error.localizedDescription)
          } else {
            previewPlayer.play(withSmoothBuffer: true)
            completion?(nil)
          }
        }
      }
    }
  }

  func stopPreview(completion: ((String?) -> Void)? = nil) {
    DispatchQueue.main.async {
      if self.isPreviewPlugged, let previewPlayer = self.previewPlayer {
        self.mediaSession.unplug(previewPlayer)
        self.isPreviewPlugged = false
      }
      guard self.isSessionRunning else {
        self.setLiveViewEnabled(false) { _ in }
        self.stopHeartbeats()
        completion?(nil)
        return
      }
      self.mediaSession.stopRunning { error in
        self.isSessionRunning = false
        self.setLiveViewEnabled(false) { _ in }
        self.stopHeartbeats()
        if let error {
          completion?(error.localizedDescription)
        } else {
          completion?(nil)
        }
      }
    }
  }

  func takePicture(completion: @escaping (String?) -> Void) {
    INSCameraManager.shared().commandManager.takePicture(with: nil) { error, _ in
      completion(error?.localizedDescription)
    }
  }

  func startCapture(completion: @escaping (String?) -> Void) {
    INSCameraManager.shared().commandManager.startCapture(with: nil) { error in
      completion(error?.localizedDescription)
    }
  }

  func stopCapture(completion: @escaping (String?) -> Void) {
    INSCameraManager.shared().commandManager.stopCapture(with: nil) { error, _ in
      completion(error?.localizedDescription)
    }
  }

  func cameraStateSummary() -> [String: Int] {
    return [
      "socket": Int(INSCameraManager.socket().cameraState.rawValue),
      "usb": Int(INSCameraManager.usb().cameraState.rawValue),
      "external": Int(INSCameraManager.external().cameraState.rawValue)
    ]
  }

  func deviceDidConnected(_ device: INSBluetoothDevice) {
    if connectedBluetoothDevice?.identifierUUIDStringSafe ==
        device.identifierUUIDStringSafe {
      return
    }
    connectedBluetoothDevice = device
    emitEvent([
      "type": "bluetooth_connected",
      "identifier": device.identifierUUIDStringSafe,
      "name": device.name ?? "unknown"
    ])
  }

  func device(_ device: INSBluetoothDevice, didDisconnectWithError error: Error?) {
    if connectedBluetoothDevice?.identifierUUIDStringSafe == device.identifierUUIDStringSafe {
      connectedBluetoothDevice = nil
    }
    stopHeartbeats()
    var payload: [String: Any] = [
      "type": "bluetooth_disconnected",
      "identifier": device.identifierUUIDStringSafe
    ]
    if let error {
      payload["error"] = error.localizedDescription
    }
    emitEvent(payload)
  }

  func exporter2Manager(_ manager: INSExporter2Manager, progress: Float) {
    emitEvent([
      "type": "export_progress",
      "kind": exportKind ?? "video",
      "exportId": exportId ?? "",
      "progress": progress,
      "outputPath": exportOutputPath ?? ""
    ])
  }

  func exporter2Manager(_ manager: INSExporter2Manager, state: INSExporter2State, error: Error?) {
    let kind = exportKind ?? "video"
    if state == .complete {
      emitEvent([
        "type": "export_complete",
        "kind": kind,
        "exportId": exportId ?? "",
        "outputPath": exportOutputPath ?? ""
      ])
      finishExport(with: .success(exportOutputPath ?? ""))
    } else if state == .error || state == .cancel || state == .interrupt || state == .disconnect || state == .initError {
      let message = error?.localizedDescription ?? "export_failed"
      emitEvent([
        "type": "export_failed",
        "kind": kind,
        "exportId": exportId ?? "",
        "error": message
      ])
      finishExport(with: .failure(Insta360SdkError(message: message)))
    }
  }

  func exporter2Manager(_ manager: INSExporter2Manager, correctOffset: String, errorNum: Int32, totalNum: Int32, clipIndex: Int32, type: String) {
    // No-op: hook for diagnostics if needed.
  }

  private func attachPreviewPlayerIfNeeded() {
    guard let container = previewContainer else { return }
    if previewPlayer == nil {
      previewPlayer = INSCameraPreviewPlayer(frame: container.bounds, renderType: .sphericalPanoRender)
    }
    guard let previewPlayer else { return }
    let renderView = previewPlayer.renderView
    if renderView.superview !== container {
      container.subviews.forEach { $0.removeFromSuperview() }
      renderView.frame = container.bounds
      renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      container.addSubview(renderView)
    }
  }

  private func bluetoothCommandManager() -> INSAllBluetoothCommands? {
    guard let device = connectedBluetoothDevice else {
      return nil
    }
    return bluetoothManager.command(by: device)
  }

  private func setLiveViewEnabled(_ enabled: Bool, completion: @escaping (String?) -> Void) {
    let options = INSCameraOptions()
    options.appLiveviewStatus = enabled
    let types = [NSNumber(value: INSCameraOptionsType.appLiveViewStatus.rawValue)]
    INSCameraManager.socket().commandManager.setOptions(options, forTypes: types) { error, _ in
      completion(error?.localizedDescription)
    }
  }

  private func startHeartbeats() {
    guard heartbeatTimer == nil else { return }
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now(), repeating: 0.5)
    timer.setEventHandler {
      INSCameraManager.socket().commandManager.sendHeartbeats(with: nil)
    }
    timer.resume()
    heartbeatTimer = timer
  }

  private func makeWifiRequestOptions() -> INSCameraRequestOptions {
    let options = INSCameraRequestOptions()
    options.timeout = 12
    options.repeatCount = 1
    return options
  }

  private func stopHeartbeats() {
    heartbeatTimer?.cancel()
    heartbeatTimer = nil
  }

  private func emitEvent(_ payload: [String: Any]) {
    eventHandler?.emit(payload)
  }

  private func finishExport(with result: Result<String, Insta360SdkError>) {
    videoExporter?.shutDown()
    videoExporter = nil
    imageExporter = nil
    let completion = exportCompletion
    exportCompletion = nil
    exportOutputPath = nil
    exportId = nil
    exportKind = nil
    completion?(result)
  }

  private func applyExportOptions(_ options: [String: Any], to exporter: INSExportSimplify) {
    if let width = options["width"] as? NSNumber {
      exporter.width = Int32(width.intValue)
    }
    if let height = options["height"] as? NSNumber {
      exporter.height = Int32(height.intValue)
    }
    if let fps = options["fps"] as? NSNumber {
      exporter.fps = fps.doubleValue
    }
    if let bitrate = options["bitrate"] as? NSNumber {
      exporter.bitrate = bitrate.intValue
    }
    if let colorFusion = options["colorFusion"] as? Bool {
      exporter.colorFusion = colorFusion
    }
    if let colorPlus = options["colorPlus"] as? Bool {
      exporter.colorPlus = colorPlus
    }
    if let enableDenoise = options["enableDenoise"] as? Bool {
      exporter.enableDenoise = enableDenoise
    }
    if let stabMode = options["stabMode"] as? NSNumber,
       let mode = INSStabilizerStabMode(rawValue: stabMode.intValue) {
      exporter.stabMode = mode
    }
    if let protectType = options["protectType"] as? NSNumber {
      exporter.protectType = INSOffsetConvertOptions(rawValue: protectType.uintValue)
    }
  }

  private func applyExportOptions(_ options: [String: Any], to exporter: INSExportImageSimplify) {
    if let width = options["width"] as? NSNumber {
      exporter.width = Int32(width.intValue)
    }
    if let height = options["height"] as? NSNumber {
      exporter.height = Int32(height.intValue)
    }
    if let colorFusion = options["colorFusion"] as? Bool {
      exporter.colorFusion = colorFusion
    }
    if let colorPlus = options["colorPlus"] as? Bool {
      exporter.colorPlus = colorPlus
    }
    if let protectType = options["protectType"] as? NSNumber {
      exporter.protectType = INSOffsetConvertOptions(rawValue: protectType.uintValue)
    }
  }

  private func urlFromStringOrURI(_ value: String) -> URL? {
    if value.hasPrefix("file://"), let url = URL(string: value) {
      return url
    }
    if value.hasPrefix("/") {
      return URL(fileURLWithPath: value)
    }
    if let url = URL(string: value), url.scheme != nil {
      return url
    }
    return INSHTTPURLForResourceURI(value)
  }

  private func mapResources(_ resources: INSCameraResources?, storageType: INSStorageType) -> [[String: Any]] {
    var items: [INSCameraBaseFileInfo] = []
    if storageType.contains(.camera) {
      items.append(contentsOf: resources?.cameraResources ?? [])
    }
    let sdStorage = INSStorageType(rawValue: 0b0001)
    if storageType.contains(sdStorage) {
      items.append(contentsOf: resources?.sdResources ?? [])
    }
    if items.isEmpty {
      items = resources?.cameraResources ?? resources?.sdResources ?? []
    }
    return items.sorted { $0.uri > $1.uri }.map { info in
      var payload = info.toJSONDict() as? [String: Any] ?? [:]
      payload["uri"] = info.uri
      payload["storageType"] = Int(info.storageType.rawValue)
      if let video = info as? INSCameraVideoInfo {
        payload["fileSize"] = video.fileSize
        payload["totalTime"] = video.totalTime
      } else if let photo = info as? INSCameraPhotoInfo {
        if let hdrUris = photo.hdrUris {
          payload["hdrUris"] = hdrUris
        }
        if let burstUris = photo.burstUris {
          payload["burstUris"] = burstUris
        }
      }
      return payload
    }
  }

  private func defaultDocumentsSubdir(named name: String) -> URL {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    return documents.appendingPathComponent(name, isDirectory: true)
  }

  private func ensureDirectory(_ url: URL) -> Bool {
    do {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      return true
    } catch {
      return false
    }
  }

  private func timestampString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    return formatter.string(from: Date())
  }
}
#endif
