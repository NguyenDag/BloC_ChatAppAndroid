import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:emoji_picker_flutter/locales/default_emoji_set_locale.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/opp_model.dart';
import 'package:myapp/pages/friendslist_page.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/message_service.dart';
import 'package:saver_gallery/saver_gallery.dart';

import '../blocs/chat/messages/chat_bloc.dart';
import '../blocs/chat/messages/chat_event.dart';
import '../blocs/chat/messages/chat_state.dart';
import '../constants/api_constants.dart';
import '../services/file_service.dart';
import '../services/friend_service.dart';

late Size mq;

class ChatConfig extends Equatable {
  final int maxImagePick;
  final int maxFilePick;
  final double maxImageSizeMB;
  final List<String> allowedImageTypes;
  final List<String> allowedFileTypes;

  const ChatConfig({
    this.maxImagePick = 10,
    this.maxFilePick = 5,
    this.maxImageSizeMB = 10.0,
    this.allowedImageTypes = const ['jpg', 'jpeg', 'png', 'gif'],
    this.allowedFileTypes = const ['pdf', 'doc', 'docx', 'txt', 'zip'],
  });

  @override
  List<Object?> get props => [
    maxImagePick,
    maxFilePick,
    maxImageSizeMB,
    allowedImageTypes,
    allowedFileTypes,
  ];
}

class OnlineChat extends StatelessWidget {
  final Friend friend;
  final String avatarUrl;
  final ChatConfig config;

  const OnlineChat({
    super.key,
    required this.friend,
    required this.avatarUrl,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc()..add(LoadMessages(friend.friendId)),
      child: OnlineChatView(
        friend: friend,
        avatarUrl: avatarUrl,
        config: config,
      ),
    );
  }
}

class OnlineChatView extends StatefulWidget {
  final Friend friend;
  final String avatarUrl;
  final ChatConfig config;

  const OnlineChatView({
    super.key,
    required this.friend,
    required this.avatarUrl,
    required this.config,
  });

  @override
  State<StatefulWidget> createState() => _OnlineChatViewState();
}

