import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable{
  const LoginState();

  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState{}

class LoginLoading extends LoginState{}

class LoginFailure extends LoginState {
  final String error;

  const LoginFailure({required this.error});

  @override
  List<Object> get props => [error];
}

class UsernameLoadedState extends LoginState{
  final String username;

  const UsernameLoadedState({required this.username});

  @override
  List<Object> get props => [username];
}

class LoginSuccess extends LoginState{}
