import 'package:realm/realm.dart';

import '../models/opp_model.dart';

class RealmMessageService {
  static Realm? _realm;
  static bool _isInitialized = false;

  /// Khởi tạo Realm database
  static void init() {
    if (_isInitialized && _realm != null && !_realm!.isClosed) {
      return;
    }

    try {
      final config = Configuration.local([Message.schema, FileModel.schema]);
      _realm = Realm(config);
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Realm: $e');
    }
  }

  static void _ensureInitialized() {
    if (!_isInitialized || _realm == null || _realm!.isClosed) {
      init();
    }
  }

  static List<Message> getAllMessages() {
    try {
      _ensureInitialized();
      return _realm!.all<Message>().toList();
    } catch (e) {
      throw Exception('Fail to get all messages: $e');
    }
  }

  static List<Message> getMessagesForFriend(String friendId) {
    try {
      _ensureInitialized();

      if (friendId.isEmpty) {
        return [];
      }

      final messages =
          _realm!.query<Message>("friendId == \$0", [friendId]).toList();
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return messages;
    } catch (e) {
      throw Exception('Fail to get message for friend $friendId: $e');
    }
  }

  static Future<void> saveMessagesToLocal(
    String friendId,
    List<Map<String, dynamic>> jsonList,
  ) async {
    try {
      _ensureInitialized();

      if (friendId.isEmpty || jsonList.isEmpty) {
        return;
      }

      final messages =
          jsonList
              .map((json) => messageFromJson(json, friendId))
              .cast<Message>()
              .toList();

      if (messages.isEmpty) {
        return;
      }

      _realm!.write(() {
        for (var message in messages) {
          _realm!.add(message, update: true);
        }
      });
    } catch (e) {
      throw Exception('Failed to save messages to local: $e');
    }
  }

  /// Lưu một tin nhắn đơn lẻ
  static Future<void> saveMessage(Message message) async {
    try {
      _ensureInitialized();

      _realm!.write(() {
        _realm!.add(message, update: true);
      });
    } catch (e) {
      throw Exception('Failed to save message: $e');
    }
  }

  /// Xóa tất cả tin nhắn của một friend
  static Future<void> deleteMessagesForFriend(String friendId) async {
    try {
      _ensureInitialized();

      if (friendId.isEmpty) {
        return;
      }

      final messages = _realm!.query<Message>("friendId == \$0", [friendId]);

      _realm!.write(() {
        _realm!.deleteMany(messages);
      });
    } catch (e) {
      throw Exception('Failed to delete messages for friend $friendId: $e');
    }
  }

  static Future<void> clearAllMessages() async {
    try {
      _ensureInitialized();

      _realm!.write(() {
        _realm!.deleteAll<Message>();
      });
    } catch (e) {
      throw Exception('Failed to clear all messages: $e');
    }
  }

  static int getMessageCount() {
    try {
      _ensureInitialized();
      return _realm!.all<Message>().length;
    } catch (e) {
      throw Exception('Failed to get message count: $e');
    }
  }

  static int getMessageCountForFriend(String friendId) {
    try {
      _ensureInitialized();

      if (friendId.isEmpty) {
        return 0;
      }

      return _realm!.query<Message>("friendId == \$0", [friendId]).length;
    } catch (e) {
      throw Exception('Failed to get message count for friend $friendId: $e');
    }
  }

  /// Lấy tin nhắn mới nhất của một friend
  static Message? getLatestMessageForFriend(String friendId) {
    try {
      _ensureInitialized();

      if (friendId.isEmpty) {
        return null;
      }

      final messages =
          _realm!.query<Message>("friendId == \$0", [friendId]).toList();

      if (messages.isEmpty) {
        return null;
      }

      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return messages.first;
    } catch (e) {
      throw Exception('Failed to get latest message for friend $friendId: $e');
    }
  }

  /// Tìm kiếm tin nhắn theo nội dung
  static List<Message> searchMessages(String searchText) {
    try {
      _ensureInitialized();

      if (searchText.isEmpty) {
        return [];
      }

      final messages =
          _realm!.query<Message>("content CONTAINS[c] \$0", [
            searchText,
          ]).toList();

      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return messages;
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  /// Đóng Realm connection
  static void dispose() {
    if (_realm != null && !_realm!.isClosed) {
      _realm!.close();
      _realm = null;
      _isInitialized = false;
    }
  }

  /// Kiểm tra trạng thái Realm
  static bool get isInitialized =>
      _isInitialized && _realm != null && !_realm!.isClosed;
}
