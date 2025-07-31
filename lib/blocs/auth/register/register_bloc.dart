import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/blocs/auth/register/register_event.dart';
import 'package:myapp/blocs/auth/register/register_state.dart';

import '../../../services/register_service.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  // RegisterBloc(super.initialState);
  RegisterBloc() : super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<RegisterReset>(_onRegisterReset);
  }

  void _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    final error = await RegisterService.registerAuth(
      event.fullName,
      event.username,
      event.password,
      event.confirmPassword,
    );

    if (error != null) {
      emit(RegisterFailure(error: error));
    } else {
      emit(RegisterSuccess());
    }
  }

  void _onRegisterReset(
    RegisterReset event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterInitial());
  }
}
