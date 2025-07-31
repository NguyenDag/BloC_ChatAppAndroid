import 'package:equatable/equatable.dart';

abstract class FriendsListEvent extends Equatable {
  const FriendsListEvent();

  @override
  List<Object> get props => [];
}

class LoadCurrentUser extends FriendsListEvent {}

class LoadFriends extends FriendsListEvent {}

class RefreshFriends extends FriendsListEvent {}

class SearchFriendChanged extends FriendsListEvent {
  final String query;

  const SearchFriendChanged(this.query);
}

class ClearSearch extends FriendsListEvent {}