import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:myapp/services/token_service.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/api_constants.dart';
import '../models/user_info.dart';

class UserStorage {
  static Future<String> _getFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/users_info.json';
  }

  static Future<List<UserInfo>> readUsersInfo() async {
    final path = await _getFilePath();
    final file = File(path);

    if (!file.existsSync()) return [];

    final content = await file.readAsString();
    final jsonData = json.decode(content);
    return (jsonData as List).map((e) => UserInfo.fromJson(e)).toList();
  }

  static Future<void> saveUserInfo(UserInfo user) async {
    final users = await readUsersInfo();
    final exists = users.any((u) => u.username == user.username);

    if (!exists) {
      users.add(user);

      final path = await _getFilePath();
      final file = File(path);

      final jsonString = json.encode(users.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonString);
    }
  }

  static void printAllUsers() async {
    final users = await UserStorage.readUsersInfo();
    for (var user in users) {
      print('👤 ${user.username} - ${user.fullName} - ${user.avatar}');
    }
  }

  static Future<Map<String, dynamic>?> fetchUserInfo() async{
    final token = await TokenService.getToken();
    if (token == null) {
      return null;
    }
    final endPoint = '/user/info';
    final url = Uri.parse(ApiConstants.getUrl(endPoint));

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if(response.statusCode == 200){
      final body = jsonDecode(response.body);
      final status = body['status'];
      if(status != null && status == 1){
        // List<dynamic> rawList = body['data'];
        return body['data'];
      }else{
        // print('Lỗi API: ${body['message']}');
      }
    }else{
      // print('Lỗi server: ${response.statusCode}');
    }
    return null;
  }
}