// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:flutter/foundation.dart';
// import 'package:realm/realm.dart';
//
// import '../models/message.dart';
//
// class WebSocketService extends ChangeNotifier {
//   WebSocketChannel? _channel;
//   StreamSubscription? _subscription;
//   final String _baseUrl;
//   final String _userId;
//   String? _token;
//   late Realm _realm;
//
//   // Connection state
//   bool _isConnected = false;
//   bool get isConnected => _isConnected;
//
//   // Message streams
//   final StreamController<Message> _messageController = StreamController<Message>.broadcast();
//   Stream<Message> get messageStream => _messageController.stream;
//
//   // Typing indicators
//   final StreamController<TypingEvent> _typingController = StreamController<TypingEvent>.broadcast();
//   Stream<TypingEvent> get typingStream => _typingController.stream;
//
//   WebSocketService({
//     required String baseUrl,
//     required String userId,
//     required Realm realm,
//     String? token,
//   }) : _baseUrl = baseUrl, _userId = userId, _token = token, _realm = realm;
//
//   // Kết nối WebSocket
//   Future<void> connectWebSocket() async {
//     try {
//       final uri = Uri.parse('$_baseUrl/ws?userId=$_userId&token=$_token');
//       _channel = IOWebSocketChannel.connect(uri);
//
//       _subscription = _channel!.stream.listen(
//         _handleMessage,
//         onError: _handleError,
//         onDone: _handleDisconnection,
//       );
//
//       _isConnected = true;
//       notifyListeners();
//
//       // Gửi ping để duy trì kết nối
//       _startHeartbeat();
//
//     } catch (e) {
//       print('WebSocket connection error: $e');
//       _handleError(e);
//     }
//   }
//
//   // Xử lý tin nhắn nhận được
//   void _handleMessage(dynamic data) {
//     try {
//       final Map<String, dynamic> json = jsonDecode(data);
//       final String type = json['type'] ?? '';
//
//       switch (type) {
//         case 'message':
//           final messageData = json['data'] as Map<String, dynamic>;
//           final friendId = messageData['senderId'] ?? messageData['friendId'] ?? '';
//
//           // Tạo Message từ JSON và lưu vào Realm
//           final message = messageFromJson(messageData, friendId);
//           _saveMessageToRealm(message);
//           _messageController.add(message);
//           break;
//
//         case 'typing':
//           final typingEvent = TypingEvent.fromJson(json['data']);
//           _typingController.add(typingEvent);
//           break;
//
//         case 'user_online':
//           _handleUserStatus(json['data'], true);
//           break;
//
//         case 'user_offline':
//           _handleUserStatus(json['data'], false);
//           break;
//
//         case 'message_delivered':
//           _handleMessageDelivered(json['data']);
//           break;
//
//         case 'message_read':
//           _handleMessageRead(json['data']);
//           break;
//
//         case 'pong':
//           break;
//       }
//     } catch (e) {
//       print('Error parsing message: $e');
//     }
//   }
//
//   // Lưu tin nhắn vào Realm
//   void _saveMessageToRealm(Message message) {
//     try {
//       _realm.write(() {
//         _realm.add(message, update: true);
//       });
//     } catch (e) {
//       print('Error saving message to Realm: $e');
//     }
//   }
//
//   // Gửi tin nhắn text
//   void sendTextMessage(String content, String friendId) {
//     if (!_isConnected || _channel == null) return;
//
//     // Tạo message local
//     final message = Message(
//       DateTime.now().millisecondsSinceEpoch.toString(),
//       friendId,
//       1, // isSend = 1 (đã gửi)
//       DateTime.now(),
//       0, // MessageType = 0 (text)
//       content: content,
//       files: <FileModel>[],
//       images: <FileModel>[],
//     );
//
//     // Lưu vào Realm
//     _saveMessageToRealm(message);
//
//     // Gửi qua WebSocket
//     final messageData = {
//       'type': 'message',
//       'data': {
//         'id': message.id,
//         'friendId': friendId,
//         'Content': content,
//         'MessageType': 0,
//         'CreatedAt': DateTime.now().toIso8601String(),
//         'Files': [],
//         'Images': [],
//       }
//     };
//
//     _channel!.sink.add(jsonEncode(messageData));
//     _messageController.add(message);
//   }
//
//   // Gửi tin nhắn với file
//   void sendFileMessage(List<FileModel> files, String friendId, {int messageType = 1}) {
//     if (!_isConnected || _channel == null) return;
//
//     final message = Message(
//       DateTime.now().millisecondsSinceEpoch.toString(),
//       friendId,
//       1,
//       DateTime.now(),
//       messageType,
//       content: null,
//       files: messageType == 1 ? files : <FileModel>[],
//       images: messageType == 2 ? files : <FileModel>[],
//     );
//
//     _saveMessageToRealm(message);
//
//     final messageData = {
//       'type': 'message',
//       'data': {
//         'id': message.id,
//         'friendId': friendId,
//         'Content': null,
//         'MessageType': messageType,
//         'CreatedAt': DateTime.now().toIso8601String(),
//         'Files': messageType == 1 ? files.map(fileModelToJson).toList() : [],
//         'Images': messageType == 2 ? files.map(fileModelToJson).toList() : [],
//       }
//     };
//
//     _channel!.sink.add(jsonEncode(messageData));
//     _messageController.add(message);
//   }
//
//   // Gửi tin nhắn với hình ảnh
//   void sendImageMessage(List<FileModel> images, String friendId) {
//     sendFileMessage(images, friendId, messageType: 2);
//   }
//
//   // Gửi trạng thái đang gõ
//   void sendTyping(String friendId, bool isTyping) {
//     if (!_isConnected || _channel == null) return;
//
//     final typing = {
//       'type': 'typing',
//       'data': {
//         'friendId': friendId,
//         'isTyping': isTyping,
//         'userId': _userId,
//       }
//     };
//
//     _channel!.sink.add(jsonEncode(typing));
//   }
//
//   // Tham gia room chat
//   void joinRoom(String roomId) {
//     if (!_isConnected || _channel == null) return;
//
//     final joinRoom = {
//       'type': 'join_room',
//       'data': {
//         'roomId': roomId,
//         'userId': _userId,
//       }
//     };
//
//     _channel!.sink.add(jsonEncode(joinRoom));
//   }
//
//   // Rời khỏi room chat
//   void leaveRoom(String roomId) {
//     if (!_isConnected || _channel == null) return;
//
//     final leaveRoom = {
//       'type': 'leave_room',
//       'data': {
//         'roomId': roomId,
//         'userId': _userId,
//       }
//     };
//
//     _channel!.sink.add(jsonEncode(leaveRoom));
//   }
//
//   // Đánh dấu tin nhắn đã đọc
//   void markMessageAsRead(String messageId, String friendId) {
//     if (!_isConnected || _channel == null) return;
//
//     final readMessage = {
//       'type': 'message_read',
//       'data': {
//         'messageId': messageId,
//         'friendId': friendId,
//         'userId': _userId,
//       }
//     };
//
//     _channel!.sink.add(jsonEncode(readMessage));
//   }
//
//   // Xử lý tin nhắn đã giao
//   void _handleMessageDelivered(Map<String, dynamic> data) {
//     final messageId = data['messageId'] as String?;
//     if (messageId != null) {
//       try {
//         final message = _realm.find<Message>(messageId);
//         if (message != null) {
//           _realm.write(() {
//             // Có thể thêm field deliveryStatus vào model
//             // message.deliveryStatus = 1; // delivered
//           });
//         }
//       } catch (e) {
//         print('Error updating message delivery status: $e');
//       }
//     }
//   }
//
//   // Xử lý tin nhắn đã đọc
//   void _handleMessageRead(Map<String, dynamic> data) {
//     final messageId = data['messageId'] as String?;
//     if (messageId != null) {
//       try {
//         final message = _realm.find<Message>(messageId);
//         if (message != null) {
//           _realm.write(() {
//             // Có thể thêm field readStatus vào model
//             // message.readStatus = 1; // read
//           });
//         }
//       } catch (e) {
//         print('Error updating message read status: $e');
//       }
//     }
//   }
//
//   // Lấy tin nhắn từ Realm
//   RealmResults<Message> getMessagesWithFriend(String friendId) {
//     return _realm.query<Message>('friendId == \$0 SORT(createdAt ASC)', [friendId]);
//   }
//
//   // Lấy tin nhắn gần đây nhất với từng friend
//   List<Message> getLatestMessagesForEachFriend() {
//     final allMessages = _realm.all<Message>();
//     final Map<String, Message> latestMessages = {};
//
//     for (final message in allMessages) {
//       final friendId = message.friendId;
//       if (!latestMessages.containsKey(friendId) ||
//           message.createdAt.isAfter(latestMessages[friendId]!.createdAt)) {
//         latestMessages[friendId] = message;
//       }
//     }
//
//     final result = latestMessages.values.toList();
//     result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//     return result;
//   }
//
//   // Xóa tin nhắn
//   void deleteMessage(String messageId) {
//     try {
//       final message = _realm.find<Message>(messageId);
//       if (message != null) {
//         _realm.write(() {
//           _realm.delete(message);
//         });
//
//         // Gửi thông báo xóa tin nhắn qua WebSocket
//         if (_isConnected && _channel != null) {
//           final deleteData = {
//             'type': 'delete_message',
//             'data': {
//               'messageId': messageId,
//               'userId': _userId,
//             }
//           };
//           _channel!.sink.add(jsonEncode(deleteData));
//         }
//       }
//     } catch (e) {
//       print('Error deleting message: $e');
//     }
//   }
//
//   // Tìm kiếm tin nhắn
//   RealmResults<Message> searchMessages(String query, {String? friendId}) {
//     if (friendId != null) {
//       return _realm.query<Message>(
//           'friendId == \$0 AND content CONTAINS[c] \$1 SORT(createdAt DESC)',
//           [friendId, query]
//       );
//     } else {
//       return _realm.query<Message>(
//           'content CONTAINS[c] \$0 SORT(createdAt DESC)',
//           [query]
//       );
//     }
//   }
//
//   // Heartbeat để duy trì kết nối
//   Timer? _heartbeatTimer;
//   void _startHeartbeat() {
//     _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
//       if (_isConnected && _channel != null) {
//         _channel!.sink.add(jsonEncode({'type': 'ping'}));
//       }
//     });
//   }
//
//   // Xử lý lỗi
//   void _handleError(dynamic error) {
//     print('WebSocket error: $error');
//     _isConnected = false;
//     notifyListeners();
//
//     // Thử kết nối lại sau 5 giây
//     Timer(Duration(seconds: 5), () {
//       if (!_isConnected) {
//         connectWebSocket();
//       }
//     });
//   }
//
//   // Xử lý ngắt kết nối
//   void _handleDisconnection() {
//     print('WebSocket disconnected');
//     _isConnected = false;
//     notifyListeners();
//
//     // Auto reconnect
//     Timer(Duration(seconds: 3), () {
//       if (!_isConnected) {
//         connectWebSocket();
//       }
//     });
//   }
//
//   // Xử lý trạng thái user
//   void _handleUserStatus(Map<String, dynamic> data, bool isOnline) {
//     print('User ${data['userId']} is ${isOnline ? 'online' : 'offline'}');
//   }
//
//   // Đóng kết nối
//   void disconnect() {
//     _heartbeatTimer?.cancel();
//     _subscription?.cancel();
//     _channel?.sink.close();
//     _isConnected = false;
//     notifyListeners();
//   }
//
//   @override
//   void dispose() {
//     disconnect();
//     _messageController.close();
//     _typingController.close();
//     super.dispose();
//   }
// }
//
// // Model cho typing event
// class TypingEvent {
//   final String userId;
//   final String userName;
//   final bool isTyping;
//   final DateTime timestamp;
//
//   TypingEvent({
//     required this.userId,
//     required this.userName,
//     required this.isTyping,
//     required this.timestamp,
//   });
//
//   factory TypingEvent.fromJson(Map<String, dynamic> json) {
//     return TypingEvent(
//       userId: json['userId'] ?? json['friendId'] ?? '',
//       userName: json['userName'] ?? '',
//       isTyping: json['isTyping'] ?? false,
//       timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
//     );
//   }
// }