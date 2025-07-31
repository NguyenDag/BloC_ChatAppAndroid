import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/services/friend_service.dart';
import 'package:myapp/services/realm_friend_service.dart';
import 'package:path/path.dart' as path;
import 'package:myapp/services/token_service.dart';

import '../constants/api_constants.dart';
import '../models/opp_model.dart';

class MessageService {
  static Future<List<Message>> fetchMessages(String friendId) async {
    final token = await TokenService.getToken();
    if (token == null) {
      return [];
    }

    final endPoint = '/message/get-message?FriendID=$friendId';
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
        final List<dynamic> rawList = body['data'];
        return rawList
            .map(
              (item) => messageFromJson(item as Map<String, dynamic>, friendId),
            )
            .toList();
      } else {
        print('Lỗi API: ${body['message']}');
      }
    } else {
      print('Lỗi server: ${response.statusCode}');
    }
    return [];
  }

  static Future<Message?> sendMessage({
    required String friendId,
    String? content,
    List<File>? imageFiles,
    List<File>? otherFiles,
  }) async {
    final token = await TokenService.getToken();
    if (token == null) {
      return null;
    }

    final endPoint = '/message/send-message';
    final url = Uri.parse(ApiConstants.getUrl(endPoint));
    var request = http.MultipartRequest('POST', url);

    request.headers['ContentType'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['FriendID'] = friendId;

    if (content != null && content.isNotEmpty) {
      request.fields['Content'] = content;
    }

    /*
    //=========xử lý lưu vào đúng đường dẫn ảnh và file
    // Gửi ảnh
    if (imageFiles != null) {
      for (var image in imageFiles) {
        var stream = http.ByteStream(image.openRead());
        var length = await image.length();
        var multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: path.basename(image.path),
        );
        request.files.add(multipartFile);
      }
    }

    // Gửi file
    if (otherFiles != null) {
      for (var file in otherFiles) {
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();
        var multipartFile = http.MultipartFile(
          'files',
          stream,
          length,
          filename: path.basename(file.path),
        );
        request.files.add(multipartFile);
      }
    }
    */

    final allFiles = [...?imageFiles, ...?otherFiles];

    //xử lý gộp chung vào "files"
    for (var file in allFiles) {
      var stream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        'files',
        stream,
        length,
        filename: path.basename(file.path),
      );
      request.files.add(multipartFile);
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResp = jsonDecode(respStr);

        if (jsonResp['status'] == 1) {
          return messageFromJson(jsonResp['data'], friendId);
        } else {
          print('Send failed: ${jsonResp['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception sending message: $e');
    }

    return null;
  }

  static bool isImageUrl(String? url) {
    if (url == null) return false;
    final lower = url.toLowerCase();

    final allowedExtensions = [
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.bmp',
      '.webp',
    ];
    return allowedExtensions.any((ext) => lower.endsWith(ext));
  }

  static bool isFileUrl(String? url) {
    if (url == null) return false;
    final lower = url.toLowerCase();

    final allowedExtensions = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
      '.zip',
      '.rar',
      '.7z',
      '.mp3',
      '.mp4',
      '.mov',
      '.avi',
    ];

    return allowedExtensions.any((ext) => lower.endsWith(ext));
  }

  static String getContentType(String? url, String? content) {
    if (isImageUrl(url)) return 'image';
    if (isFileUrl(url)) return 'file';
    if (content != null && content.isNotEmpty) return 'text';
    return 'unknown';
  }

  static void showRenameDialog(BuildContext context, Friend friend) {
    final controller_nickname = TextEditingController(
      text: friend.localNickname ?? friend.fullName,
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Đổi biệt danh'),
            content: TextField(
              controller: controller_nickname,
              decoration: const InputDecoration(hintText: 'Nhập biệt danh mới'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  final newName = controller_nickname.text.trim();
                  if (newName.isNotEmpty && newName != friend.fullName) {
                    FriendService.setLocalNickname(
                      RealmFriendService.realm,
                      friend,
                      newName,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Lưu'),
              ),
            ],
          ),
    );
  }

  static void showRecolorDialog(BuildContext context, Friend friend) {
    final List<Color> colorOptions = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.grey,
      Colors.white,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn màu đoạn chat'),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                colorOptions.map((color) {
                  return GestureDetector(
                    onTap: () {
                      // Gọi service để lưu màu mới
                      FriendService.setChatColor(
                        RealmFriendService.realm,
                        friend,
                        color.value,
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                    ),
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }
}
