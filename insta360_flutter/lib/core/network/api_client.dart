import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

import '../error/app_exception.dart';
import '../error/result.dart';

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<Result<Map<String, dynamic>>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    try {
      final response = await _client.get(uri, headers: headers);
      return _handleJson(response);
    } catch (error) {
      return left(AppException('Network request failed', details: error));
    }
  }

  Future<Result<Map<String, dynamic>>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client.post(
        uri,
        headers: _withJson(headers),
        body: body == null ? null : jsonEncode(body),
      );
      return _handleJson(response);
    } catch (error) {
      return left(AppException('Network request failed', details: error));
    }
  }

  Future<Result<Map<String, dynamic>>> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client.patch(
        uri,
        headers: _withJson(headers),
        body: body == null ? null : jsonEncode(body),
      );
      return _handleJson(response);
    } catch (error) {
      return left(AppException('Network request failed', details: error));
    }
  }

  Map<String, String> _withJson(Map<String, String>? headers) {
    return {
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
  }

  Result<Map<String, dynamic>> _handleJson(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return right(data);
      }
      return left(
        AppException(
          data['message']?.toString() ?? 'Request failed',
          statusCode: response.statusCode,
          details: data,
        ),
      );
    } catch (error) {
      return left(
        AppException('Invalid server response',
            statusCode: response.statusCode, details: error),
      );
    }
  }
}
