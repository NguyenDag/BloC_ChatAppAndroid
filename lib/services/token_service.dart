import 'package:shared_preferences/shared_preferences.dart';

class TokenService{
  static const _tokenKey = 'token';
  static const _loginTime = 'login_time';
  static const _username = 'username';

  static Future<void> saveToken(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_username, username);
    await prefs.setString(_loginTime, DateTime.now().toIso8601String());
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_username);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_loginTime);
  }
}