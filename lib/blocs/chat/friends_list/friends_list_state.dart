import 'package:equatable/equatable.dart';

abstract class FriendsListState extends Equatable {
  const FriendsListState();

  @override
  List<Object> get props => [];
}

class FriendsListInitial extends FriendsListState {}

class FriendsListLoading extends FriendsListState {}

class FriendsListLoaded extends FriendsListState {
  final List<Map<String, dynamic>> friends;
  final Map<String, dynamic>? currentUser;

  const FriendsListLoaded({required this.friends, required this.currentUser});
}

class FriendsListSearchResult extends FriendsListState {
  final List<Map<String, dynamic>> filteredFriends;

  const FriendsListSearchResult({required this.filteredFriends});
}

class FriendsListError extends FriendsListState {
  final String message;

  const FriendsListError(this.message);
}

class ChatOpened extends FriendsListState {
  final Map<String, dynamic> friendData;

  const ChatOpened({required this.friendData});
}

class FriendsListLoggedOut extends FriendsListState {}
