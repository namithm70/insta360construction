import 'package:shared_preferences/shared_preferences.dart';

class WifiCredentialsStore {
  static const String _ssidKey = 'insta360_camera_wifi_ssid';
  static const String _passwordKey = 'insta360_camera_wifi_password';

  Future<void> save({required String ssid, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ssidKey, ssid);
    await prefs.setString(_passwordKey, password);
  }

  Future<WifiCredentials?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final ssid = prefs.getString(_ssidKey);
    if (ssid == null || ssid.trim().isEmpty) {
      return null;
    }
    final password = prefs.getString(_passwordKey) ?? '';
    return WifiCredentials(ssid: ssid, password: password);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ssidKey);
    await prefs.remove(_passwordKey);
  }
}

class WifiCredentials {
  const WifiCredentials({required this.ssid, required this.password});

  final String ssid;
  final String password;
}
