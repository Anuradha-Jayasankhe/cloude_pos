part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool isPlatform;

  const AuthLoginRequested(this.email, this.password, {this.isPlatform = false});

  @override
  List<Object> get props => [email, password, isPlatform];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;

  const AuthRegisterRequested(this.name, this.email, this.password, this.role);

  @override
  List<Object> get props => [name, email, password, role];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckStatusRequested extends AuthEvent {}