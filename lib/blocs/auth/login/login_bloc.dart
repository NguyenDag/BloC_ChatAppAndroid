
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/blocs/auth/login/login_event.dart';
import 'package:myapp/blocs/auth/login/login_state.dart';
import 'package:myapp/services/login_service.dart';
import 'package:myapp/services/token_service.dart';

class LoginBloC extends Bloc<LoginEvent, LoginState> {
  LoginBloC() : super(LoginInitial()) {
    on<UsernameLoaded>(_onUsernameLoaded);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginErrorCleared>(_onLoginErrorCleared);
  }

  void _onUsernameLoaded(UsernameLoaded event, Emitter<LoginState> emit) async {
    final savedUsername = await TokenService.getUsername();
    if (savedUsername != null) {
      emit(UsernameLoadedState(username: savedUsername));
    }
  }

  void _onLoginSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    final error = await LoginService.loginAuth(event.username, event.password);

    if (error != null) {
      emit(LoginFailure(error: error));
    } else {
      emit(LoginSuccess());
    }
  }

  void _onLoginErrorCleared(
    LoginErrorCleared event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginInitial());
  }
}
