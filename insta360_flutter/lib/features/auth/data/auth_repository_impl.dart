import 'package:dartz/dartz.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final result = await apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    return result.map(AuthSession.fromJson);
  }

  @override
  Future<Result<AuthSession>> signup({
    required String email,
    required String fullName,
    required String password,
    required String role,
  }) async {
    final result = await apiClient.post(
      '/auth/signup',
      body: {
        'email': email,
        'full_name': fullName,
        'password': password,
        'role': role,
      },
    );
    return result.map(AuthSession.fromJson);
  }

  @override
  Future<Result<String>> forgotPassword({required String email}) async {
    final result = await apiClient.post(
      '/auth/forgot',
      body: {
        'email': email,
      },
    );
    return result.map((json) => json['message']?.toString() ?? 'Request sent');
  }

  @override
  Future<Result<AuthUser>> updateRole({
    required String token,
    required String role,
  }) async {
    if (token.isEmpty) {
      return left(AppException('Missing auth token'));
    }
    final result = await apiClient.patch(
      '/users/me/role',
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        'role': role,
      },
    );
    return result.map(AuthUser.fromJson);
  }
}
