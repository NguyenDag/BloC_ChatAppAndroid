import 'package:flutter_bloc/flutter_bloc.dart';

import 'friends_list_event.dart';
import 'friends_list_state.dart';

class FriendsListBloc extends Bloc<FriendsListEvent, FriendsListState>{
  // FriendsListBloc(super.initialState);
  FriendsListBloc() : super(FriendsListInitial()) {
    on<LoadCurrentUser>(_onLoadCurrentUser);
    on<LoadFriends>(_onLoadFriends);
    on<RefreshFriends>(_onRefreshFriends);
    on<SearchFriendChanged>(_onSearchFriendChanged);
    on<ClearSearch>(_onClearSearch);
  }

  void _onLoadCurrentUser(LoadCurrentUser event, Emitter<FriendsListState> emit) async {

  }

  void _onLoadFriends(LoadFriends event, Emitter<FriendsListState> emit) async {

  }

  void _onRefreshFriends(RefreshFriends event, Emitter<FriendsListState> emit) async {

  }

  void _onSearchFriendChanged(SearchFriendChanged event, Emitter<FriendsListState> emit) async {

  }

  void _onClearSearch(ClearSearch event, Emitter<FriendsListState> emit) async {

  }

}