class _OnlineChatViewState extends State<OnlineChatView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_messageFocusNode.hasFocus) {
      context.read<ChatBloc>().add(const HideEmojiPicker());
    }
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     // Refresh messages when app comes back to foreground
  //     context.read<ChatBloc>().add(LoadMessages(widget.friend.friendId));
  //   }
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
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          color: FriendService.getChatColor(widget.friend),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildConnectionStatus(),
            const Divider(height: 1), //kẻ đường chỉ ngang
            _buildAttachmentPreviews(),
            _buildMessageInput(),
            _buildEmojiPicker(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
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
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FriendService.getDisplayName(widget.friend),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    String statusText =
                        widget.friend.isOnline ? 'Trực tuyến' : 'Offline';
                    if (state.isSending) {
                      statusText = 'Đang gửi...';
                    } else if (state.isOffline) {
                      statusText = 'Chế độ offline';
                    }

                    return Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: state.isSending ? Colors.blue : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              enabled: !state.isSending,
              onSelected: (value) {
                switch (value) {
                  case 'nickname':
                    MessageService.showRenameDialog(context, widget.friend);
                    break;
                  case 'color':
                    MessageService.showRecolorDialog(context, widget.friend);
                    break;
                  case 'clear_attachments':
                    if (state.hasAttachments) {
                      context.read<ChatBloc>().add(const ClearAttachments());
                    }
                    break;
                  case 'refresh':
                    context.read<ChatBloc>().add(
                      LoadMessages(widget.friend.friendId),
                    );
                    break;
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
                    if (state.hasAttachments)
                      const PopupMenuItem<String>(
                        value: 'clear_attachments',
                        child: Text('Xóa đính kèm'),
                      ),
                    const PopupMenuItem<String>(
                      value: 'refresh',
                      child: Text('Làm mới'),
                    ),
                  ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state.isOffline) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'Chế độ offline - Dữ liệu có thể không cập nhật',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageList() {
    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen:
          (previous, current) =>
              previous.status != current.status ||
              previous.messages.length != current.messages.length,
      listener: (context, state) {
        if (state.status == ChatStatus.success ||
            state.status == ChatStatus.sendSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } else if (state.status == ChatStatus.offline) {
          _showSnackBar(
            'Đang sử dụng dữ liệu offline',
            backgroundColor: Colors.orange,
            icon: Icons.wifi_off,
          );
        } else if (state.hasError && state.errorMessage != null) {
          _showErrorDialog(state.errorMessage!);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải tin nhắn...'),
              ],
            ),
          );
        }

        if (state.messages.isEmpty && !state.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có tin nhắn nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy bắt đầu cuộc trò chuyện!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final msg = state.messages[index];
            final prevMsg = index > 0 ? state.messages[index - 1] : null;

            final currentDate = formatDateGroup(msg.createdAt);
            final prevDate =
                prevMsg != null ? formatDateGroup(prevMsg.createdAt) : '';

            bool showDateHeader = currentDate != prevDate;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showDateHeader) _buildDateHeader(currentDate),
                ContentMessage(
                  msg: msg,
                  index: index,
                  name: FriendService.getDisplayName(widget.friend),
                  messages: state.messages,
                  avatarUrl: widget.avatarUrl,
                  isOnline: widget.friend.isOnline,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateHeader(String dateText) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          dateText,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentPreviews() {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen:
          (previous, current) =>
              previous.pickedImages != current.pickedImages ||
              previous.pickedFiles != current.pickedFiles,
      builder: (context, state) {
        if (!state.hasAttachments) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.pickedImages.isNotEmpty)
                _buildImagePreviews(state.pickedImages),
              if (state.pickedFiles.isNotEmpty)
                _buildFilePreviews(state.pickedFiles),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePreviews(List<File> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text(
              'Hình ảnh (${images.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        images[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () {
                          context.read<ChatBloc>().add(RemoveImage(index));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreviews(List<File> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (files.isNotEmpty) const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.attach_file, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Tệp đính kèm (${files.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...files.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          final fileName = file.path.split('/').last;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insert_drive_file,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.read<ChatBloc>().add(RemoveFile(index));
                  },
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMessageInput() {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen:
          (previous, current) =>
              previous.isSending != current.isSending ||
              previous.showEmojiPicker != current.showEmojiPicker,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap:
                    state.isSending
                        ? null
                        : () {
                          _messageFocusNode.unfocus();
                          context.read<ChatBloc>().add(
                            const ToggleEmojiPicker(),
                          );
                        },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        state.showEmojiPicker
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/emoji_icon.png',
                    width: 24,
                    height: 24,
                    color:
                        state.isSending
                            ? Colors.grey
                            : (state.showEmojiPicker ? Colors.blue : null),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          state.isSending
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.transparent,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    enabled: !state.isSending,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintText:
                          state.isSending ? 'Đang gửi...' : 'Nhập tin nhắn...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      border: InputBorder.none,
                      suffixIcon:
                          state.isSending
                              ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : IconButton(
                                icon: const Icon(Icons.send),
                                color: Colors.blue,
                                onPressed: () => _sendMessage(context, state),
                              ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: state.isSending ? null : () => _pickFiles(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/attach.png',
                    width: 24,
                    height: 24,
                    color: state.isSending ? Colors.grey : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: state.isSending ? null : () => _pickImages(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/image.png',
                    width: 24,
                    height: 24,
                    color: state.isSending ? Colors.grey : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmojiPicker() {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen:
          (previous, current) =>
              previous.showEmojiPicker != current.showEmojiPicker,
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: state.showEmojiPicker ? 250 : 0,
          child:
              state.showEmojiPicker
                  ? EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      final currentText = _messageController.text;
                      final currentPosition =
                          _messageController.selection.baseOffset;

                      if (currentPosition < 0) {
                        _messageController.text = currentText + emoji.emoji;
                        _messageController
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: _messageController.text.length),
                        );
                      } else {
                        final newText = currentText.replaceRange(
                          currentPosition,
                          currentPosition,
                          emoji.emoji,
                        );
                        _messageController.text = newText;
                        _messageController
                            .selection = TextSelection.fromPosition(
                          TextPosition(
                            offset: currentPosition + emoji.emoji.length,
                          ),
                        );
                      }
                    },
                    config: Config(
                      height: 256, // Giữ nguyên giá trị mặc định
                      checkPlatformCompatibility: true,
                      emojiSet:
                          getDefaultEmojiLocale, // Giữ nguyên giá trị mặc định
                      locale: const Locale('en'), // Giữ nguyên giá trị mặc định
                      emojiViewConfig: EmojiViewConfig(
                        columns: 7,
                        emojiSizeMax: 32,
                        verticalSpacing: 0,
                        horizontalSpacing: 0,
                        gridPadding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFFF2F2F2),
                        recentsLimit: 28,
                        noRecents: const Text(
                          'Chưa có emoji gần đây',
                          style: TextStyle(fontSize: 20, color: Colors.black26),
                          textAlign: TextAlign.center,
                        ),
                        loadingIndicator: const SizedBox.shrink(),
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        initCategory: Category.RECENT,
                        indicatorColor: Colors.blue,
                        iconColor: Colors.grey,
                        iconColorSelected: Colors.blue,
                        tabIndicatorAnimDuration: kTabScrollDuration,
                        categoryIcons: const CategoryIcons(),
                      ),
                      skinToneConfig: SkinToneConfig(
                        // enableSkinTones: true,
                        dialogBackgroundColor: Colors.white,
                        indicatorColor: Colors.grey,
                      ),
                      bottomActionBarConfig: BottomActionBarConfig(
                        enabled: true, // Bật thanh hành động
                        backgroundColor:
                            Colors.white, // Màu nền của thanh hành động
                        showBackspaceButton: true, // Hiển thị nút backspace
                        showSearchViewButton: true,
                      ),
                      searchViewConfig: SearchViewConfig(
                        // Có thể thêm các cấu hình tìm kiếm nếu cần
                      ),
                      viewOrderConfig: const ViewOrderConfig(),
                    ),
                  )
                  : const SizedBox.shrink(),
        );
      },
    );
  }

  void _sendMessage(BuildContext context, ChatState state) {
    final content = _messageController.text.trim();
    final hasText = content.isNotEmpty;

    final currentState = context.read<ChatBloc>().state;
    final hasAttachments = currentState.hasAttachments;

    if (!hasText && !hasAttachments) return;

    context.read<ChatBloc>().add(
      SendMessage(
        friendId: widget.friend.friendId,
        content: content,
        imageFiles: currentState.pickedImages.isEmpty ? null : currentState.pickedImages,
        otherFiles: currentState.pickedFiles.isEmpty ? null : currentState.pickedFiles,
      ),
    );

    _messageController.clear();
    context.read<ChatBloc>().add(const HideEmojiPicker());
  }

  Future<void> _pickFiles(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: widget.config.allowedFileTypes,
      );

      if (result != null && result.files.isNotEmpty) {
        final files =
            result.paths
                .where((path) => path != null)
                .map((path) => File(path!))
                .toList();

        if (files.isNotEmpty) {
          context.read<ChatBloc>().add(AddFiles(files));
          _showSnackBar(
            'Đã thêm ${files.length} tệp',
            backgroundColor: Colors.green,
            icon: Icons.attach_file,
          );
        }
      }
    } catch (e) {
      _showSnackBar(
        'Lỗi khi chọn tệp: ${e.toString()}',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // Check file size
        final validImages = <File>[];
        final maxSizeBytes = widget.config.maxImageSizeMB * 1024 * 1024;

        for (final image in images) {
          final file = File(image.path);
          final fileSize = await file.length();

          if (fileSize <= maxSizeBytes) {
            validImages.add(file);
          } else {
            _showSnackBar(
              'Ảnh ${image.name} quá lớn (>${widget.config.maxImageSizeMB}MB)',
              backgroundColor: Colors.orange,
              icon: Icons.warning,
            );
          }
        }

        if (validImages.isNotEmpty) {
          context.read<ChatBloc>().add(AddImages(validImages));
          _showSnackBar(
            'Đã thêm ${validImages.length} ảnh',
            backgroundColor: Colors.green,
            icon: Icons.image,
          );
        }
      }
    } catch (e) {
      _showSnackBar(
        'Lỗi khi chọn ảnh: ${e.toString()}',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  void _showSnackBar(
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Lỗi'),
              ],
            ),
            content: Text(message),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<ChatBloc>().add(const ClearError());
                },
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<ChatBloc>().add(
                    RetryLoadMessages(widget.friend.friendId),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Thử lại'),
              ),
            ],
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

extension ChatStateExtensions on ChatState {
  bool get canSendMessage => !isSending && !isLoading;
  bool get shouldShowRetry => hasError && !isLoading;
  String get statusDisplayText {
    switch (status) {
      case ChatStatus.loading:
        return 'Đang tải...';
      case ChatStatus.sending:
        return 'Đang gửi...';
      case ChatStatus.offline:
        return 'Offline';
      case ChatStatus.failure:
      case ChatStatus.sendFailure:
        return 'Lỗi';
      default:
        return '';
    }
  }
}

extension MessageExtensions on Message {
  bool get isToday {
    final now = DateTime.now();
    final messageDate = createdAt;
    return now.year == messageDate.year &&
        now.month == messageDate.month &&
        now.day == messageDate.day;
  }

  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final messageDate = createdAt;
    return yesterday.year == messageDate.year &&
        yesterday.month == messageDate.month &&
        yesterday.day == messageDate.day;
  }
}
