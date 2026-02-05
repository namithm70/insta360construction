class AppConfig {
  static const String backendBaseUrl = 'https://insta360-backend.onrender.com';
  static const bool debugBypassAuth =
      bool.fromEnvironment('DEBUG_BYPASS_AUTH', defaultValue: true);
}
