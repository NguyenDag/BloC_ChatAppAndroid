import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../../models/opp_model.dart';

enum ChatStatus {
  initial,
  loading,
  loadingMore,
  success,
  failure,
  offline,
  sending,
  sendSuccess,
  sendFailure,
}

class ChatState extends Equatable {
  final ChatStatus status;
  final List<Message> messages;
  final List<File> pickedImages;
  final List<File> pickedFiles;
  final bool showEmojiPicker;
  final String? errorMessage;
  final bool isOnline;
  final Message? lastSentMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.pickedImages = const [],
    this.pickedFiles = const [],
    this.showEmojiPicker = false,
    this.errorMessage,
    this.isOnline = true,
    this.lastSentMessage,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    List<File>? pickedImages,
    List<File>? pickedFiles,
    bool? showEmojiPicker,
    String? errorMessage,
    bool? isOnline,
    Message? lastSentMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      pickedImages: pickedImages ?? this.pickedImages,
      pickedFiles: pickedFiles ?? this.pickedFiles,
      showEmojiPicker: showEmojiPicker ?? this.showEmojiPicker,
      errorMessage: errorMessage,
      isOnline: isOnline ?? this.isOnline,
      lastSentMessage: lastSentMessage,
    );
  }

  // Computed properties
  bool get isLoading => status == ChatStatus.loading;
  bool get isSending => status == ChatStatus.sending;
  bool get hasError =>
      status == ChatStatus.failure || status == ChatStatus.sendFailure;
  bool get isOffline => status == ChatStatus.offline;
  bool get hasAttachments => pickedImages.isNotEmpty || pickedFiles.isNotEmpty;
  int get totalAttachments => pickedImages.length + pickedFiles.length;

  @override
  List<Object?> get props => [
    status,
    messages,
    pickedImages,
    pickedFiles,
    showEmojiPicker,
    errorMessage,
    isOnline,
    lastSentMessage,
  ];

  @override
  String toString() {
    return '''ChatState {
      status: $status,
      messagesCount: ${messages.length},
      pickedImagesCount: ${pickedImages.length},
      pickedFilesCount: ${pickedFiles.length},
      showEmojiPicker: $showEmojiPicker,
      errorMessage: $errorMessage,
      isOnline: $isOnline,
    }''';
  }
}
