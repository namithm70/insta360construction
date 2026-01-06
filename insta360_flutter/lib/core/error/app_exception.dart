class AppException implements Exception {
  AppException(
    this.message, {
    this.statusCode,
    this.details,
  });

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() {
    final code = statusCode != null ? ' (code: $statusCode)' : '';
    return 'AppException: $message$code';
  }
}
