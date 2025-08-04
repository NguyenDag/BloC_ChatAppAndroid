import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object> get props => [];
}

class RegisterSubmitted extends RegisterEvent {
  final String fullName;
  final String username;
  final String password;
  final String confirmPassword;

  const RegisterSubmitted({required this.fullName, required this.username, required this.password, required this.confirmPassword});

  @override
  List<Object> get props => [fullName, username, password, confirmPassword];
}

class RegisterReset extends RegisterEvent {}