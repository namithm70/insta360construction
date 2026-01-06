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
