import 'package:equatable/equatable.dart';

import '../../domain/auth_user.dart';

enum AuthStatus {
  unauthenticated,
  authenticated,
  loading,
  error,
}

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.message,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? token;
  final String? message;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? token,
    String? message,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, user, token, message];

  factory AuthState.initial() => const AuthState(status: AuthStatus.unauthenticated);
}
