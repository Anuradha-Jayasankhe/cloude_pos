import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/models.dart';
import '../../services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _authService.login(
        event.email,
        event.password,
        isPlatform: event.isPlatform,
      );

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError(_authService.lastActionError ?? 'Invalid credentials'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _authService.register(
        event.name,
        event.email,
        event.password,
        event.role,
      );

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Registration failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.logout();
    emit(AuthInitial());
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
          return;
        }
      }

      final cached = await _authService.getCachedCredentials();
      if (cached != null) {
        final user = await _authService.login(cached.email, cached.password);
        if (user != null) {
          emit(AuthAuthenticated(user));
          return;
        }
      }

      emit(AuthInitial());
    } catch (_) {
      emit(AuthInitial());
    }
  }
}
