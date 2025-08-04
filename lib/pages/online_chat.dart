import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/opp_model.dart';
import 'package:myapp/pages/friendslist_page.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/message_service.dart';
import 'package:saver_gallery/saver_gallery.dart';

import '../constants/api_constants.dart';
import '../services/file_service.dart';
import '../services/friend_service.dart';
import '../services/realm_message_service.dart';

late Size mq;

class OnlineChat extends StatefulWidget {
  final Friend friend;
  final String avatarUrl;

  const OnlineChat({super.key, required this.friend, required this.avatarUrl});

  @override
  State<StatefulWidget> createState() {
    return MyWidget();
  }
}

class MyWidget extends State<OnlineChat> {
  final ScrollController _scrollController = ScrollController();

  // File? _pickedImage;

  List<File> _pickedImages = [];
  List<File> _pickedFiles = [];

  final ImagePicker _imagePicker = ImagePicker();
  bool _showEmoji = false;
  final TextEditingController _emojiController = TextEditingController();
  bool isLoading = false;
  List<Message> messages = [];

  Future<void> loadMessage() async {
    if (!mounted) return;

    // Hiển thị loading indicator
    setState(() {
      isLoading = true;
    });

    try {
      final offlineMessages = RealmMessageService.getMessagesForFriend(
        widget.friend.friendId,
      );

      if (!mounted) return;

      if (offlineMessages.isNotEmpty) {
        setState(() {
          messages = offlineMessages;
          isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      try {
        final apiMessages = await MessageService.fetchMessages(
          widget.friend.friendId,
        );

        if (!mounted) return;

        await RealmMessageService.saveMessagesToLocal(
          widget.friend.friendId,
          apiMessages.map((m) => m.messageToJson()).toList(),
        );

        setState(() {
          messages = apiMessages;
          isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } catch (apiError) {
        // print('Không thể gọi API, sử dụng dữ liệu offline. Error: $apiError');

        if (!mounted) return;

        if (messages.isEmpty && offlineMessages.isEmpty) {
          setState(() {
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }

        _showOfflineMessage();
      }
    } catch (realmError) {
      // print('Lỗi khi load tin nhắn từ Realm: $realmError');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        messages = []; // Hoặc giữ nguyên messages hiện tại
      });

      // Hiển thị dialog lỗi nếu cần
      _showErrorDialog('Có lỗi xảy ra khi tải tin nhắn');
    }
  }

  // Helper method để hiển thị thông báo offline
  void _showOfflineMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang sử dụng dữ liệu offline'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Helper method để hiển thị dialog lỗi
  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Lỗi'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  loadMessage(); // Retry
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
    );
  }

  // void _scrollToBottom() {
  //   _scrollController.animateTo(
  //     _scrollController.position.maxScrollExtent,
  //     duration: Duration(milliseconds: 300),
  //     curve: Curves.easeOut,
  //   );
  // }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // loadOfflineMessages();
    loadMessage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: BackButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => FriendsList()),
              (Route<dynamic> route) => false,
            );
          },
        ),

        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.avatarUrl),
                  radius: 24,
                ),
                if (widget.friend.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        border: Border.all(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FriendService.getDisplayName(widget.friend),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    widget.friend.isOnline ? 'Trực tuyến' : 'Offline',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w100,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'nickname') {
                MessageService.showRenameDialog(context, widget.friend);
              } else if (value == 'color') {
                MessageService.showRecolorDialog(context, widget.friend);
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'nickname',
                    child: Text('Đổi biệt danh'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'color',
                    child: Text('Đổi màu sắc'),
                  ),
                ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: FriendService.getChatColor(widget.friend),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                // physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final prevMsg = index > 0 ? messages[index - 1] : null;

                  final currentDate = formatDateGroup(msg.createdAt);
                  final prevDate =
                      prevMsg != null ? formatDateGroup(prevMsg.createdAt) : '';

                  bool showDateHeader = currentDate != prevDate;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showDateHeader)
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF8F8FB),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Text(
                                currentDate,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ContentMessage(
                        msg: messages[index],
                        index: index,
                        name: FriendService.getDisplayName(widget.friend),
                        messages: messages,
                        avatarUrl: widget.avatarUrl,
                        isOnline: widget.friend.isOnline,
                      ),
                    ],
                  );
                },
              ),
            ),
            Divider(height: 1), //kẻ đường chỉ ngang

            if (_pickedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _pickedImages[index],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _pickedImages.removeAt(index);
                              });
                            },
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(
                        context,
                      ).unfocus(); //Ẩn bàn phím nếu đang mở
                      // showEmojiKeyboard = !showEmojiKeyboard;
                      setState(() {
                        _showEmoji = !_showEmoji;
                      });
                    },
                    child: Image.asset(
                      'assets/images/emoji_icon.png',
                      width: 20,
                      height: 20,
                    ),
                  ),

                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: null,
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F6F6),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: TextField(
                        controller: _emojiController,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          hintText: 'Nhập tin nhắn...',
                          hintStyle: TextStyle(fontSize: 12),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.send),
                            color: Colors.blue,
                            onPressed: () async {
                              final hasText =
                                  _emojiController.text.trim().isNotEmpty;
                              final hasImage = _pickedImages.isNotEmpty;
                              final hasFiles = _pickedFiles.isNotEmpty;

                              if (!hasText && !hasImage && !hasFiles) return;

                              final newMsg = await MessageService.sendMessage(
                                friendId: widget.friend.friendId,
                                content: _emojiController.text.trim(),
                                imageFiles: hasImage ? _pickedImages : null,
                                otherFiles: hasFiles ? _pickedFiles : null,
                              );

                              if (newMsg != null) {
                                setState(() {
                                  messages.add(newMsg);
                                  _emojiController.clear();
                                  _pickedImages.clear(); // reset sau khi gửi
                                  _pickedFiles.clear(); // reset sau khi gửi
                                });

                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _scrollToBottom();
                                });
                              }
                            },
                          ),
                          suffixIconColor: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(allowMultiple: true);
                      if (result != null) {
                        setState(() {
                          _pickedFiles =
                              result.paths.map((p) => File(p!)).toList();
                        });
                      }
                    },
                    child: Image.asset(
                      'assets/images/attach.png',
                      width: 20,
                      height: 20,
                    ),
                  ),

                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final List<XFile> images =
                          await _imagePicker.pickMultiImage();
                      if (images.isNotEmpty) {
                        setState(() {
                          _pickedImages =
                              images.map((x) => File(x.path)).toList();
                        });
                      }
                    },
                    child: Image.asset(
                      'assets/images/image.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ],
              ),
            ),

            //Emoji picker
            Offstage(
              offstage: !_showEmoji,
              child: SizedBox(
                height: _showEmoji ? 250 : 0,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _emojiController.text += emoji.emoji;
                  },
                  config: Config(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDateGroup(DateTime date) {
    final now = DateTime.now();
    DateTime timeNow = MessageJson.formatDate(now);
    DateTime timeDate = MessageJson.formatDate(date);
    final difference = timeNow.difference(timeDate).inDays;

    if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}

class ContentMessage extends StatelessWidget {
  final Message msg;
  final int index;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final List<Message> messages;

  const ContentMessage({
    super.key,
    required this.msg,
    required this.index,
    required this.name,
    required this.avatarUrl,
    required this.messages,
    required this.isOnline,
  });

  bool get _showAvatar =>
      index == 0 ||
      !(messages[index - 1].messageType == msg.messageType &&
          msg.messageType == 0);

  bool get _showTime =>
      index == messages.length - 1 ||
      !(messages[index + 1].messageType == msg.messageType) ||
      !(MessageJson.formatDate(messages[index + 1].createdAt) ==
          MessageJson.formatDate(msg.createdAt));

  @override
  Widget build(BuildContext context) {
    if (msg.messageType == 1) {
      return _buildSenderMessage();
    }
    return _buildReceiverMessage(name, avatarUrl, isOnline);
  }

  Widget _buildSenderMessage() {
    final Widget senderMessageBody;

    if (msg.images.isNotEmpty) {
      senderMessageBody = _ImageMessages(
        images: msg.images,
        createdAt: msg.createdAt,
        showTime: _showTime,
        messageType: msg.messageType,
      );
    } else if (msg.files.isNotEmpty) {
      if (MessageService.isImageUrl(msg.files[0].url)) {
        senderMessageBody = _ImageMessages(
          images: msg.files,
          createdAt: msg.createdAt,
          showTime: _showTime,
          messageType: msg.messageType,
        );
      } else {
        senderMessageBody = _FileMessages(
          files: msg.files,
          createdAt: msg.createdAt,
          showTime: _showTime,
          messageType: msg.messageType,
        );
      }
    } else {
      senderMessageBody = _TextMessage(
        content: msg.content ?? '',
        createdAt: msg.createdAt,
        showTime: _showTime,
        showAvatar: _showAvatar,
        messageType: msg.messageType,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        margin: EdgeInsets.only(left: mq.width * 0.2, right: mq.width * 0.01),
        child: Column(
          // alignment: Alignment.centerRight,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            senderMessageBody,
            if (_showTime)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  DateFormat('hh:mm a').format(msg.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w100,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiverMessage(String name, String avatarUrl, bool isOnline) {
    final Widget receiverMessageBody;

    if (msg.images.isNotEmpty) {
      receiverMessageBody = _ImageMessages(
        images: msg.images,
        createdAt: msg.createdAt,
        showTime: _showTime,
        messageType: msg.messageType,
      );
    } else if (msg.files.isNotEmpty) {
      if (MessageService.isImageUrl(msg.files[0].url)) {
        receiverMessageBody = _ImageMessages(
          images: msg.files,
          createdAt: msg.createdAt,
          showTime: _showTime,
          messageType: msg.messageType,
        );
      } else {
        receiverMessageBody = _FileMessages(
          files: msg.files,
          createdAt: msg.createdAt,
          showTime: _showTime,
          messageType: msg.messageType,
        );
      }
    } else {
      receiverMessageBody = _TextMessage(
        content: msg.content ?? '',
        createdAt: msg.createdAt,
        showTime: _showTime,
        showAvatar: _showAvatar,
        messageType: msg.messageType,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _showAvatar
              ? Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(avatarUrl),
                    radius: 20,
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          border: Border.all(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              )
              : SizedBox(width: 40),
          SizedBox(width: mq.width * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showAvatar) SizedBox(height: mq.height * 0.01),
              if (_showAvatar)
                Text(
                  name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 60),
                    child: receiverMessageBody,
                  ),
                  if (_showTime)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        DateFormat('hh:mm a').format(msg.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w100,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageMessages extends StatelessWidget {
  final List<FileModel> images;
  final DateTime createdAt;
  final bool showTime;
  final int messageType;

  const _ImageMessages({
    required this.images,
    required this.createdAt,
    required this.showTime,
    required this.messageType,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    Widget imageWidget;
    if (images.length == 1) {
      imageWidget = _buildImage(
        context,
        images[0],
        mq.width * 0.65,
        mq.height * 0.65 * 3 / 4,
      );
    } else if (images.length == 2) {
      double itemWidth = (mq.width * 0.65 - 6) / 2;
      double itemHeight = itemWidth * 3 / 4;

      imageWidget = SizedBox(
        width: mq.width * 0.67,
        child: Row(
          mainAxisAlignment:
              messageType == 1
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children:
              images.map((image) {
                return Padding(
                  padding:
                      messageType == 1
                          ? const EdgeInsets.only(left: 6.0)
                          : const EdgeInsets.only(right: 6.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImage(context, image, itemWidth, itemHeight),
                  ),
                );
              }).toList(),
        ),
      );
    } else {
      imageWidget = SizedBox(
        width: mq.width * 0.65,
        child: Wrap(
          spacing: 6, //khoảng cách ngang giữa các hình ảnh.
          runSpacing: 6, //khoảng cách dọc giữa các dòng ảnh.
          children:
              images.map((image) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(
                    context,
                    image,
                    (mq.width * 0.65 - 12) / 3,
                    mq.height * 0.15,
                  ),
                );
              }).toList(),
        ),
      );
    }
    return imageWidget;
  }

  Widget _buildImage(
    BuildContext context,
    FileModel image,
    double width,
    double height,
  ) {
    return GestureDetector(
      onTap: () {
        //oppen full screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => FullScreenImageViewer(
                  imageUrl: ApiConstants.getUrl(image.url),
                ),
          ),
        );
      },
      onLongPress: () {
        //display download dialog
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text('Download'),
                content: Text('Bạn muốn tải ảnh này không?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      _downloadImage(context, image.url, image.fileName);
                    },
                    child: Text('Tải xuống'),
                  ),
                ],
              ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          ApiConstants.getUrl(image.url),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                width: width,
                height: height,
                child: Icon(Icons.broken_image),
              ),
        ),
      ),
    );
  }

  void _downloadImage(
    BuildContext context,
    String imageUrl,
    String imageName,
  ) async {
    bool hasPermission = await FileService.requestStoragePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cần quyền để lưu ảnh.")));
      return;
    }

    try {
      final response = await Dio().get(
        ApiConstants.getUrl(imageUrl),
        options: Options(responseType: ResponseType.bytes),
      );
      Uint8List bytes = Uint8List.fromList(response.data);

      // Lưu ảnh
      final result = await SaverGallery.saveImage(
        bytes,
        fileName: imageName,
        skipIfExists: false,
        quality: 100,
      );
      if (result.isSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Tải thành công")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Tải ảnh thất bại!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi tải ảnh: $e")));
    }
  }
}

