import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';
import '../../domain/auth_user.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this.repository}) : super(AuthState.initial());

  final AuthRepository repository;

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    final result = await repository.login(email: email, password: password);
    result.fold(
      (error) => emit(state.copyWith(status: AuthStatus.error, message: error.message)),
      (session) => emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
          token: session.token,
          message: null,
        ),
      ),
    );
  }

  void loginWithTestAccount() {
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: const AuthUser(
          id: 'test-user',
          email: 'test@local',
          fullName: 'Test User',
          role: 'admin',
        ),
        token: 'test-token',
        message: null,
      ),
    );
  }

  Future<void> signup({
    required String email,
    required String fullName,
    required String password,
    required String role,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    final result = await repository.signup(
      email: email,
      fullName: fullName,
      password: password,
      role: role,
    );
    result.fold(
      (error) => emit(state.copyWith(status: AuthStatus.error, message: error.message)),
      (session) => emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
          token: session.token,
          message: null,
        ),
      ),
    );
  }

  Future<String?> forgotPassword({required String email}) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    final result = await repository.forgotPassword(email: email);
    return result.fold(
      (error) {
        emit(state.copyWith(status: AuthStatus.error, message: error.message));
        return null;
      },
      (message) {
        emit(state.copyWith(status: AuthStatus.unauthenticated, message: message));
        return message;
      },
    );
  }

  Future<void> updateRole(String role) async {
    final token = state.token;
    if (token == null) {
      emit(state.copyWith(status: AuthStatus.error, message: 'Missing session token'));
      return;
    }
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    final result = await repository.updateRole(token: token, role: role);
    result.fold(
      (error) => emit(state.copyWith(status: AuthStatus.error, message: error.message)),
      (user) => emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: _mergeUser(user),
          message: 'Role updated',
        ),
      ),
    );
  }

  void logout() {
    emit(AuthState.initial());
  }

  AuthUser? _mergeUser(AuthUser user) {
    final current = state.user;
    if (current == null) {
      return user;
    }
    return current.copyWith(
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      id: user.id,
    );
  }
}
