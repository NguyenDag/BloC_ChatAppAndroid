import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/models/opp_model.dart';

import '../../../services/message_service.dart';
import '../../../services/realm_message_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(const ChatState()) {
    on<LoadMessages>(_onLoadMessages);
    on<RetryLoadMessages>(_onRetryLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageSent>(_onMessageSent);
    on<ToggleEmojiPicker>(_onToggleEmojiPicker);
    on<ShowEmojiPicker>(_onShowEmojiPicker);
    on<HideEmojiPicker>(_onHideEmojiPicker);
    on<AddImages>(_onAddImages);
    on<RemoveImage>(_onRemoveImage);
    on<AddFiles>(_onAddFiles);
    on<RemoveFile>(_onRemoveFile);
    on<ClearAttachments>(_onClearAttachments);
    on<ClearError>(_onClearError);
  }
  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      // Load offline messages first for better UX
      final offlineMessages = RealmMessageService.getMessagesForFriend(
        event.friendId,
      );

      if (offlineMessages.isNotEmpty) {
        emit(
          state.copyWith(
            status: ChatStatus.success,
            messages: offlineMessages,
            isOnline: false,
          ),
        );
      }

      try {
        // Try to fetch from API
        final apiMessages = await MessageService.fetchMessages(event.friendId);

        // Save to local storage
        await RealmMessageService.saveMessagesToLocal(
          event.friendId,
          apiMessages.map((m) => m.messageToJson()).toList(),
        );

        emit(
          state.copyWith(
            status: ChatStatus.success,
            messages: apiMessages,
            isOnline: true,
            errorMessage: null,
          ),
        );
      } catch (apiError) {
        // API failed, use offline data if available
        if (offlineMessages.isEmpty) {
          emit(
            state.copyWith(
              status: ChatStatus.failure,
              errorMessage:
                  'Không thể tải tin nhắn. Vui lòng kiểm tra kết nối mạng.',
              isOnline: false,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: ChatStatus.offline,
              messages: offlineMessages,
              isOnline: false,
            ),
          );
        }
      }
    } catch (realmError) {
      emit(
        state.copyWith(
          status: ChatStatus.failure,
          errorMessage: 'Lỗi cơ sở dữ liệu: ${realmError.toString()}',
          isOnline: false,
        ),
      );
    }
  }

  Future<void> _onRetryLoadMessages(
    RetryLoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    // Clear error state and retry
    emit(state.copyWith(errorMessage: null));
    add(LoadMessages(event.friendId));
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final hasText = event.content.trim().isNotEmpty;
    final hasImages = event.imageFiles?.isNotEmpty ?? false;
    final hasFiles = event.otherFiles?.isNotEmpty ?? false;

    if (!hasText && !hasImages && !hasFiles) return;

    // Set sending state
    emit(state.copyWith(status: ChatStatus.sending));

    try {
      final newMsg = await MessageService.sendMessage(
        friendId: event.friendId,
        content: event.content,
        imageFiles: hasImages ? event.imageFiles : null,
        otherFiles: hasFiles ? event.otherFiles : null,
      );

      if (newMsg != null) {
        // Add the new message and clear attachments
        final updatedMessages = List<Message>.from(state.messages)..add(newMsg);
        emit(
          state.copyWith(
            status: ChatStatus.sendSuccess,
            messages: updatedMessages,
            pickedImages: [],
            pickedFiles: [],
            lastSentMessage: newMsg,
            errorMessage: null,
          ),
        );

        // Reset to success state after a brief moment
        await Future.delayed(const Duration(milliseconds: 100));
        emit(state.copyWith(status: ChatStatus.success));
      } else {
        emit(
          state.copyWith(
            status: ChatStatus.sendFailure,
            errorMessage: 'Không thể gửi tin nhắn',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: ChatStatus.sendFailure,
          errorMessage: 'Lỗi gửi tin nhắn: ${error.toString()}',
        ),
      );
    }
  }

  void _onMessageSent(MessageSent event, Emitter<ChatState> emit) {
    final updatedMessages = List<Message>.from(state.messages)
      ..add(event.newMessage);

    emit(
      state.copyWith(
        messages: updatedMessages,
        lastSentMessage: event.newMessage,
      ),
    );
  }

  void _onToggleEmojiPicker(ToggleEmojiPicker event, Emitter<ChatState> emit) {
    emit(state.copyWith(showEmojiPicker: !state.showEmojiPicker));
  }

  void _onShowEmojiPicker(ShowEmojiPicker event, Emitter<ChatState> emit) {
    emit(state.copyWith(showEmojiPicker: true));
  }

  void _onHideEmojiPicker(HideEmojiPicker event, Emitter<ChatState> emit) {
    emit(state.copyWith(showEmojiPicker: false));
  }

  void _onAddImages(AddImages event, Emitter<ChatState> emit) {
    // Combine existing and new images, avoiding duplicates
    final existingPaths = state.pickedImages.map((f) => f.path).toSet();
    final newImages =
        event.images
            .where((image) => !existingPaths.contains(image.path))
            .toList();

    final updatedImages = [...state.pickedImages, ...newImages];
    emit(state.copyWith(pickedImages: updatedImages));
  }

  void _onRemoveImage(RemoveImage event, Emitter<ChatState> emit) {
    if (event.index >= 0 && event.index < state.pickedImages.length) {
      final updatedImages = List<File>.from(state.pickedImages)
        ..removeAt(event.index);
      emit(state.copyWith(pickedImages: updatedImages));
    }
  }

  void _onAddFiles(AddFiles event, Emitter<ChatState> emit) {
    // Combine existing and new files, avoiding duplicates
    final existingPaths = state.pickedFiles.map((f) => f.path).toSet();
    final newFiles =
        event.files
            .where((file) => !existingPaths.contains(file.path))
            .toList();

    final updatedFiles = [...state.pickedFiles, ...newFiles];

    emit(state.copyWith(pickedFiles: updatedFiles));

  }

  void _onRemoveFile(RemoveFile event, Emitter<ChatState> emit) {
    if (event.index >= 0 && event.index < state.pickedFiles.length) {
      final updatedFiles = List<File>.from(state.pickedFiles)
        ..removeAt(event.index);
      emit(state.copyWith(pickedFiles: updatedFiles));
    }
  }

  void _onClearAttachments(ClearAttachments event, Emitter<ChatState> emit) {
    emit(state.copyWith(pickedImages: [], pickedFiles: []));
  }

  void _onClearError(ClearError event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        errorMessage: null,
        status:
            state.messages.isNotEmpty ? ChatStatus.success : ChatStatus.initial,
      ),
    );
  }
}