class _FileMessages extends StatelessWidget {
  final List<FileModel> files;
  final DateTime createdAt;
  final bool showTime;
  final int messageType;

  const _FileMessages({
    required this.files,
    required this.createdAt,
    required this.showTime,
    required this.messageType,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      constraints: BoxConstraints(maxWidth: mq.width * 0.65),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            files.map((file) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.fileName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        _downloadFile(context, file.url, file.fileName);
                      },
                      child: const Icon(
                        Icons.download,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  void _downloadFile(
    BuildContext context,
    String? url,
    String? fileName,
  ) async {
    if (url == null || fileName == null) return;

    FileService.downloadToDownloadFolder(url, fileName);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đang tải $fileName...')));
  }
}

class _TextMessage extends StatelessWidget {
  final String content;
  final DateTime createdAt;
  final bool showTime;
  final bool showAvatar;
  final int messageType;

  const _TextMessage({
    required this.content,
    required this.createdAt,
    required this.showTime,
    required this.showAvatar,
    required this.messageType,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    Widget textMessage = Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin:
          (messageType == 0 && showAvatar)
              ? EdgeInsets.only(top: mq.height * 0.01)
              : EdgeInsets.only(),

      decoration: BoxDecoration(
        color: messageType == 1 ? Color(0xFF20A090) : Color(0xFFF2F7FB),
        borderRadius:
            messageType == 1
                ? BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                )
                : BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mq.width * 0.6),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: messageType == 1 ? Colors.white : Colors.black,
          ),
        ),
      ),
    );

    return textMessage;
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(child: InteractiveViewer(child: Image.network(imageUrl))),
      ),
    );
  }
}
