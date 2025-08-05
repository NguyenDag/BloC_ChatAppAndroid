import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myapp/services/token_service.dart';
import 'package:myapp/services/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../models/user_info.dart';

class LoginService {
  static Future<bool> isLoggedInWithinAWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final loginTimeStr = prefs.getString('login_time');

    if (token == null || loginTimeStr == null) return false;

    final loginTime = DateTime.parse(loginTimeStr);
    final now = DateTime.now();
    final diff = now.difference(loginTime);

    return diff.inDays <= 7;
  }

  static Future<String?> loginAuth(String username, String password) async {
    if (username.isEmpty) {
      return 'Tên đăng nhập không được để trống';
    } else if (password.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    String endPoint = '/auth/login';
    final uri = Uri.parse(ApiConstants.getUrl(endPoint));

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Username': username, 'Password': password}),
      );
      final json = jsonDecode(response.body);

      if (json['status'] == 1) {
        final data = json['data'];
        final fullName = data['FullName'];
        final avatar = data['Avatar'];
        final token = data['token'];

        TokenService.saveToken(token, username);

        final newUserInfo = UserInfo(
          username: username,
          fullName: fullName,
          avatar: avatar,
        );
        await UserStorage.saveUserInfo(newUserInfo);

        return null;
      } else {
        return json['message'] ?? 'Đăng nhập thất bại!';
      }
    } catch (e) {
      return 'Lỗi kết nối tới máy chủ!';
    }
  }
}
