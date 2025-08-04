import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/blocs/chat/friends_list/friends_list_bloc.dart';
import 'package:myapp/blocs/chat/friends_list/friends_list_event.dart';
import 'package:myapp/blocs/chat/friends_list/friends_list_state.dart';
import 'package:myapp/constants/api_constants.dart';
import 'package:myapp/models/opp_model.dart';
import 'package:myapp/pages/online_chat.dart';

import '../constants/color_constants.dart';
import '../services/friend_service.dart';

late Size mq;

class FriendsList extends StatelessWidget {
  const FriendsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FriendsListBloc(),
      child: BlocListener<FriendsListBloc, FriendsListState>(
        listener: (context, state) {
          if (state is ChatOpened) {
            final friend = friendFromJson(state.friendData);
            final avatarUrl = state.friendData['avatarUrl'] ?? '';
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => OnlineChat(friend: friend, avatarUrl: avatarUrl),
              ),
            );
          }
        },
        child: const FriendsListView(),
      ),
    );
  }
}

class FriendsListView extends StatefulWidget {
  const FriendsListView({super.key});

  @override
  State<StatefulWidget> createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<FriendsListView> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> friendsList = [];
  List<Map<String, dynamic>> originalFriendsList = [];
  Map<String, dynamic>? currentUser;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar:
          false, //đảm bảo phần body không vẽ ra sau appbar để tránh xung đột màu
      // backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        // elevation: 0,
        title: Text(
          'Bkav Chat',
          style: TextStyle(
            color: ColorConstants.logoColor,
            fontSize: 24,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          //chứa widget nằm ở cuối( bên phải) của appBar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<FriendsListBloc>().add(LogoutRequested());
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Đăng xuất'),
                  ),
                ];
              },
              child: CircleAvatar(
                child: CircleAvatar(
                  backgroundImage:
                      (currentUser != null && currentUser!['Avatar'] != null)
                          ? NetworkImage(
                            ApiConstants.getUrl(currentUser!['Avatar']),
                          )
                          : const AssetImage('assets/images/no_avatar.jpg')
                              as ImageProvider,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.all(mq.width * .03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //thanh tìm kiếm
              Container(
                width: mq.width * .8,
                height: mq.height * .055,
                decoration: BoxDecoration(
                  color: Color(0xFFF3F6F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 12),
                  onChanged: (text) {
                    context.read<FriendsListBloc>().add(
                      SearchFriendChanged(query: text),
                    );
                  },
                  decoration: InputDecoration(
                    icon: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Icon(Icons.search, size: 35),
                    ),
                    border: InputBorder.none,
                    hintText: 'Tìm kiếm',
                    hintStyle: TextStyle(fontSize: 12),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: GestureDetector(
                      //bắt sự kiện khi người dùng click vào icon
                      onTap: () {
                        _searchController.clear();
                        context.read<FriendsListBloc>().add(ClearSearch());
                      },
                      child: Icon(Icons.close, size: 20),
                    ),
                  ),
                ),
              ),
              SizedBox(height: mq.height * .025),
              Center(
                child: const Text(
                  'Danh sách bạn bè',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: mq.height * .025),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<FriendsListBloc>().add(RefreshFriends());
                  },
                  child: BlocBuilder(
                    builder: (context, state) {
                      if (state is FriendsListLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else if (state is FriendsListLoaded) {
                        final friendsList = state.friends;
                        return ListView.builder(
                          itemCount: friendsList.length,
                          // physics: BouncingScrollPhysics(),//hiệu ứng cuộn 'giật nhẹ lại'
                          itemBuilder: (context, index) {
                            final f = friendsList[index];
                            String? content = f['Content'];

                            final filesJson =
                                f['Files'] as List<dynamic>? ?? [];
                            final List<FileModel> tempFiles =
                                filesJson
                                    .map(
                                      (e) => fileModelFromJson(
                                        e as Map<String, dynamic>,
                                      ),
                                    )
                                    .toList();

                            final imagesJson =
                                f['Images'] as List<dynamic>? ?? [];
                            final List<FileModel> tempImages =
                                imagesJson
                                    .map(
                                      (e) => fileModelFromJson(
                                        e as Map<String, dynamic>,
                                      ),
                                    )
                                    .toList();

                            if (tempFiles.isNotEmpty) {
                              content = 'Đã gửi file cho bạn!';
                            } else if (tempImages.isNotEmpty) {
                              content = 'Đã gửi ảnh cho bạn!';
                            } else if ((content == null || content == '') &&
                                tempFiles.isEmpty &&
                                tempImages.isEmpty) {
                              content = 'Hãy bắt đầu cuộc trò chuyện!';
                            }
                            final fullName = f['FullName'] ?? 'No Name';
                            final avatar =
                                (f['Avatar'] != null)
                                    ? ApiConstants.getUrl(f['Avatar'])
                                    : 'https://static2.yan.vn/YanNews/2167221/202102/facebook-cap-nhat-avatar-doi-voi-tai-khoan-khong-su-dung-anh-dai-dien-e4abd14d.jpg';
                            final isOnline = f['isOnline'];
                            final friendId = f['FriendID'];
                            final isSend = f['isSend'];
                            final username = f['Username'];
                            final localNickname = f['localNickname'];
                            final chatColor = f['chatColor'];

                            final Friend friend = Friend(
                              friendId,
                              fullName,
                              username,
                              isOnline ?? false,
                              isSend ?? 0,
                              content: content,
                              files: tempFiles,
                              images: tempImages,
                              localNickname: localNickname,
                              chatColor: chatColor,
                            );

                            return FriendTile(
                              avatarUrl: avatar,
                              friend: friend,
                            );
                          },
                        );
                      } else {
                        return Center(child: Text('Không có dữ liệu'));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FriendTile extends StatelessWidget {
  final String avatarUrl;
  final Friend friend;

  const FriendTile({super.key, required this.avatarUrl, required this.friend});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return OnlineChat(friend: friend, avatarUrl: avatarUrl);
            },
          ),
        );
      },
      leading: Stack(
        children: [
          CircleAvatar(backgroundImage: NetworkImage(avatarUrl), radius: 24),
          if (friend.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green,
                  // borderRadius: BorderRadius.circular(24.0),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Text(FriendService.getDisplayName(friend)),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Text(
          friend.content!,
          style:
              friend.isSend == 0
                  ? TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                  : TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
