package com.insta360.insta360_sdk

import android.app.Application
import android.content.Context
import android.graphics.Bitmap
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Handler
import android.os.Looper
import com.arashivision.sdkcamera.InstaCameraSDK
import com.arashivision.sdkcamera.camera.InstaCameraManager
import com.arashivision.sdkcamera.camera.callback.ICameraChangedCallback
import com.arashivision.sdkcamera.camera.callback.ICameraOperateCallback
import com.arashivision.sdkcamera.camera.callback.IPreviewStatusListener
import com.arashivision.sdkcamera.camera.callback.IScanBleListener
import com.arashivision.sdkcamera.camera.model.TemperatureLevel
import com.arashivision.sdkmedia.InstaMediaSDK
import com.arashivision.sdkmedia.player.capture.CaptureParamsBuilderV2
import com.arashivision.sdkmedia.work.WorkUtils
import com.arashivision.sdkmedia.work.WorkWrapper
import com.clj.fastble.data.BleDevice
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean

class Insta360SdkPlugin : FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ICameraChangedCallback,
    IPreviewStatusListener {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private var applicationContext: Context? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val cameraManager: InstaCameraManager = InstaCameraManager.getInstance()
    private val initialized = AtomicBoolean(false)

    private var pendingBleIdentifier: String? = null
    private val bleDevices: MutableMap<String, BleDevice> = LinkedHashMap()

    private var wifiNetworkCallback: ConnectivityManager.NetworkCallback? = null
    private var wifiNetwork: Network? = null

    private var pendingPreviewResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "insta360_sdk/methods")
        eventChannel = EventChannel(binding.binaryMessenger, "insta360_sdk/events")
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            "insta360_sdk/preview",
            Insta360PreviewFactory()
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        if (initialized.get()) {
            cameraManager.unregisterCameraChangedCallback(this)
        }
        applicationContext = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                ensureInitialized()
                result.success(null)
            }
            "connectWifi" -> {
                ensureInitialized()
                cameraManager.openCamera(InstaCameraManager.CONNECT_TYPE_WIFI)
                result.success(null)
            }
            "disconnectWifi" -> {
                cameraManager.closeCamera()
                unbindNetwork()
                result.success(null)
            }
            "connectUsb" -> {
                ensureInitialized()
                cameraManager.openCamera(InstaCameraManager.CONNECT_TYPE_USB)
                result.success(null)
            }
            "disconnectUsb" -> {
                cameraManager.closeCamera()
                result.success(null)
            }
            "connectExternal" -> {
                result.error("not_supported", "External connection is not supported on Android", null)
            }
            "disconnectExternal" -> {
                result.error("not_supported", "External connection is not supported on Android", null)
            }
            "startBluetoothScan" -> {
                ensureInitialized()
                cameraManager.setScanBleListener(scanBleListener)
                cameraManager.startBleScan()
                result.success(null)
            }
            "stopBluetoothScan" -> {
                cameraManager.stopBleScan()
                emit(mapOf("type" to "bluetooth_scan_stopped"))
                result.success(null)
            }
            "connectBluetoothDevice" -> {
                ensureInitialized()
                val identifier = call.argument<String>("identifier")
                if (identifier.isNullOrEmpty()) {
                    result.error("invalid_arguments", "Missing identifier", null)
                    return
                }
                val device = bleDevices[identifier]
                if (device == null) {
                    result.error("bluetooth_device_missing", "Unknown bluetooth device", null)
                    return
                }
                pendingBleIdentifier = identifier
                cameraManager.connectBle(device)
                result.success(null)
            }
            "disconnectBluetoothDevice" -> {
                cameraManager.closeCamera()
                result.success(null)
            }
            "openCameraWifi" -> {
                ensureInitialized()
                cameraManager.openCameraWifi(object : ICameraOperateCallback {
                    override fun onSuccessful() {
                        result.success(null)
                    }

                    override fun onFailed() {
                        result.error("wifi_open_failed", "open wifi failed", null)
                    }

                    override fun onCameraConnectError() {
                        result.error("wifi_open_failed", "camera not connected", null)
                    }
                })
            }
            "closeCameraWifi" -> {
                ensureInitialized()
                cameraManager.closeCameraWifi(object : ICameraOperateCallback {
                    override fun onSuccessful() {
                        result.success(null)
                    }

                    override fun onFailed() {
                        result.error("wifi_close_failed", "close wifi failed", null)
                    }

                    override fun onCameraConnectError() {
                        result.error("wifi_close_failed", "camera not connected", null)
                    }
                })
            }
            "resetCameraWifi" -> {
                ensureInitialized()
                val channel = call.argument<Int>("channel") ?: 0
                if (channel > 0) {
                    cameraManager.resetCameraWifi(channel, object : ICameraOperateCallback {
                        override fun onSuccessful() {
                            result.success(null)
                        }

                        override fun onFailed() {
                            result.error("wifi_reset_failed", "reset wifi failed", null)
                        }

                        override fun onCameraConnectError() {
                            result.error("wifi_reset_failed", "camera not connected", null)
                        }
                    })
                } else {
                    cameraManager.resetCameraWifi(object : ICameraOperateCallback {
                        override fun onSuccessful() {
                            result.success(null)
                        }

                        override fun onFailed() {
                            result.error("wifi_reset_failed", "reset wifi failed", null)
                        }

                        override fun onCameraConnectError() {
                            result.error("wifi_reset_failed", "camera not connected", null)
                        }
                    })
                }
            }
            "setWifiCountryCode" -> {
                ensureInitialized()
                val countryCode = call.argument<String>("countryCode") ?: ""
                if (countryCode.isEmpty()) {
                    result.error("invalid_arguments", "Missing countryCode", null)
                    return
                }
                cameraManager.setWifiCountry(countryCode, object : ICameraOperateCallback {
                    override fun onSuccessful() {
                        result.success(null)
                    }

                    override fun onFailed() {
                        result.error("wifi_country_failed", "set wifi country failed", null)
                    }

                    override fun onCameraConnectError() {
                        result.error("wifi_country_failed", "camera not connected", null)
                    }
                })
            }
            "getWifiInfo" -> {
                ensureInitialized()
                val info = cameraManager.wifiInfo
                val infoAny: Any = info
                val payload = mapOf(
                    "ssid" to (readString(infoAny, "getSsid") ?: ""),
                    "password" to (readString(infoAny, "getPwd") ?: readString(infoAny, "getPassword") ?: ""),
                    "state" to (readInt(infoAny, "getState") ?: 0),
                    "isBusy" to (readBoolean(infoAny, "isBusy") ?: readBoolean(infoAny, "getBusy") ?: false),
                    "channel" to (readInt(infoAny, "getChannel") ?: 0)
                )
                result.success(payload)
            }
            "getWifiChannelList" -> {
                ensureInitialized()
                cameraManager.fetchWifiChannel { countryCode, channel ->
                    val listAny = cameraManager.wifiChannelList
                    val list24 = readIntList(listAny, "getChannelList24g")
                    val list5 = readIntList(listAny, "getChannelList5g")
                    val payload = mapOf(
                        "countryCode" to (countryCode ?: ""),
                        "currentChannel" to channel,
                        "channelList24g" to list24,
                        "channelList5g" to list5
                    )
                    result.success(payload)
                }
            }
            "setWifiProvisioningEnabled" -> {
                result.error("not_supported", "Wi-Fi provisioning is not supported on Android", null)
            }
            "startWifiScan" -> {
                result.error("not_supported", "Wi-Fi scan is not supported on Android", null)
            }
            "connectToWifi" -> {
                ensureInitialized()
                val ssid = call.argument<String>("ssid") ?: ""
                val password = call.argument<String>("password") ?: ""
                if (ssid.isEmpty()) {
                    result.error("invalid_arguments", "Missing ssid", null)
                    return
                }
                joinWifi(ssid, password, result)
            }
            "joinCameraWifi" -> {
                ensureInitialized()
                val ssid = call.argument<String>("ssid") ?: ""
                val password = call.argument<String>("password") ?: ""
                if (ssid.isEmpty()) {
                    result.error("invalid_arguments", "Missing ssid", null)
                    return
                }
                joinWifi(ssid, password, result)
            }
            "getConnectedWifiList" -> {
                result.success(
                    mapOf(
                        "list" to emptyList<Map<String, Any?>>(),
                        "current" to emptyMap<String, Any?>()
                    )
                )
            }
            "startPreview" -> {
                ensureInitialized()
                startPreview(result)
            }
            "stopPreview" -> {
                stopPreview(result)
            }
            "takePicture" -> {
                ensureInitialized()
                cameraManager.startNormalCapture()
                result.success(null)
            }
            "startCapture" -> {
                ensureInitialized()
                cameraManager.startNormalRecord()
                result.success(null)
            }
            "stopCapture" -> {
                ensureInitialized()
                cameraManager.stopNormalRecord()
                result.success(null)
            }
            "getCameraState" -> {
                val connectedType = cameraManager.cameraConnectedType
                val socketState = if (connectedType == InstaCameraManager.CONNECT_TYPE_WIFI) 3 else 5
                val usbState = if (connectedType == InstaCameraManager.CONNECT_TYPE_USB) 3 else 5
                result.success(
                    mapOf(
                        "socket" to socketState,
                        "usb" to usbState,
                        "external" to 5
                    )
                )
            }
            "listMedia" -> {
                ensureInitialized()
                val payload = listMedia()
                result.success(payload)
            }
            "fetchPhoto" -> {
                ensureInitialized()
                val uri = call.argument<String>("uri") ?: ""
                if (uri.isEmpty()) {
                    result.error("invalid_arguments", "Missing uri", null)
                    return
                }
                val bytes = fetchPhotoBytes(uri)
                result.success(bytes)
            }
            "downloadResource" -> {
                ensureInitialized()
                val uri = call.argument<String>("uri") ?: ""
                val targetPath = call.argument<String>("targetPath")
                if (uri.isEmpty()) {
                    result.error("invalid_arguments", "Missing uri", null)
                    return
                }
                downloadResource(uri, targetPath, result)
            }
            "setPlaybackSources" -> {
                result.error("not_supported", "Playback is not supported on Android", null)
            }
            "playbackPlay" -> {
                result.error("not_supported", "Playback is not supported on Android", null)
            }
            "playbackPause" -> {
                result.error("not_supported", "Playback is not supported on Android", null)
            }
            "playbackStop" -> {
                result.error("not_supported", "Playback is not supported on Android", null)
            }
            "exportVideo" -> {
                result.error("not_supported", "Export is not supported on Android", null)
            }
            "exportImage" -> {
                result.error("not_supported", "Export is not supported on Android", null)
            }
            else -> result.notImplemented()
        }
    }

    private fun ensureInitialized() {
        val context = applicationContext ?: return
        val app = (context.applicationContext as? Application) ?: return
        if (initialized.compareAndSet(false, true)) {
            InstaCameraSDK.init(app)
            InstaMediaSDK.init(app)
            cameraManager.registerCameraChangedCallback(this)
        }
    }

    private fun joinWifi(ssid: String, password: String, result: MethodChannel.Result) {
        val context = applicationContext ?: run {
            result.error("wifi_join_failed", "Missing application context", null)
            return
        }
        val connectivityManager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val wifiManager =
            context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (!wifiManager.isWifiEnabled) {
            result.error("wifi_join_failed", "Wi-Fi is disabled", null)
            return
        }

        val specifierBuilder = WifiNetworkSpecifier.Builder().setSsid(ssid)
        if (password.isNotEmpty()) {
            specifierBuilder.setWpa2Passphrase(password)
        }
        val specifier = specifierBuilder.build()
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .setNetworkSpecifier(specifier)
            .build()

        val timeout = Runnable {
            wifiNetworkCallback?.let { connectivityManager.unregisterNetworkCallback(it) }
            wifiNetworkCallback = null
            result.error("wifi_join_failed", "timeout", null)
        }

        val callback = object : ConnectivityManager.NetworkCallback() {
            private var completed = false

            override fun onAvailable(network: Network) {
                if (completed) return
                completed = true
                wifiNetwork = network
                wifiNetworkCallback = this
                connectivityManager.bindProcessToNetwork(network)
                cameraManager.setNetIdToCamera(network.networkHandle)
                mainHandler.removeCallbacks(timeout)
                emit(
                    mapOf(
                        "type" to "wifi_connection_result",
                        "result" to mapOf(
                            "code" to 0,
                            "ssid" to ssid
                        )
                    )
                )
                result.success(null)
            }

            override fun onUnavailable() {
                if (completed) return
                completed = true
                mainHandler.removeCallbacks(timeout)
                result.error("wifi_join_failed", "unavailable", null)
            }
        }

        wifiNetworkCallback?.let { connectivityManager.unregisterNetworkCallback(it) }
        wifiNetworkCallback = callback
        mainHandler.postDelayed(timeout, 15000)
        connectivityManager.requestNetwork(request, callback)
    }

    private fun unbindNetwork() {
        val context = applicationContext ?: return
        val connectivityManager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        connectivityManager.bindProcessToNetwork(null)
        wifiNetwork?.let { network ->
            wifiNetworkCallback?.let { callback ->
                connectivityManager.unregisterNetworkCallback(callback)
            }
        }
        wifiNetwork = null
        wifiNetworkCallback = null
    }

    private fun startPreview(result: MethodChannel.Result) {
        val view = PreviewHolder.current()
        if (view == null) {
            result.error("preview_start_failed", "Preview view not ready", null)
            return
        }
        if (cameraManager.previewStatus == InstaCameraManager.PREVIEW_STATUS_OPENED) {
            result.success(null)
            return
        }
        pendingPreviewResult = result
        cameraManager.setPreviewStatusChangedListener(this)
        view.post {
            val params = CaptureParamsBuilderV2().apply {
                width = view.width
                height = view.height
            }
            view.prepare(params)
            view.play()
            view.keepScreenOn = true
            cameraManager.startPreviewStream(InstaCameraManager.PREVIEW_TYPE_NORMAL)
        }
    }

    private fun stopPreview(result: MethodChannel.Result) {
        cameraManager.closePreviewStream()
        cameraManager.setPreviewStatusChangedListener(null)
        result.success(null)
    }

    private fun listMedia(): Map<String, Any?> {
        val works: List<WorkWrapper> = WorkUtils.getAllCameraWorks()
        val photos = ArrayList<Map<String, Any?>>()
        val videos = ArrayList<Map<String, Any?>>()
        for (work in works) {
            val uri = work.urls.firstOrNull() ?: work.allUrls.firstOrNull().orEmpty()
            val name = if (uri.contains("/")) uri.substringAfterLast('/') else uri
            val payload = mutableMapOf<String, Any?>(
                "uri" to uri,
                "name" to name,
                "size" to 0,
                "storageType" to 0
            )
            if (work.isVideo) {
                payload["totalTime"] = work.durationInMs
                videos.add(payload)
            } else {
                photos.add(payload)
            }
        }
        return mapOf(
            "photos" to photos,
            "videos" to videos
        )
    }

    private fun fetchPhotoBytes(uri: String): ByteArray {
        val works = WorkUtils.getAllCameraWorks()
        val match = works.firstOrNull { work ->
            work.urls.contains(uri) || work.allUrls.contains(uri)
        } ?: return ByteArray(0)
        val bitmap = match.loadThumbnail() ?: return ByteArray(0)
        val output = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, output)
        return output.toByteArray()
    }

    private fun downloadResource(uri: String, targetPath: String?, result: MethodChannel.Result) {
        val context = applicationContext
        if (context == null) {
            result.error("download_failed", "Missing application context", null)
            return
        }
        Thread {
            try {
                bindCameraNetworkIfNeeded()
                val outputPath = if (!targetPath.isNullOrEmpty()) {
                    if (targetPath.startsWith("file://")) {
                        targetPath.removePrefix("file://")
                    } else {
                        targetPath
                    }
                } else {
                    val dir = File(context.getExternalFilesDir(null), "insta360_downloads")
                    if (!dir.exists()) dir.mkdirs()
                    val fileName = uri.substringAfterLast('/')
                    File(dir, fileName).absolutePath
                }

                val url = URL(uri)
                val connection = url.openConnection() as HttpURLConnection
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                connection.connect()

                val total = connection.contentLengthLong
                val input = connection.inputStream
                val outputFile = File(outputPath)
                outputFile.parentFile?.mkdirs()
                val output = FileOutputStream(outputFile)
                val buffer = ByteArray(8 * 1024)
                var downloaded = 0L
                var count = input.read(buffer)
                var lastProgress = 0
                while (count != -1) {
                    output.write(buffer, 0, count)
                    downloaded += count
                    if (total > 0) {
                        val progress = ((downloaded.toDouble() / total.toDouble()) * 100).toInt()
                        if (progress != lastProgress) {
                            lastProgress = progress
                            emit(
                                mapOf(
                                    "type" to "download_progress",
                                    "uri" to uri,
                                    "progress" to (downloaded.toDouble() / total.toDouble())
                                )
                            )
                        }
                    }
                    count = input.read(buffer)
                }
                output.flush()
                output.close()
                input.close()
                emit(
                    mapOf(
                        "type" to "download_complete",
                        "uri" to uri,
                        "path" to outputFile.absolutePath
                    )
                )
                mainHandler.post { result.success(outputFile.absolutePath) }
            } catch (ex: Exception) {
                emit(
                    mapOf(
                        "type" to "download_failed",
                        "uri" to uri,
                        "error" to (ex.message ?: "download failed")
                    )
                )
                mainHandler.post { result.error("download_failed", ex.message, null) }
            }
        }.start()
    }

    private val scanBleListener = object : IScanBleListener {
        override fun onScanStartSuccess() {
            emit(mapOf("type" to "bluetooth_scan_started"))
        }

        override fun onScanStartFail() {
            emit(mapOf("type" to "bluetooth_scan_stopped"))
        }

        override fun onScanning(bleDevice: BleDevice) {
            val identifier = bleDevice.mac ?: bleDevice.device?.address ?: ""
            if (identifier.isEmpty()) return
            bleDevices[identifier] = bleDevice
            emit(
                mapOf(
                    "type" to "bluetooth_device_found",
                    "identifier" to identifier,
                    "name" to (bleDevice.name ?: "unknown"),
                    "rssi" to bleDevice.rssi
                )
            )
        }

        override fun onScanFinish(list: List<BleDevice>) {
            emit(mapOf("type" to "bluetooth_scan_stopped"))
        }
    }

    override fun onCameraSDCardStateChanged(enabled: Boolean) {
        emitNotification("camera_sdcard_state", mapOf("enabled" to enabled.toString()))
    }

    override fun onCameraBatteryLow() {
        emitNotification("camera_battery_low", emptyMap())
    }

    override fun onCameraBatteryUpdate(batteryLevel: Int, isCharging: Boolean) {
        emitNotification(
            "camera_battery_update",
            mapOf("battery" to batteryLevel.toString(), "charging" to isCharging.toString())
        )
    }

    override fun onCameraStorageChanged(freeSpace: Long, totalSpace: Long) {
        emitNotification(
            "camera_storage_update",
            mapOf("free" to freeSpace.toString(), "total" to totalSpace.toString())
        )
    }

    override fun onCameraTemperatureChanged(tempLevel: TemperatureLevel?) {
        emitNotification("camera_temperature", mapOf("level" to tempLevel?.name.orEmpty()))
    }

    override fun onCameraStatusChanged(enabled: Boolean, connectType: Int) {
        when (connectType) {
            InstaCameraManager.CONNECT_TYPE_BLE -> {
                val identifier = pendingBleIdentifier
                if (enabled) {
                    emit(
                        mapOf(
                            "type" to "bluetooth_connected",
                            "identifier" to identifier,
                            "name" to (bleDevices[identifier]?.name ?: "unknown")
                        )
                    )
                } else {
                    emit(
                        mapOf(
                            "type" to "bluetooth_disconnected",
                            "identifier" to identifier
                        )
                    )
                }
            }
            InstaCameraManager.CONNECT_TYPE_WIFI -> {
                emitCameraState("socket", enabled)
            }
            InstaCameraManager.CONNECT_TYPE_USB -> {
                emitCameraState("usb", enabled)
            }
        }
    }

    override fun onCameraConnectError(errorCode: Int) {
        val identifier = pendingBleIdentifier
        if (!identifier.isNullOrEmpty()) {
            emit(
                mapOf(
                    "type" to "bluetooth_connect_failed",
                    "identifier" to identifier,
                    "error" to errorCode.toString()
                )
            )
        }
    }

    override fun onOpening() {
        emitNotification("preview_opening", emptyMap())
    }

    override fun onOpened() {
        emitNotification("preview_opened", emptyMap())
        pendingPreviewResult?.success(null)
        pendingPreviewResult = null
    }

    override fun onIdle() {
        emitNotification("preview_idle", emptyMap())
    }

    override fun onError() {
        pendingPreviewResult?.error("preview_start_failed", "preview error", null)
        pendingPreviewResult = null
    }

    private fun emitCameraState(source: String, enabled: Boolean) {
        val stateName = if (enabled) "connected" else "no_connection"
        val stateValue = if (enabled) 3 else 5
        emit(
            mapOf(
                "type" to "camera_state",
                "source" to source,
                "state" to stateValue,
                "stateName" to stateName
            )
        )
    }

    private fun emitNotification(name: String, userInfo: Map<String, String>) {
        emit(
            mapOf(
                "type" to "notification",
                "name" to name,
                "userInfo" to userInfo
            )
        )
    }

    private fun emit(payload: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(payload)
        }
    }

    private fun bindCameraNetworkIfNeeded() {
        val context = applicationContext ?: return
        val connectivityManager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val wifiManager =
            context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val network = getCurrentWifiNetwork(connectivityManager, wifiManager) ?: return
        connectivityManager.bindProcessToNetwork(network)
        cameraManager.setNetIdToCamera(network.networkHandle)
    }

    private fun getCurrentWifiNetwork(
        connectivityManager: ConnectivityManager,
        wifiManager: WifiManager,
    ): Network? {
        val wifiIp = parseIpAddress(wifiManager.connectionInfo?.ipAddress ?: 0)
        connectivityManager.allNetworks.forEach { network ->
            val caps = connectivityManager.getNetworkCapabilities(network) ?: return@forEach
            if (!caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return@forEach
            val info = caps.transportInfo
            if (info is android.net.wifi.WifiInfo) {
                val networkIp = parseIpAddress(info.ipAddress)
                if (networkIp == wifiIp) {
                    return network
                }
            }
        }
        return null
    }

    private fun parseIpAddress(ip: Int): String {
        return ((ip and 0xFF).toString() + "." +
            ((ip ushr 8) and 0xFF) + "." +
            ((ip ushr 16) and 0xFF) + "." +
            ((ip ushr 24) and 0xFF))
    }

    private fun readString(target: Any, getter: String): String? {
        return try {
            val method = target.javaClass.getMethod(getter)
            method.invoke(target) as? String
        } catch (_: Exception) {
            null
        }
    }

    private fun readInt(target: Any, getter: String): Int? {
        return try {
            val method = target.javaClass.getMethod(getter)
            val value = method.invoke(target)
            when (value) {
                is Number -> value.toInt()
                else -> null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun readBoolean(target: Any, getter: String): Boolean? {
        return try {
            val method = target.javaClass.getMethod(getter)
            val value = method.invoke(target)
            value as? Boolean
        } catch (_: Exception) {
            null
        }
    }

    private fun readIntList(target: Any?, getter: String): List<Int> {
        if (target == null) return emptyList()
        return try {
            val method = target.javaClass.getMethod(getter)
            val value = method.invoke(target)
            when (value) {
                is List<*> -> value.mapNotNull { (it as? Number)?.toInt() }
                else -> emptyList()
            }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
