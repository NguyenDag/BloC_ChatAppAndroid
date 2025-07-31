import 'package:realm/realm.dart';

import '../models/opp_model.dart';

class RealmFriendService {
  static late Realm _realm;

  static void init() {
    if (true) {
      final config = Configuration.local([
        Friend.schema,
        FileModel.schema,
        UserFriendList.schema,
      ]);
      _realm = Realm(config);
    }
  }

  static Realm get realm {
    init();
    return _realm;
  }

  static List<Friend> getAllLocalFriends(String? username) {
    init();
    final userList = _realm.find<UserFriendList>(username);
    return userList?.friends.toList() ?? [];
  }

  static void saveFriendsToLocal(
    List<Map<String, dynamic>> jsonList,
    String? username,
  ) {
    if (username == null) return;
    init();
    final friends = jsonList.map((e) => friendFromJson(e)).toList();

    _realm.write(() {
      for (final newFriend in friends) {
        // Đảm bảo FileModel được add trước với update:true (tránh lỗi trùng key)
        for (var file in newFriend.files) {
          _realm.add(file, update: true);
        }
        for (var image in newFriend.images) {
          _realm.add(image, update: true);
        }
        final existingFriend = _realm.find<Friend>(newFriend.friendId);

        if (existingFriend != null) {
          // Cập nhật thông tin từ API, giữ lại nickname, màu, v.v.
          existingFriend.fullName = newFriend.fullName;
          existingFriend.username = newFriend.username;
          existingFriend.isOnline = newFriend.isOnline;
          existingFriend.isSend = newFriend.isSend;
          existingFriend.content = newFriend.content;

          existingFriend.files
            ..clear()
            ..addAll(newFriend.files);

          existingFriend.images
            ..clear()
            ..addAll(newFriend.images);
        } else {
          _realm.add(newFriend);
        }
      }

      final friendIds = friends.map((f) => f.friendId).toList();
      final attachedFriends =
          friendIds.map((id) => _realm.find<Friend>(id)!).toList();

      var friendListOfUser = _realm.find<UserFriendList>(username);
      if (friendListOfUser != null) {
        friendListOfUser.friends
          ..clear()
          ..addAll(attachedFriends);
      } else {
        friendListOfUser = UserFriendList(username, friends: attachedFriends);
        _realm.add(friendListOfUser);
      }
    });
  }

  static void clearAllLocalFriends(String username) {
    init();
    final userList = _realm.find<UserFriendList>(username);
    if (userList != null) {
      _realm.write(() {
        _realm.deleteMany(userList.friends);
        _realm.delete(userList);
      });
    }
  }
}
