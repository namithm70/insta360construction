import '../../../core/error/result.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';

abstract class AuthRepository {
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthSession>> signup({
    required String email,
    required String fullName,
    required String password,
    required String role,
  });

  Future<Result<String>> forgotPassword({required String email});

  Future<Result<AuthUser>> updateRole({
    required String token,
    required String role,
  });
}
