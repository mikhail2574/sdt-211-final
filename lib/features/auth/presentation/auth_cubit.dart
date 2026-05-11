import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../domain/user.dart';

enum AuthStatus { checking, unauthenticated, loading, authenticated, failure }

class AuthState {
  const AuthState({required this.status, this.user, this.errorMessage});

  const AuthState.checking() : this(status: AuthStatus.checking);

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState copyWith({AuthStatus? status, User? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState.checking());

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    try {
      final user = await _repository.restoreSession();
      if (user == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      } else {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      }
    } catch (error) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: '$error'));
    }
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _repository.login(email: email, password: password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (error) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: '$error'));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
