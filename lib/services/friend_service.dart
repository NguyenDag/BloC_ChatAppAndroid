import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/constants/api_constants.dart';
import 'package:myapp/services/token_service.dart';
import 'package:realm/realm.dart';

import '../models/opp_model.dart';

class FriendService {
  static Future<List<Map<String, dynamic>>> fetchFriends() async {
    final token = await TokenService.getToken();
    if (token == null) {
      return [];
    }

    final endPoint = '/message/list-friend';
    final url = Uri.parse(ApiConstants.getUrl(endPoint));

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final status = body['status'];
      if (status != null && status == 1) {
        List<dynamic> rawList = body['data'];

        List<Map<String, dynamic>> processedList =
            rawList.map<Map<String, dynamic>>((item) {
              final content = item['content'];
              final files = item['files'];
              final images = item['images'];

              // Xử lý nội dung hiển thị
              if (content == null ||
                  (content is String && content.trim().isEmpty)) {
                if (files != null && files is List && files.isNotEmpty) {
                  item['content'] = 'Đã gửi files';
                } else if (images != null &&
                    images is List &&
                    images.isNotEmpty) {
                  item['content'] = 'Đã gửi ảnh';
                } else {
                  item['content'] = 'Hãy bắt đầu cuộc trò chuyện!';
                }
              }
              return item.cast<String, dynamic>();
            }).toList();

        return processedList;
      } else {
        // print('Lỗi API: ${body['message']}');
      }
    } else {
      // print('Lỗi server: ${response.statusCode}');
    }
    return [];
  }

  static List<Map<String, dynamic>> filterFriends(
    List<Map<String, dynamic>> originalList,
    String query,
  ) {
    return originalList.where((friend) {
      final name = friend['FullName']?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();
  }

  static void setChatColor(Realm realm, Friend f, int colorValue) {
    final friend = realm.find<Friend>(f.friendId);
    if (friend != null) {
      realm.write(() {
        friend.chatColor = colorValue;
      });
    }
  }

  static Color getChatColor(Friend friend) {
    return friend.chatColor != null ? Color(friend.chatColor!) : Colors.white;
  }

  static void setLocalNickname(Realm realm, Friend f, String newNickname) {
    final friend = realm.find<Friend>(f.friendId);
    if (friend != null) {
      realm.write(() {
        friend.localNickname = newNickname;
      });
    }
  }

  static String getDisplayName(Friend friend) {
    return friend.localNickname?.isNotEmpty == true
        ? friend.localNickname!
        : friend.fullName;
  }
}
