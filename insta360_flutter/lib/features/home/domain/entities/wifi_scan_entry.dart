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
