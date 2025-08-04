import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/material.dart';
import 'package:myapp/constants/app_constants.dart';
import 'package:myapp/constants/color_constants.dart';
import 'package:myapp/pages/login_page.dart';

import '../blocs/auth/register/register_bloc.dart';
import '../blocs/auth/register/register_event.dart';
import '../blocs/auth/register/register_state.dart';
// import 'package:path_provider/path_provider.dart'; //liên quan xử lý file

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterBloc(),
      child: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }
        },
        child: const RegisterView(),
      ),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 16,
      fontFamily: 'Roboto',
      color: ColorConstants.blackColor,
    );

    const inputDecoration = InputDecoration(border: UnderlineInputBorder());

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
          },
        ),
        centerTitle: true,
        backgroundColor: ColorConstants.whiteColor,
        // backgroundColor: Colors.red,
        foregroundColor: ColorConstants.blackColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 26),
              const Center(
                child: Text(
                  AppConstants.registerTitle,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(height: 25),
              Text('Tên hiển thị', style: labelStyle),
              TextFormField(
                controller: _fullNameController,
                decoration: inputDecoration,
              ),

              const SizedBox(height: 25),
              Text('Tài khoản', style: labelStyle),
              TextFormField(
                controller: _usernameController,
                decoration: inputDecoration,
              ),

              const SizedBox(height: 25),
              Text('Mật khẩu', style: labelStyle),
              TextFormField(
                controller: _passwordController,
                obscureText: true, //input hiển thị dưới dạng ẩn
                decoration: inputDecoration,
              ),

              const SizedBox(height: 25),
              Text('Nhập lại mật khẩu', style: labelStyle),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: inputDecoration,
              ),

              const Spacer(),

              BlocBuilder<RegisterBloc, RegisterState>(
                builder: (context, state) {
                  if (state is RegisterFailure) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(),
                        child: Text(
                          state.error,
                          style: TextStyle(
                            color: ColorConstants.errorTextColor,
                            fontSize: 16,
                            fontFamily: 'Roboto',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),

              Spacer(),

              BlocBuilder<RegisterBloc, RegisterState>(
                builder: (context, state) {
                  final isLoading = state is RegisterLoading;
                  return Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  context.read<RegisterBloc>().add(
                                    RegisterSubmitted(
                                      fullName: _fullNameController.text.trim(),
                                      username: _usernameController.text.trim(),
                                      password: _passwordController.text,
                                      confirmPassword:
                                          _confirmPasswordController.text,
                                    ),
                                  );
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child:
                            isLoading
                                ? CircularProgressIndicator(
                                  color: ColorConstants.whiteColor,
                                )
                                : const Text(
                                  AppConstants.registerTitle,
                                  style: TextStyle(
                                    color: ColorConstants.whiteColor,
                                    fontFamily: 'Roboto',
                                    fontSize: 16,
                                  ),
                                ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
