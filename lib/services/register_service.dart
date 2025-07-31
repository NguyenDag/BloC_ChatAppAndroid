import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myapp/services/user_storage.dart';

import '../constants/api_constants.dart';
import '../models/user_info.dart';

class RegisterService{

//confirm username input is exits or not
  static bool isFormatUsername(String username) => username.trim().contains(' ');

//confirm pass is true or not
  static bool isPasswordMismatch(String password, String confirmPassword) {
    return password != confirmPassword;
  }

  static Future<String?> registerAuth(
      String fullName,
      String username,
      String password,
      String confirmPassword,
      ) async {
    if (fullName.trim().isEmpty ||
        username.trim().isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return 'Vui lòng điền đầy đủ thông tin!';
    } else if (isFormatUsername(username)) {
      return 'Tài khoản không được chứa dấu cách!';
    } else if (isPasswordMismatch(password, confirmPassword)) {
      return 'Mật khẩu không khớp!';
    }
    String endPoint = '/auth/register';
    final uri = Uri.parse(ApiConstants.getUrl(endPoint));

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'FullName': fullName,
          'Username': username,
          'Password': password,
        }),
      );

      final json = jsonDecode(response.body);
      // if (json['id'] == 102) {
      if(response.statusCode == 200){
        final newUserInfo = UserInfo(username: username, fullName: fullName, avatar: null);
        await UserStorage.saveUserInfo(newUserInfo);
        return null;
      } else {
        return json['message'] ?? 'Đăng ký thất bại!';
      }
    } catch (e) {
      return 'Lỗi kết nối tới máy chủ!';
    }
  }
}