import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../../models/opp_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String friendId;

  const LoadMessages(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

class SendMessage extends ChatEvent {
  final String friendId;
  final String content;
  final List<File>? imageFiles;
  final List<File>? otherFiles;

  const SendMessage({
    required this.friendId,
    required this.content,
    this.imageFiles,
    this.otherFiles,
  });

  @override
  List<Object?> get props => [friendId, content, imageFiles, otherFiles];
}

class MessageSent extends ChatEvent {
  final Message newMessage;

  const MessageSent(this.newMessage);

  @override
  List<Object?> get props => [newMessage];
}

class ToggleEmojiPicker extends ChatEvent {
  const ToggleEmojiPicker();
}

class HideEmojiPicker extends ChatEvent {
  const HideEmojiPicker();
}

class ShowEmojiPicker extends ChatEvent {
  const ShowEmojiPicker();
}

class AddImages extends ChatEvent {
  final List<File> images;

  const AddImages(this.images);

  @override
  List<Object?> get props => [images];
}

class RemoveImage extends ChatEvent {
  final int index;

  const RemoveImage(this.index);

  @override
  List<Object?> get props => [index];
}

class AddFiles extends ChatEvent {
  final List<File> files;

  const AddFiles(this.files);

  @override
  List<Object?> get props => [files];
}

class RemoveFile extends ChatEvent {
  final int index;

  const RemoveFile(this.index);

  @override
  List<Object?> get props => [index];
}

class ClearAttachments extends ChatEvent {
  const ClearAttachments();
}

class RetryLoadMessages extends ChatEvent {
  final String friendId;

  const RetryLoadMessages(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

class ClearError extends ChatEvent {
  const ClearError();
}